//
//  DatabaseBranchTests.swift
//  CoreModel-SQLite
//
//  Covers database-level branches not hit by the main integration tests: the
//  to-many relationship write cases, an invalid sort property, an upsert with no
//  updatable columns, and custom-function arguments of every storage class.
//

import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

// MARK: - To-many relationship writes

@Test func insertToManyRelationshipAsNullClearsLinks() async throws {
    let database = try makeDatabase()
    let people = ["p1", "p2"].map {
        ModelData(entity: "Person", id: ObjectID(rawValue: $0), attributes: ["name": .string($0)])
    }
    try await database.insert(people)
    try await database.insert(ModelData(
        entity: "Event", id: "e1",
        attributes: ["name": .string("E")],
        relationships: ["people": .toMany(["p1", "p2"])]
    ))
    // Re-inserting with `.null` for the to-many relationship clears all links.
    try await database.insert(ModelData(
        entity: "Event", id: "e1",
        attributes: ["name": .string("E")],
        relationships: ["people": .null]
    ))
    let event = try #require(try await database.fetch("Event", for: "e1"))
    #expect(event.relationships["people"] == .toMany([]))
}

@Test func insertToOneValueForToManyRelationshipThrows() async throws {
    let database = try makeDatabase()
    // "people" is a to-many relationship; a to-one value is invalid.
    let event = ModelData(
        entity: "Event", id: "e1",
        attributes: ["name": .string("E")],
        relationships: ["people": .toOne("p1")]
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.insert(event)
    }
}

// MARK: - Upsert with no updatable columns

@Test func upsertWithNoProvidedColumns() async throws {
    let database = try makeDatabase()
    // A ModelData with only a primary key provides no columns to overwrite, so a
    // conflicting re-insert resolves to `DO NOTHING` rather than `DO UPDATE`.
    let bare = ModelData(entity: "Person", id: "p1")
    try await database.insert(bare)
    try await database.insert(bare) // must not throw
    #expect(try await database.count(FetchRequest(entity: "Person")) == 1)
}

// MARK: - Sorting

@Test func sortByUnknownPropertyThrows() async throws {
    let database = try makeDatabase()
    try await database.insert(ModelData(entity: "Person", id: "p1", attributes: ["name": .string("A")]))
    let request = FetchRequest(
        entity: "Person",
        sortDescriptors: [.init(property: "doesNotExist", ascending: true)]
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.fetch(request)
    }
}

// MARK: - Custom-function argument storage classes

@Test func customFunctionReceivesEveryStorageClass() async throws {
    let database = try makeDatabase()
    // A function that always returns NULL — we only care that its argument, of
    // varying storage class, is decoded on the way in.
    let probe = DatabaseFunction(name: "probe", argumentCount: 1) { _ in nil }
    try await database.register(function: probe)
    // name: TEXT, avatar: BLOB, token: NULL (omitted)
    try await database.insert(ModelData(
        entity: "Person", id: "p1",
        attributes: ["name": .string("Alice"), "avatar": .data(Data([1, 2, 3]))]
    ))

    for column in ["name", "avatar", "token"] {
        let request = FetchRequest(
            entity: "Person",
            sortDescriptors: [.init(term: .function(.init(name: "probe", arguments: [.keyPath(.init(rawValue: column))])))]
        )
        // Executes `probe(<column>)` once per row, decoding the argument binding.
        #expect(try await database.fetchID(request) == ["p1"])
    }
}
