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

private var geoModel: Model {
    Model(entities: [
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
}

private func makeGeoDatabase(named name: String = "GeoTests") async throws -> SQLiteDatabase {
    let database = try SQLiteDatabase(path: temporaryDatabasePath(named: name), model: geoModel)
    try await database.register(function: distanceFunction)
    return database
}

/// A deterministic pseudo-random generator so the large-dataset comparison tests are
/// reproducible run to run (SPLITMIX64).
private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Whether this SQLite build includes the R*Tree module (an optional compile-time
/// feature), determined by attempting to create an R*Tree virtual table in memory.
private let isRTreeAvailable: Bool = {
    guard let connection = try? Connection(path: .inMemory) else { return false }
    do {
        try connection.run("CREATE VIRTUAL TABLE rtree_probe USING rtree(id, minX, maxX)")
        return true
    } catch {
        return false
    }
}()

private func distanceSort(ascending: Bool = true) -> FetchRequest.SortDescriptor {
    .init(term: .function(.init(name: "distance", arguments: [
        .keyPath("latitude"), .keyPath("longitude"),
        .attribute(.double(referenceLatitude)), .attribute(.double(referenceLongitude))
    ])), ascending: ascending)
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
    let model = geoModel
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

/// Generate a reproducible spread of coordinates across the continental US and their
/// precomputed distance from the reference point.
private func randomSites(count: Int, seed: UInt64) -> [(id: ObjectID, latitude: Double, longitude: Double, distance: Double)] {
    var rng = SeededGenerator(seed: seed)
    return (0..<count).map { index in
        let latitude = Double.random(in: 25...49, using: &rng)
        let longitude = Double.random(in: -124 ... -67, using: &rng)
        return (
            id: ObjectID(rawValue: "site\(index)"),
            latitude: latitude,
            longitude: longitude,
            distance: haversineDistance(latitude, longitude, referenceLatitude, referenceLongitude)
        )
    }
}

/// The SQL `distance` function (executed inside SQLite) must produce exactly the same
/// filtered set and sort order as filtering/sorting the same data in Swift. Because the
/// registered function delegates to the same `haversineDistance` Swift code, the two
/// paths compute bit-identical distances, so the comparison is exact.
@Test func matchesInMemorySwiftFilterAndSort() async throws {
    let database = try await makeGeoDatabase(named: "GeoCompare")
    let generated = randomSites(count: 200, seed: 0xC0FFEE)
    for site in generated {
        try await database.insert(ModelData(entity: "Site", id: site.id, attributes: [
            "latitude": .double(site.latitude),
            "longitude": .double(site.longitude)
        ]))
    }

    let radius = 1_000_000.0 // 1000 km

    // SQL path: filter and sort by the registered distance function
    let sqlRequest = FetchRequest(
        entity: "Site",
        sortDescriptors: [distanceSort()],
        predicate: .comparison(.init(left: distanceExpression(), right: .attribute(.double(radius)), type: .lessThanOrEqualTo))
    )
    let sqlIDs = try await database.fetchID(sqlRequest)

    // In-memory Swift path: same filter and sort over the same data
    let inMemoryIDs = generated
        .filter { $0.distance <= radius }
        .sorted { $0.distance < $1.distance }
        .map(\.id)

    #expect(sqlIDs == inMemoryIDs)
    #expect(sqlIDs.isEmpty == false) // ensure the radius actually matched something
    #expect(sqlIDs.count < generated.count) // ...and excluded something
}

/// App-managed R*Tree: CoreModelSQLite provides only `execute(_:_:)` and the generic
/// `distance` function — the app itself creates an R*Tree virtual table (plus a rowid
/// mapping and triggers to keep it in sync), uses it as a bounding-box prefilter, then
/// applies the exact `distance` function for correctness. The final result must match
/// the brute-force in-memory oracle, and the prefilter must be sound (a superset of the
/// exact matches) and actually prune.
///
/// R*Tree is an optional SQLite compile-time feature (`SQLITE_ENABLE_RTREE`). It's present
/// in the system SQLite on Apple platforms but not in the embedded SQLite used elsewhere,
/// so this test is skipped where the `rtree` module is unavailable.
@Test(.enabled(if: isRTreeAvailable, "R*Tree module not compiled into this SQLite build"))
func appManagedRTreePrefilter() async throws {
    let path = temporaryDatabasePath(named: "GeoRTree")
    let database = try SQLiteDatabase(path: path, model: geoModel)
    try await database.register(function: distanceFunction)

    // App-owned spatial index and sync triggers — entirely outside the library.
    try await database.execute("""
        CREATE TABLE "Site_rtree_map" (rowid INTEGER PRIMARY KEY AUTOINCREMENT, site_id TEXT UNIQUE NOT NULL)
        """)
    try await database.execute("""
        CREATE VIRTUAL TABLE "Site_rtree" USING rtree(id, minLat, maxLat, minLon, maxLon)
        """)
    try await database.execute("""
        CREATE TRIGGER "Site_rtree_insert" AFTER INSERT ON "Site" BEGIN
            INSERT INTO "Site_rtree_map"(site_id) VALUES (NEW."id");
            INSERT INTO "Site_rtree"(id, minLat, maxLat, minLon, maxLon)
                SELECT rowid, NEW."latitude", NEW."latitude", NEW."longitude", NEW."longitude"
                FROM "Site_rtree_map" WHERE site_id = NEW."id";
        END
        """)

    let generated = randomSites(count: 200, seed: 0xBEEF)
    for site in generated {
        try await database.insert(ModelData(entity: "Site", id: site.id, attributes: [
            "latitude": .double(site.latitude),
            "longitude": .double(site.longitude)
        ]))
    }

    let radius = 1_000_000.0 // 1000 km

    // Bounding box (a superset of the radius circle) in degrees.
    let latDelta = radius / 111_320.0
    let lonDelta = radius / (111_320.0 * cos(referenceLatitude * .pi / 180))
    let minLat = referenceLatitude - latDelta
    let maxLat = referenceLatitude + latDelta
    let minLon = referenceLongitude - lonDelta
    let maxLon = referenceLongitude + lonDelta

    // Query the app's R*Tree (through the app's own read connection) for candidate ids.
    let reader = try Connection(path: path, isReadOnly: true)
    let statement = try reader.prepare("""
        SELECT m.site_id FROM "Site_rtree" r
        JOIN "Site_rtree_map" m ON m.rowid = r.id
        WHERE r.minLat <= ? AND r.maxLat >= ? AND r.minLon <= ? AND r.maxLon >= ?
        """, [maxLat.binding, minLat.binding, maxLon.binding, minLon.binding])
    var candidates = Set<ObjectID>()
    while let row = try statement.failableNext() {
        if let site = row[0]?.textValue {
            candidates.insert(ObjectID(rawValue: site))
        }
    }

    // Combine the R*Tree candidate set with the exact distance filter via the library.
    let request = FetchRequest(
        entity: "Site",
        sortDescriptors: [distanceSort()],
        predicate: .compound(.and([
            .comparison(.init(left: .keyPath("id"), right: .relationship(.toMany(Array(candidates))), type: .in)),
            .comparison(.init(left: distanceExpression(), right: .attribute(.double(radius)), type: .lessThanOrEqualTo))
        ]))
    )
    let rtreeResult = try await database.fetchID(request)

    // Brute-force oracle over the same data.
    let oracle = generated
        .filter { $0.distance <= radius }
        .sorted { $0.distance < $1.distance }
        .map(\.id)

    #expect(rtreeResult == oracle)                       // combined query is correct
    #expect(Set(oracle).isSubset(of: candidates))        // prefilter is sound
    #expect(candidates.count < generated.count)          // prefilter actually pruned
    #expect(oracle.isEmpty == false)
}

