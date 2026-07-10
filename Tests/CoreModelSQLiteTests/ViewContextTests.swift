import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

@Suite("SQLiteViewContext", .serialized)
@MainActor
struct ViewContextTests {

    // MARK: - Helpers

    /// Creates a file-backed database pre-populated with 5 people and 1 team.
    /// Returns the database (for further writes) and the file path (for ViewContext).
    private func makePopulatedDatabase() async throws -> (database: SQLiteDatabase, path: String) {
        let path = temporaryDatabasePath(named: "ViewContext")
        let database = try SQLiteDatabase(path: path, model: testModel)
        let people = (0..<5).map { index in
            ModelData(
                entity: "Person",
                id: ObjectID(rawValue: "person\(index)"),
                attributes: [
                    "name": .string("Person \(index)"),
                    "age": .int32(Int32(20 + index))
                ]
            )
        }
        try await database.insert(people)
        let team = ModelData(entity: "Team", id: "team1", attributes: ["name": .string("Red")])
        try await database.insert(team)
        return (database, path)
    }

    // MARK: - Initialization

    @Test func initializesFromPath() async throws {
        let (_, path) = try await makePopulatedDatabase()
        _ = try SQLiteViewContext(path: path, model: testModel)
    }

    @Test func initializesFromLocation() async throws {
        let (_, path) = try await makePopulatedDatabase()
        _ = try SQLiteViewContext(.uri(path), model: testModel)
    }

    // MARK: - fetch(entity:for:)

