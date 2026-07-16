import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

/// A Haversine distance function, in meters, written directly in the test — CoreModelSQLite
/// itself has no notion of "distance" or geo data; this exercises the generic
/// `DatabaseFunction`/`.function` expression mechanism using a realistic example.
private func haversineDistance(_ lat1: Double, _ lon1: Double, _ lat2: Double, _ lon2: Double) -> Double {
    let earthRadius = 6_371_000.0
    let dLat = (lat2 - lat1) * .pi / 180
    let dLon = (lon2 - lon1) * .pi / 180
    let a = sin(dLat / 2) * sin(dLat / 2)
        + cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) * sin(dLon / 2) * sin(dLon / 2)
    let c = 2 * atan2(a.squareRoot(), (1 - a).squareRoot())
    return earthRadius * c
}

private let distanceFunction = DatabaseFunction(name: "distance", argumentCount: 4) { arguments in
    guard case let .double(lat1) = arguments[0],
          case let .double(lon1) = arguments[1],
          case let .double(lat2) = arguments[2],
          case let .double(lon2) = arguments[3]
    else { return nil }
    return .double(haversineDistance(lat1, lon1, lat2, lon2))
}

private func makeGeoDatabase() async throws -> SQLiteDatabase {
    let model = Model(entities: [
        EntityDescription(
            id: "Site",
            attributes: [
                .init(id: "name", type: .string),
                .init(id: "latitude", type: .double),
                .init(id: "longitude", type: .double)
            ],
            relationships: []
        )
    ])
    let database = try SQLiteDatabase(path: temporaryDatabasePath(named: "GeoTests"), model: model)
    try await database.register(function: distanceFunction)
    return database
}

/// Known coordinates, distances computed against Raleigh, NC (35.7796, -78.6382), the
/// reference point every test below filters/sorts by.
private let referenceLatitude = 35.7796
private let referenceLongitude = -78.6382

private let sites: [(id: ObjectID, name: String, latitude: Double, longitude: Double)] = [
    ("raleigh", "Raleigh, NC", 35.7796, -78.6382),          // ~0 m
    ("durham", "Durham, NC", 35.9940, -78.8986),             // ~30 km
    ("charlotte", "Charlotte, NC", 35.2271, -80.8431),       // ~210 km
    ("atlanta", "Atlanta, GA", 33.7490, -84.3880),           // ~530 km
    ("nyc", "New York, NY", 40.7128, -74.0060)               // ~660 km
]

private func insertSites(_ database: SQLiteDatabase) async throws {
    for site in sites {
        try await database.insert(ModelData(
            entity: "Site",
            id: site.id,
            attributes: [
                "name": .string(site.name),
                "latitude": .double(site.latitude),
                "longitude": .double(site.longitude)
            ]
        ))
    }
}

private func distanceExpression() -> FetchRequest.Predicate.Expression {
    .function(.init(name: "distance", arguments: [
        .keyPath("latitude"),
        .keyPath("longitude"),
        .attribute(.double(referenceLatitude)),
        .attribute(.double(referenceLongitude))
    ]))
}

/// Independently computed oracle, not exercising any library code, to check results against.
private func expectedIDs(within radiusMeters: Double) -> Set<ObjectID> {
    Set(sites.filter { haversineDistance($0.latitude, $0.longitude, referenceLatitude, referenceLongitude) <= radiusMeters }.map(\.id))
}

@Test func functionPredicateFiltersByRadius() async throws {
    let database = try await makeGeoDatabase()
    try await insertSites(database)

    let radius = 250_000.0
    let request = FetchRequest(
        entity: "Site",
        predicate: .comparison(.init(left: distanceExpression(), right: .attribute(.double(radius)), type: .lessThanOrEqualTo))
    )
    let ids = Set(try await database.fetchID(request))
    #expect(ids == expectedIDs(within: radius))
    #expect(ids == ["raleigh", "durham", "charlotte"])
}

@Test func functionSortOrdersByDistance() async throws {
    let database = try await makeGeoDatabase()
    try await insertSites(database)

    let request = FetchRequest(
        entity: "Site",
        sortDescriptors: [.init(term: .function(.init(name: "distance", arguments: [
            .keyPath("latitude"), .keyPath("longitude"),
            .attribute(.double(referenceLatitude)), .attribute(.double(referenceLongitude))
        ])), ascending: true)]
    )
    let ids = try await database.fetchID(request)
    #expect(ids == ["raleigh", "durham", "charlotte", "atlanta", "nyc"])
}

@Test func functionFilterAndSortWithLimit() async throws {
    let database = try await makeGeoDatabase()
    try await insertSites(database)

    let radius = 700_000.0
    let request = FetchRequest(
        entity: "Site",
        sortDescriptors: [.init(term: .function(.init(name: "distance", arguments: [
            .keyPath("latitude"), .keyPath("longitude"),
            .attribute(.double(referenceLatitude)), .attribute(.double(referenceLongitude))
        ])), ascending: true)],
        predicate: .comparison(.init(left: distanceExpression(), right: .attribute(.double(radius)), type: .lessThanOrEqualTo)),
        fetchLimit: 2
    )
    let ids = try await database.fetchID(request)
    #expect(ids == ["raleigh", "durham"])
}

@MainActor
@Test func functionRegisteredOnViewContext() async throws {
    let path = temporaryDatabasePath(named: "GeoViewContextTests")
    let model = Model(entities: [
        EntityDescription(
            id: "Site",
            attributes: [
                .init(id: "name", type: .string),
                .init(id: "latitude", type: .double),
                .init(id: "longitude", type: .double)
            ],
            relationships: []
        )
    ])
    let database = try SQLiteDatabase(path: path, model: model)
    try await database.register(function: distanceFunction)
    try await insertSites(database)

    let viewContext = try SQLiteViewContext(.uri(path), model: model)
    try viewContext.register(function: distanceFunction)

    let radius = 250_000.0
    let request = FetchRequest(
        entity: "Site",
        predicate: .comparison(.init(left: distanceExpression(), right: .attribute(.double(radius)), type: .lessThanOrEqualTo))
    )
    let ids = Set(try viewContext.fetchID(request))
    #expect(ids == expectedIDs(within: radius))
}

@Test func unrelatedEntitiesUnaffected() async throws {
    // regression: entities/queries with no `.function` usage behave exactly as before
    let database = try makeDatabase()
    let people = (0..<3).map { index in
        ModelData(entity: "Person", id: ObjectID(rawValue: "person\(index)"), attributes: ["name": .string("Person \(index)")])
    }
    try await database.insert(people)
    let count = try await database.count(FetchRequest(entity: "Person"))
    #expect(count == 3)
}
