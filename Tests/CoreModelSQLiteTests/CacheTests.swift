import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

/// Verifies `SQLiteDatabase`'s object cache: repeated ID lookups are served from memory,
/// and every write shape that can change a fetched representation — direct updates,
/// inverse relationship changes, reassignment side effects, and deletes — invalidates
/// the affected entries so reads never observe stale data.
@Suite("Object Cache")
struct CacheTests {

    @Test func fetchByIDPopulatesCache() async throws {
        let database = try makeDatabase()
        let person = ModelData(
            entity: "Person",
            id: "person1",
            attributes: ["name": .string("Alice"), "age": .int32(30)]
        )
        try await database.insert(person)
        #expect(await database.cache["Person"]?["person1"] == nil)
        let fetched = try #require(try await database.fetch("Person", for: "person1"))
        #expect(await database.cache["Person"]?["person1"] == fetched)
        // a second fetch returns the cached value
        let cached = try #require(try await database.fetch("Person", for: "person1"))
        #expect(cached == fetched)
    }

    @Test func fetchRequestRegistersResults() async throws {
        let database = try makeDatabase()
        let people = (0..<5).map { index in
            ModelData(
                entity: "Person",
                id: ObjectID(rawValue: "person\(index)"),
                attributes: ["name": .string("Person \(index)"), "age": .int32(Int32(20 + index))]
            )
        }
        try await database.insert(people)
        let results = try await database.fetch(FetchRequest(entity: "Person"))
        #expect(results.count == 5)
        let cache = await database.cache["Person"]
        #expect(cache?.count == 5)
        for value in results {
            #expect(cache?[value.id] == value)
        }
    }

    @Test func updateInvalidatesCachedObject() async throws {
        let database = try makeDatabase()
        var person = ModelData(
            entity: "Person",
            id: "person1",
            attributes: ["name": .string("Alice"), "age": .int32(30)]
        )
        try await database.insert(person)
        _ = try await database.fetch("Person", for: "person1")
        // update through the same database
        person.attributes["age"] = .int32(31)
        try await database.insert(person)
        #expect(await database.cache["Person"] == nil)
        let fetched = try #require(try await database.fetch("Person", for: "person1"))
        #expect(fetched.attributes["age"] == .int32(31))
    }

    @Test func writeInvalidatesInverseRelationship() async throws {
        let database = try makeDatabase()
        let team = ModelData(entity: "Team", id: "team1", attributes: ["name": .string("Red")])
        try await database.insert(team)
        // cache the team with no members
        let cached = try #require(try await database.fetch("Team", for: "team1"))
        #expect(cached.relationships["members"] == .toMany([]))
        // inserting a person pointing at the team changes the team's derived `members`
        let person = ModelData(
            entity: "Person",
            id: "person1",
            attributes: ["name": .string("Alice")],
            relationships: ["team": .toOne("team1")]
        )
        try await database.insert(person)
        let fetched = try #require(try await database.fetch("Team", for: "team1"))
        #expect(fetched.relationships["members"] == .toMany(["person1"]))
    }

    @Test func reassignmentInvalidatesOtherRows() async throws {
        let database = try makeDatabase()
        let teams = ["team1", "team2"].map {
            ModelData(entity: "Team", id: ObjectID(rawValue: $0), attributes: ["name": .string($0)])
        }
        try await database.insert(teams)
        let person = ModelData(
            entity: "Person",
            id: "person1",
            attributes: ["name": .string("Alice")],
            relationships: ["team": .toOne("team2")]
        )
        try await database.insert(person)
        // cache team2 with its member
        let cached = try #require(try await database.fetch("Team", for: "team2"))
        #expect(cached.relationships["members"] == .toMany(["person1"]))
        // claiming the person for team1 also changes team2's derived `members`,
        // a row of the written entity other than the one written
        var team1 = teams[0]
        team1.relationships["members"] = .toMany(["person1"])
        try await database.insert(team1)
        let fetched = try #require(try await database.fetch("Team", for: "team2"))
        #expect(fetched.relationships["members"] == .toMany([]))
    }

    @Test func deleteRemovesFromCache() async throws {
        let database = try makeDatabase()
        let person = ModelData(
            entity: "Person",
            id: "person1",
            attributes: ["name": .string("Alice")]
        )
        try await database.insert(person)
        _ = try await database.fetch("Person", for: "person1")
        try await database.delete("Person", for: "person1")
        #expect(await database.cache["Person"] == nil)
        #expect(try await database.fetch("Person", for: "person1") == nil)
    }

    @Test func deleteNullifiesCachedReferences() async throws {
        let database = try makeDatabase()
        let team = ModelData(entity: "Team", id: "team1", attributes: ["name": .string("Red")])
        let person = ModelData(
            entity: "Person",
            id: "person1",
            attributes: ["name": .string("Alice")],
            relationships: ["team": .toOne("team1")]
        )
        try await database.insert(team)
        try await database.insert(person)
        // cache the person with its team reference
        let cached = try #require(try await database.fetch("Person", for: "person1"))
        #expect(cached.relationships["team"] == .toOne("team1"))
        // deleting the team nullifies the cached person's foreign key
        try await database.delete("Team", for: "team1")
        let fetched = try #require(try await database.fetch("Person", for: "person1"))
        #expect(fetched.relationships["team"] == .null)
    }
}