    @Test func fetchByIDReturnsObject() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let person = try #require(try context.fetch("Person", for: "person0"))
        #expect(person.id == "person0")
        #expect(person.attributes["name"] == .string("Person 0"))
        #expect(person.attributes["age"] == .int32(20))
    }

    @Test func fetchByIDReturnsNilForMissing() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let result = try context.fetch("Person", for: "nonexistent")
        #expect(result == nil)
    }

    @Test func fetchByIDThrowsForUnknownEntity() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        #expect(throws: (any Error).self) {
            try context.fetch("Unknown", for: "person0")
        }
    }

    // MARK: - fetch(fetchRequest:)

    @Test func fetchAllReturnsAllObjects() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let results = try context.fetch(FetchRequest(entity: "Person"))
        #expect(results.count == 5)
    }

    @Test func fetchWithPredicateFilters() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let request = FetchRequest(
            entity: "Person",
            predicate: .comparison(.init(
                left: .keyPath("age"),
                right: .attribute(.int32(22)),
                type: .greaterThan
            ))
        )
        let results = try context.fetch(request)
        #expect(results.count == 2) // ages 23 and 24
    }

    @Test func fetchWithSortDescriptorDescending() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let request = FetchRequest(
            entity: "Person",
            sortDescriptors: [.init(property: "age", ascending: false)]
        )
        let results = try context.fetch(request)
        #expect(results.map { $0.attributes["age"] } == [.int32(24), .int32(23), .int32(22), .int32(21), .int32(20)])
    }

    @Test func fetchWithLimit() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let request = FetchRequest(
            entity: "Person",
            sortDescriptors: [.init(property: "age", ascending: true)],
            fetchLimit: 2
        )
        let results = try context.fetch(request)
        #expect(results.count == 2)
        #expect(results[0].attributes["age"] == .int32(20))
        #expect(results[1].attributes["age"] == .int32(21))
    }

    @Test func fetchWithOffset() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let request = FetchRequest(
            entity: "Person",
            sortDescriptors: [.init(property: "age", ascending: true)],
            fetchLimit: 2,
            fetchOffset: 2
        )
        let results = try context.fetch(request)
        #expect(results.count == 2)
        #expect(results[0].attributes["age"] == .int32(22))
        #expect(results[1].attributes["age"] == .int32(23))
    }

    @Test func fetchCompoundPredicate() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let request = FetchRequest(
            entity: "Person",
            predicate: .compound(.and([
                .comparison(.init(left: .keyPath("age"), right: .attribute(.int32(21)), type: .greaterThanOrEqualTo)),
                .comparison(.init(left: .keyPath("age"), right: .attribute(.int32(23)), type: .lessThan))
            ]))
        )
        let results = try context.fetch(request)
        #expect(results.count == 2) // ages 21 and 22
    }

    // MARK: - fetchID(fetchRequest:)

    @Test func fetchIDReturnsCorrectIDs() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let ids = try context.fetchID(FetchRequest(
            entity: "Person",
            sortDescriptors: [.init(property: "age", ascending: true)]
        ))
        #expect(ids == ["person0", "person1", "person2", "person3", "person4"])
    }

    @Test func fetchIDWithInPredicate() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let request = FetchRequest(
            entity: "Person",
            predicate: .comparison(.init(
                left: .keyPath("id"),
                right: .relationship(.toMany(["person1", "person3"])),
                type: .in
            ))
        )
        let ids = try context.fetchID(request)
        #expect(Set(ids) == Set(["person1", "person3"]))
    }

    // MARK: - count(fetchRequest:)

    @Test func countReturnsTotal() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let count = try context.count(FetchRequest(entity: "Person"))
        #expect(count == 5)
    }

    @Test func countWithPredicate() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let request = FetchRequest(
            entity: "Person",
            predicate: .comparison(.init(
                left: .keyPath("age"),
                right: .attribute(.int32(21)),
                type: .greaterThanOrEqualTo
            ))
        )
        let count = try context.count(request)
        #expect(count == 4) // ages 21, 22, 23, 24
    }

    @Test func countReturnsZeroForNoMatches() async throws {
        let (_, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)
        let request = FetchRequest(
            entity: "Person",
            predicate: .comparison(.init(
                left: .keyPath("age"),
                right: .attribute(.int32(100)),
                type: .greaterThan
            ))
        )
        let count = try context.count(request)
        #expect(count == 0)
    }

    // MARK: - Relationship reading

    @Test func fetchToOneRelationship() async throws {
        let (database, path) = try await makePopulatedDatabase()
        let person = ModelData(
            entity: "Person",
            id: "personWithTeam",
            attributes: ["name": .string("Alice")],
            relationships: ["team": .toOne("team1")]
        )
        try await database.insert(person)

        let context = try SQLiteViewContext(path: path, model: testModel)
        let fetched = try #require(try context.fetch("Person", for: "personWithTeam"))
        #expect(fetched.relationships["team"] == .toOne("team1"))
    }

    @Test func fetchInverseToManyRelationship() async throws {
        let (database, path) = try await makePopulatedDatabase()
        let person = ModelData(
            entity: "Person",
            id: "personOnTeam",
            attributes: ["name": .string("Bob")],
            relationships: ["team": .toOne("team1")]
        )
        try await database.insert(person)

        let context = try SQLiteViewContext(path: path, model: testModel)
        let team = try #require(try context.fetch("Team", for: "team1"))
        #expect(team.relationships["members"] == .toMany(["personOnTeam"]))
    }

    // MARK: - Sees committed writes

    @Test func reflectsNewlyInsertedData() async throws {
        let (database, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)

        #expect(try context.count(FetchRequest(entity: "Person")) == 5)

        try await database.insert(ModelData(
            entity: "Person",
            id: "newPerson",
            attributes: ["name": .string("New"), "age": .int32(99)]
        ))

        #expect(try context.count(FetchRequest(entity: "Person")) == 6)
        let fetched = try #require(try context.fetch("Person", for: "newPerson"))
        #expect(fetched.attributes["age"] == .int32(99))
    }

    @Test func reflectsDeletedData() async throws {
        let (database, path) = try await makePopulatedDatabase()
        let context = try SQLiteViewContext(path: path, model: testModel)

        #expect(try context.count(FetchRequest(entity: "Person")) == 5)
        try await database.delete("Person", for: "person0")
        #expect(try context.count(FetchRequest(entity: "Person")) == 4)
        #expect(try context.fetch("Person", for: "person0") == nil)
    }
}
