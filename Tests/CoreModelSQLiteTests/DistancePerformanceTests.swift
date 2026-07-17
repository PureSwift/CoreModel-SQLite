//
//  DistancePerformanceTests.swift
//  CoreModel-SQLite
//
//  Compares distance filtering/sorting via a registered SQL function (executed in
//  SQLite) against fetching every row and filtering/sorting in Swift.
//
//  These are benchmarks, not correctness tests (though they assert the two paths
//  agree). They insert a large dataset and are skipped unless `BENCHMARK` is set in
//  the environment, so they don't slow the normal test matrix. Run with:
//
//      BENCHMARK=1 swift test -c release --filter Benchmark
//

import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

/// Benchmarks are opt-in: set `BENCHMARK` in the environment to run them.
private let benchmarksEnabled = ProcessInfo.processInfo.environment["BENCHMARK"] != nil

private let benchmarkReferenceLatitude = 35.7796
private let benchmarkReferenceLongitude = -78.6382
private let benchmarkRowCount = 100_000
private let benchmarkIterations = 10

private func benchmarkHaversine(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
    let earthRadius = 6_371_000.0
    let dLat = (lat2 - lat1) * .pi / 180
    let dLon = (lon2 - lon1) * .pi / 180
    let a = sin(dLat / 2) * sin(dLat / 2)
        + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
    return earthRadius * 2 * atan2(a.squareRoot(), (1 - a).squareRoot())
}

private let benchmarkDistanceFunction = DatabaseFunction(name: "distance", argumentCount: 4) { arguments in
    guard case let .double(lat1) = arguments[0], case let .double(lon1) = arguments[1],
          case let .double(lat2) = arguments[2], case let .double(lon2) = arguments[3] else { return nil }
    return .double(benchmarkHaversine(lat1, lon1, lat2, lon2))
}

/// A database seeded with `benchmarkRowCount` sites spread across the continental US,
/// with the `distance` function registered.
private func makeBenchmarkDatabase() async throws -> SQLiteDatabase {
    let model = Model(entities: [
        EntityDescription(id: "Site", attributes: [
            .init(id: "latitude", type: .double),
            .init(id: "longitude", type: .double)
        ], relationships: [])
    ])
    let database = try SQLiteDatabase(path: temporaryDatabasePath(named: "Benchmark"), model: model)
    try await database.register(function: benchmarkDistanceFunction)

    var rng = SystemRandomNumberGenerator()
    var rows = [ModelData]()
    rows.reserveCapacity(benchmarkRowCount)
    for index in 0..<benchmarkRowCount {
        rows.append(ModelData(entity: "Site", id: ObjectID(rawValue: "s\(index)"), attributes: [
            "latitude": .double(Double.random(in: 24...49, using: &rng)),
            "longitude": .double(Double.random(in: -125 ... -66, using: &rng))
        ]))
    }
    try await database.insert(rows)
    return database
}

private func benchmarkDistanceSort() -> FetchRequest.SortDescriptor {
    .init(term: .function(.init(name: "distance", arguments: [
        .keyPath("latitude"), .keyPath("longitude"),
        .attribute(.double(benchmarkReferenceLatitude)), .attribute(.double(benchmarkReferenceLongitude))
    ])), ascending: true)
}

private func benchmarkDistanceExpression() -> FetchRequest.Predicate.Expression {
    .function(.init(name: "distance", arguments: [
        .keyPath("latitude"), .keyPath("longitude"),
        .attribute(.double(benchmarkReferenceLatitude)), .attribute(.double(benchmarkReferenceLongitude))
    ]))
}

/// Filter+sort by distance in Swift over already-fetched rows.
private func benchmarkInMemory(_ rows: [ModelData], radius: Double) -> [ObjectID] {
    rows.compactMap { row -> (ObjectID, Double)? in
        guard case let .double(latitude)? = row.attributes["latitude"],
              case let .double(longitude)? = row.attributes["longitude"] else { return nil }
        let distance = benchmarkHaversine(latitude, longitude, benchmarkReferenceLatitude, benchmarkReferenceLongitude)
        return distance <= radius ? (row.id, distance) : nil
    }
    .sorted { $0.1 < $1.1 }
    .map(\.0)
}

@Suite(.enabled(if: benchmarksEnabled, "set BENCHMARK in the environment to run"))
struct DistancePerformanceBenchmarks {

    /// Selective radius filter + distance sort: SQLite returns only the matches, so the
    /// custom-function path avoids materializing the excluded rows.
    @Test func benchmarkSelectiveFilterAndSort() async throws {
        let database = try await makeBenchmarkDatabase()
        let radius = 500_000.0 // 500 km
        let sqlRequest = FetchRequest(
            entity: "Site",
            sortDescriptors: [benchmarkDistanceSort()],
            predicate: .comparison(.init(left: benchmarkDistanceExpression(), right: .attribute(.double(radius)), type: .lessThanOrEqualTo))
        )
        let allRequest = FetchRequest(entity: "Site")

        #expect(try await database.fetch(sqlRequest).count == benchmarkInMemory(try await database.fetch(allRequest), radius: radius).count)

        var sqlMatches = 0
        let sqlStart = Date()
        for _ in 0..<benchmarkIterations { sqlMatches = try await database.fetch(sqlRequest).count }
        let sqlTime = Date().timeIntervalSince(sqlStart)

        var memMatches = 0
        let memStart = Date()
        for _ in 0..<benchmarkIterations { memMatches = benchmarkInMemory(try await database.fetch(allRequest), radius: radius).count }
        let memTime = Date().timeIntervalSince(memStart)

        print("""

        ===== Selective filter+sort: \(benchmarkRowCount) rows, \(sqlMatches) matches, \(benchmarkIterations) iterations =====
        SQL (filter+sort in SQLite): avg \(sqlTime / Double(benchmarkIterations)) seconds
        in-memory (fetch-all + Swift): avg \(memTime / Double(benchmarkIterations)) seconds
        """)
        #expect(sqlMatches == memMatches)
    }

    /// Sort by distance with no filter: every row is returned, so both paths materialize
    /// the whole table and the SQL path gains nothing from filtering in the database.
    @Test func benchmarkSortNoFilter() async throws {
        let database = try await makeBenchmarkDatabase()
        let sqlRequest = FetchRequest(entity: "Site", sortDescriptors: [benchmarkDistanceSort()])
        let allRequest = FetchRequest(entity: "Site")

        // no radius filter: `.infinity` keeps every row
        #expect(try await database.fetch(sqlRequest).map(\.id) == benchmarkInMemory(try await database.fetch(allRequest), radius: .infinity))

        var sqlCount = 0
        let sqlStart = Date()
        for _ in 0..<benchmarkIterations { sqlCount = try await database.fetch(sqlRequest).count }
        let sqlTime = Date().timeIntervalSince(sqlStart)

        var memCount = 0
        let memStart = Date()
        for _ in 0..<benchmarkIterations { memCount = benchmarkInMemory(try await database.fetch(allRequest), radius: .infinity).count }
        let memTime = Date().timeIntervalSince(memStart)

        print("""

        ===== Sort, no filter: \(benchmarkRowCount) rows returned, \(benchmarkIterations) iterations =====
        SQL (ORDER BY in SQLite): avg \(sqlTime / Double(benchmarkIterations)) seconds
        in-memory (fetch-all + Swift sort): avg \(memTime / Double(benchmarkIterations)) seconds
        """)
        #expect(sqlCount == memCount)
    }
}
