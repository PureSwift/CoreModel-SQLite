import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

/// Test model: Person –toOne→ Team (one-to-many inverse "members"),
/// Person ←toMany→ Event (many-to-many via join table).
var testModel: Model { Model(entities: [
    EntityDescription(
        id: "Person",
        attributes: [
            .init(id: "name", type: .string),
            .init(id: "age", type: .int32),
            .init(id: "weight", type: .double),
            .init(id: "born", type: .date),
            .init(id: "isActive", type: .bool),
            .init(id: "avatar", type: .data),
            .init(id: "token", type: .uuid),
            .init(id: "website", type: .url),
            .init(id: "balance", type: .decimal)
        ],
        relationships: [
            .init(id: "team", type: .toOne, destinationEntity: "Team", inverseRelationship: "members"),
            .init(id: "events", type: .toMany, destinationEntity: "Event", inverseRelationship: "people"),
            .init(id: "passport", type: .toOne, destinationEntity: "Passport", inverseRelationship: "owner")
        ]
    ),
    EntityDescription(
        id: "Passport",
        attributes: [
            .init(id: "number", type: .string)
        ],
        relationships: [
            .init(id: "owner", type: .toOne, destinationEntity: "Person", inverseRelationship: "passport")
        ]
    ),
    EntityDescription(
        id: "Team",
        attributes: [
            .init(id: "name", type: .string)
        ],
        relationships: [
            .init(id: "members", type: .toMany, destinationEntity: "Person", inverseRelationship: "team")
        ]
    ),
    EntityDescription(
        id: "Event",
        attributes: [
            .init(id: "name", type: .string),
            .init(id: "date", type: .date)
        ],
        relationships: [
            .init(id: "people", type: .toMany, destinationEntity: "Person", inverseRelationship: "events")
        ]
    )
]) }

/// Path for an isolated, file-backed test database. Tests always run against a real
/// SQLite file, never an in-memory connection, so file I/O behavior is exercised too.
func temporaryDatabasePath(named name: String) -> String {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("CoreModelSQLite-\(name)-\(UUID()).sqlite")
        .path
}

func makeDatabase() throws -> SQLiteDatabase {
    try SQLiteDatabase(path: temporaryDatabasePath(named: "Tests"), model: testModel)
}

@Test func attributeRoundTrip() async throws {
    let database = try makeDatabase()
    let uuid = UUID()
    let born = Date(timeIntervalSince1970: 1_000_000)
    let avatar = Data([0x01, 0x02, 0x03])
    let person = ModelData(
        entity: "Person",
        id: "person1",
        attributes: [
            "name": .string("Alice"),
            "age": .int32(30),
            "weight": .double(65.5),
            "born": .date(born),
            "isActive": .bool(true),
            "avatar": .data(avatar),
            "token": .uuid(uuid),
            "website": .url(URL(string: "https://example.com")!),
            "balance": .decimal(Decimal(string: "199.99")!)
        ]
    )
    try await database.insert(person)
    let fetched = try #require(try await database.fetch("Person", for: "person1"))
    #expect(fetched.id == person.id)
    #expect(fetched.attributes["name"] == .string("Alice"))
    #expect(fetched.attributes["age"] == .int32(30))
    #expect(fetched.attributes["weight"] == .double(65.5))
    #expect(fetched.attributes["born"] == .date(born))
    #expect(fetched.attributes["isActive"] == .bool(true))
    #expect(fetched.attributes["avatar"] == .data(avatar))
    #expect(fetched.attributes["token"] == .uuid(uuid))
    #expect(fetched.attributes["website"] == .url(URL(string: "https://example.com")!))
    #expect(fetched.attributes["balance"] == .decimal(Decimal(string: "199.99")!))
    #expect(fetched.relationships["team"] == .null)
}

@Test func nullAttributes() async throws {
    let database = try makeDatabase()
    let person = ModelData(
        entity: "Person",
        id: "person1",
        attributes: ["name": .string("Bob")] // everything else omitted
    )
    try await database.insert(person)
    let fetched = try #require(try await database.fetch("Person", for: "person1"))
    #expect(fetched.attributes["name"] == .string("Bob"))
    #expect(fetched.attributes["age"] == .null)
    #expect(fetched.attributes["token"] == .null)
}

