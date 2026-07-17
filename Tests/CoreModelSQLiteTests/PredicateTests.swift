//
//  PredicateTests.swift
//  CoreModel-SQLite
//
//  Exercises the predicate → SQL `WHERE` clause translation in Predicate.swift
//  through the public fetch API, covering the operators, modifiers, and error
//  paths not touched by the higher-level integration tests.
//

import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

/// A small fixture of people with predictable, easy-to-filter attributes.
private func makePeopleDatabase() async throws -> SQLiteDatabase {
    let database = try makeDatabase()
    let people = [
        ModelData(entity: "Person", id: "alice", attributes: [
            "name": .string("Alice"), "age": .int32(30), "weight": .double(60)
        ]),
        ModelData(entity: "Person", id: "bob", attributes: [
            "name": .string("Bob"), "age": .int32(40), "weight": .double(80)
        ]),
        ModelData(entity: "Person", id: "carol", attributes: [
            "name": .string("Carol"), "age": .int32(50) // weight omitted -> NULL
        ])
    ]
    try await database.insert(people)
    return database
}

// MARK: - Constant & compound predicates

@Test func constantPredicateTrueAndFalse() async throws {
    let database = try await makePeopleDatabase()
    let all = try await database.count(FetchRequest(entity: "Person", predicate: .value(true)))
    #expect(all == 3)
    let none = try await database.count(FetchRequest(entity: "Person", predicate: .value(false)))
    #expect(none == 0)
}

@Test func notCompound() async throws {
    let database = try await makePeopleDatabase()
    let request = FetchRequest(
        entity: "Person",
        predicate: .compound(.not(
            .comparison(.init(left: .keyPath("name"), right: .attribute(.string("Alice")), type: .equalTo))
        ))
    )
    let ids = try await database.fetchID(request).sorted { $0.rawValue < $1.rawValue }
    #expect(ids == ["bob", "carol"])
}

@Test func emptyCompoundMatchesEverything() async throws {
    let database = try await makePeopleDatabase()
    let and = try await database.count(FetchRequest(entity: "Person", predicate: .compound(.and([]))))
    #expect(and == 3)
    let or = try await database.count(FetchRequest(entity: "Person", predicate: .compound(.or([]))))
    #expect(or == 3)
}

// MARK: - NULL handling

@Test func nullEquality() async throws {
    let database = try await makePeopleDatabase()
    // weight IS NULL
    let isNull = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("weight"), right: .attribute(.null), type: .equalTo))
    )
    #expect(try await database.fetchID(isNull) == ["carol"])
    // weight IS NOT NULL
    let notNull = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("weight"), right: .attribute(.null), type: .notEqualTo))
    )
    let ids = try await database.fetchID(notNull).sorted { $0.rawValue < $1.rawValue }
    #expect(ids == ["alice", "bob"])
}

@Test func toOneRelationshipNullComparison() async throws {
    let database = try await makePeopleDatabase()
    // team IS NULL for everyone (no team assigned)
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("team"), right: .relationship(.null), type: .equalTo))
    )
    #expect(try await database.count(request) == 3)
}

// MARK: - String operators

@Test func caseInsensitiveEquality() async throws {
    let database = try await makePeopleDatabase()
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(
            left: .keyPath("name"),
            right: .attribute(.string("alice")),
            type: .equalTo,
            options: [.caseInsensitive]
        ))
    )
    #expect(try await database.fetchID(request) == ["alice"])
}

@Test func endsWithAndContains() async throws {
    let database = try await makePeopleDatabase()
    let endsWith = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("name"), right: .attribute(.string("ob")), type: .endsWith))
    )
    #expect(try await database.fetchID(endsWith) == ["bob"])

    let contains = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("name"), right: .attribute(.string("aro")), type: .contains))
    )
    #expect(try await database.fetchID(contains) == ["carol"])
}

@Test func likeWithWildcards() async throws {
    let database = try await makePeopleDatabase()
    // Cocoa-style wildcards: `*` -> any run, `?` -> single char
    let star = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("name"), right: .attribute(.string("A*")), type: .like))
    )
    #expect(try await database.fetchID(star) == ["alice"])

    let question = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("name"), right: .attribute(.string("Bo?")), type: .like))
    )
    #expect(try await database.fetchID(question) == ["bob"])
}

// MARK: - IN / BETWEEN

@Test func inWithEmptySetMatchesNothing() async throws {
    let database = try await makePeopleDatabase()
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("id"), right: .relationship(.toMany([])), type: .in))
    )
    #expect(try await database.count(request) == 0)
}

@Test func betweenBounds() async throws {
    let database = try await makePeopleDatabase()
    // id BETWEEN "alice" AND "bob" (lexical) -> alice, bob
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(
            left: .keyPath("id"),
            right: .relationship(.toMany(["alice", "bob"])),
            type: .between
        ))
    )
    let ids = try await database.fetchID(request).sorted { $0.rawValue < $1.rawValue }
    #expect(ids == ["alice", "bob"])
}