@Test func upsert() async throws {
    let database = try makeDatabase()
    var person = ModelData(
        entity: "Person",
        id: "person1",
        attributes: ["name": .string("Alice"), "age": .int32(30)]
    )
    try await database.insert(person)
    person.attributes["age"] = .int32(31)
    try await database.insert(person)
    let fetched = try #require(try await database.fetch("Person", for: "person1"))
    #expect(fetched.attributes["age"] == .int32(31))
    let count = try await database.count(FetchRequest(entity: "Person"))
    #expect(count == 1)
}

@Test func fetchMissing() async throws {
    let database = try makeDatabase()
    let fetched = try await database.fetch("Person", for: "unknown")
    #expect(fetched == nil)
    await #expect(throws: CoreModelError.self) {
        try await database.fetch("Unknown", for: "person1")
    }
}

@Test func predicateFetch() async throws {
    let database = try makeDatabase()
    let people = (0..<10).map { index in
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

    // comparison
    let over25 = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("age"), right: .attribute(.int32(25)), type: .greaterThan))
    )
    let overCount = try await database.count(over25)
    #expect(overCount == 4)

    // compound + sort + limit
    let request = FetchRequest(
        entity: "Person",
        sortDescriptors: [.init(property: "age", ascending: false)],
        predicate: .compound(.and([
            .comparison(.init(left: .keyPath("age"), right: .attribute(.int32(21)), type: .greaterThanOrEqualTo)),
            .comparison(.init(left: .keyPath("age"), right: .attribute(.int32(28)), type: .lessThan))
        ])),
        fetchLimit: 3
    )
    let results = try await database.fetch(request)
    #expect(results.count == 3)
    #expect(results.map { $0.attributes["age"] } == [.int32(27), .int32(26), .int32(25)])

    // string operators
    let beginsWith = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("name"), right: .attribute(.string("Person 1")), type: .beginsWith))
    )
    let beginsWithIDs = try await database.fetchID(beginsWith)
    #expect(beginsWithIDs == ["person1"])

    // IN
    let inRequest = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("id"), right: .relationship(.toMany(["person2", "person4"])), type: .in))
    )
    let inCount = try await database.count(inRequest)
    #expect(inCount == 2)
}

@Test func toOneRelationship() async throws {
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

    let fetchedPerson = try #require(try await database.fetch("Person", for: "person1"))
    #expect(fetchedPerson.relationships["team"] == .toOne("team1"))

    // inverse to-many is derived from the foreign key
    let fetchedTeam = try #require(try await database.fetch("Team", for: "team1"))
    #expect(fetchedTeam.relationships["members"] == .toMany(["person1"]))
}

@Test func oneToManyRelationship() async throws {
    let database = try makeDatabase()
    let people = ["person1", "person2", "person3"].map {
        ModelData(entity: "Person", id: ObjectID(rawValue: $0), attributes: ["name": .string($0)])
    }
    try await database.insert(people)
    // setting the to-many side rewrites the foreign keys
    let team = ModelData(
        entity: "Team",
        id: "team1",
        attributes: ["name": .string("Red")],
        relationships: ["members": .toMany(["person1", "person2"])]
    )
    try await database.insert(team)

    let person1 = try #require(try await database.fetch("Person", for: "person1"))
    #expect(person1.relationships["team"] == .toOne("team1"))
    let person3 = try #require(try await database.fetch("Person", for: "person3"))
    #expect(person3.relationships["team"] == .null)

    // replacing the set removes stale links
    var updatedTeam = team
    updatedTeam.relationships["members"] = .toMany(["person3"])
    try await database.insert(updatedTeam)
    let fetchedTeam = try #require(try await database.fetch("Team", for: "team1"))
    #expect(fetchedTeam.relationships["members"] == .toMany(["person3"]))
    let person2 = try #require(try await database.fetch("Person", for: "person2"))
    #expect(person2.relationships["team"] == .null)
}