@Test func betweenWithWrongCountThrows() async throws {
    let database = try await makePeopleDatabase()
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(
            left: .keyPath("id"),
            right: .relationship(.toMany(["alice"])), // needs exactly two
            type: .between
        ))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}

// MARK: - To-many relationship membership

@Test func toManyMembershipViaJoinTable() async throws {
    // Person <-toMany-> Event (many-to-many, join table)
    let database = try makeDatabase()
    let people = ["p1", "p2", "p3"].map {
        ModelData(entity: "Person", id: ObjectID(rawValue: $0), attributes: ["name": .string($0)])
    }
    try await database.insert(people)
    let event = ModelData(
        entity: "Event",
        id: "event1",
        attributes: ["name": .string("WWDC")],
        relationships: ["people": .toMany(["p1", "p2"])]
    )
    try await database.insert(event)

    // ANY events == event1  (contains / equalTo on a to-many relationship)
    let contains = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("events"), right: .relationship(.toOne("event1")), type: .contains))
    )
    let ids = try await database.fetchID(contains).sorted { $0.rawValue < $1.rawValue }
    #expect(ids == ["p1", "p2"])

    // events IN {event1}
    let inSet = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("events"), right: .relationship(.toMany(["event1"])), type: .in))
    )
    #expect(try await database.count(inSet) == 2)

    // empty membership set matches nothing
    let empty = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("events"), right: .relationship(.toMany([])), type: .in))
    )
    #expect(try await database.count(empty) == 0)
}

@Test func toManyMembershipViaForeignKey() async throws {
    // Team <-toMany- members, inverse Person.team is toOne (one-to-many branch)
    let database = try makeDatabase()
    let people = ["p1", "p2"].map {
        ModelData(entity: "Person", id: ObjectID(rawValue: $0), attributes: ["name": .string($0)])
    }
    try await database.insert(people)
    let team = ModelData(
        entity: "Team",
        id: "team1",
        attributes: ["name": .string("Red")],
        relationships: ["members": .toMany(["p1"])]
    )
    try await database.insert(team)

    // Teams whose members contain p1
    let request = FetchRequest(
        entity: "Team",
        predicate: .comparison(.init(left: .keyPath("members"), right: .relationship(.toOne("p1")), type: .contains))
    )
    #expect(try await database.fetchID(request) == ["team1"])
}

@Test func toManyMembershipInvalidModifierThrows() async throws {
    let database = try makeDatabase()
    // `.all` has no direct SQL translation for a to-many relationship
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(
            left: .keyPath("events"),
            right: .relationship(.toOne("event1")),
            type: .contains,
            modifier: .all
        ))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}

// MARK: - Function-call comparisons

private let magnitudeFunction = DatabaseFunction(name: "magnitude", argumentCount: 1) { arguments in
    guard case let .int64(value) = arguments[0] else { return nil }
    return .int64(abs(value))
}

@Test func functionComparisonEqualTo() async throws {
    let database = try makeDatabase()
    try await database.register(function: magnitudeFunction)
    let people = [
        ModelData(entity: "Person", id: "a", attributes: ["name": .string("A"), "age": .int32(30)]),
        ModelData(entity: "Person", id: "b", attributes: ["name": .string("B"), "age": .int32(40)])
    ]
    try await database.insert(people)

    let magnitudeOfAge = FetchRequest.Predicate.Expression.function(
        .init(name: "magnitude", arguments: [.keyPath("age")])
    )
    // magnitude(age) == 30
    let equalTo = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: magnitudeOfAge, right: .attribute(.int32(30)), type: .equalTo))
    )
    #expect(try await database.fetchID(equalTo) == ["a"])

    // magnitude(age) != 30
    let notEqualTo = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: magnitudeOfAge, right: .attribute(.int32(30)), type: .notEqualTo))
    )
    #expect(try await database.fetchID(notEqualTo) == ["b"])
}

// MARK: - Error paths

@Test func modifierOnColumnComparisonThrows() async throws {
    let database = try await makePeopleDatabase()
    // A modifier is only valid on a to-many relationship, not a scalar column.
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(
            left: .keyPath("age"),
            right: .attribute(.int32(30)),
            type: .equalTo,
            modifier: .any
        ))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}

@Test func matchesOperatorThrows() async throws {
    let database = try await makePeopleDatabase()
    // Regular-expression matching has no plain-SQL translation.
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("name"), right: .attribute(.string("A.*")), type: .matches))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}

@Test func likePatternRequiresStringThrows() async throws {
    let database = try await makePeopleDatabase()
    // beginsWith needs a string operand; an int cannot form a LIKE pattern.
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("name"), right: .attribute(.int32(5)), type: .beginsWith))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}

@Test func unknownColumnThrows() async throws {
    let database = try await makePeopleDatabase()
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("doesNotExist"), right: .attribute(.int32(1)), type: .equalTo))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}

@Test func toManyValueInScalarComparisonThrows() async throws {
    let database = try await makePeopleDatabase()
    // A to-many relationship value cannot be a single scalar binding.
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(
            left: .keyPath("team"),
            right: .relationship(.toMany(["x", "y"])),
            type: .equalTo
        ))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}