@Test func manyToManyRelationship() async throws {
    let database = try makeDatabase()
    let people = ["person1", "person2"].map {
        ModelData(entity: "Person", id: ObjectID(rawValue: $0), attributes: ["name": .string($0)])
    }
    try await database.insert(people)
    let event = ModelData(
        entity: "Event",
        id: "event1",
        attributes: ["name": .string("WWDC"), "date": .date(Date(timeIntervalSince1970: 2_000_000))],
        relationships: ["people": .toMany(["person1", "person2"])]
    )
    try await database.insert(event)

    let fetchedEvent = try #require(try await database.fetch("Event", for: "event1"))
    #expect(fetchedEvent.relationships["people"] == .toMany(["person1", "person2"]))

    // inverse side reads the same join table
    let person1 = try #require(try await database.fetch("Person", for: "person1"))
    #expect(person1.relationships["events"] == .toMany(["event1"]))

    // writing from the inverse side
    let person2 = ModelData(
        entity: "Person",
        id: "person2",
        attributes: ["name": .string("person2")],
        relationships: ["events": .toMany([])]
    )
    try await database.insert(person2)
    let updatedEvent = try #require(try await database.fetch("Event", for: "event1"))
    #expect(updatedEvent.relationships["people"] == .toMany(["person1"]))
}

@Test func delete() async throws {
    let database = try makeDatabase()
    let team = ModelData(entity: "Team", id: "team1", attributes: ["name": .string("Red")])
    let event = ModelData(entity: "Event", id: "event1", attributes: ["name": .string("WWDC")])
    let person = ModelData(
        entity: "Person",
        id: "person1",
        attributes: ["name": .string("Alice")],
        relationships: [
            "team": .toOne("team1"),
            "events": .toMany(["event1"])
        ]
    )
    try await database.insert(team)
    try await database.insert(event)
    try await database.insert(person)

    // deleting the team nullifies the foreign key on Person
    try await database.delete("Team", for: "team1")
    let fetchedPerson = try #require(try await database.fetch("Person", for: "person1"))
    #expect(fetchedPerson.relationships["team"] == .null)

    // deleting the person removes join table links
    try await database.delete("Person", for: "person1")
    #expect(try await database.fetch("Person", for: "person1") == nil)
    let fetchedEvent = try #require(try await database.fetch("Event", for: "event1"))
    // an empty to-many is `.toMany([])`, not `.null` — matches CoreData, which never
    // reports `.null` for a to-many relationship, only an empty set
    #expect(fetchedEvent.relationships["people"] == .toMany([]))
}

/// Deleting either side of a one-to-one relationship must nullify the *other* side's
/// foreign key — CoreData always nullifies on delete (`NSRelationshipDescription` never
/// sets a cascade or deny rule), and unlike a one-to-many relationship, a one-to-one's
/// inverse foreign key isn't dropped automatically by deleting the entity's own row.
@Test func oneToOneRelationshipDeleteNullifiesInverse() async throws {
    let database = try makeDatabase()
    let person = ModelData(
        entity: "Person",
        id: "person1",
        attributes: ["name": .string("Alice")],
        relationships: ["passport": .toOne("passport1")]
    )
    let passport = ModelData(
        entity: "Passport",
        id: "passport1",
        attributes: ["number": .string("X123")],
        relationships: ["owner": .toOne("person1")]
    )
    try await database.insert(person)
    try await database.insert(passport)

    // deleting the passport nullifies the foreign key on Person
    try await database.delete("Passport", for: "passport1")
    let fetchedPerson = try #require(try await database.fetch("Person", for: "person1"))
    #expect(fetchedPerson.relationships["passport"] == .null)

    // re-link, then delete from the other side: deleting the person nullifies Passport.owner
    var updatedPerson = person
    updatedPerson.relationships["passport"] = .toOne("passport1")
    try await database.insert(updatedPerson)
    try await database.insert(passport)
    try await database.delete("Person", for: "person1")
    let fetchedPassport = try #require(try await database.fetch("Passport", for: "passport1"))
    #expect(fetchedPassport.relationships["owner"] == .null)
}

@Test func fetchOffset() async throws {
    let database = try makeDatabase()
    let people = (0..<5).map { index in
        ModelData(
            entity: "Person",
            id: ObjectID(rawValue: "person\(index)"),
            attributes: ["name": .string("Person \(index)"), "age": .int32(Int32(20 + index))]
        )
    }
    try await database.insert(people)
    let request = FetchRequest(
        entity: "Person",
        sortDescriptors: [.init(property: "age", ascending: true)],
        fetchLimit: 2,
        fetchOffset: 2
    )
    let ids = try await database.fetchID(request)
    #expect(ids == ["person2", "person3"])
}
