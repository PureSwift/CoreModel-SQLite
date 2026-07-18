//
//  ModelDataTests.swift
//  CoreModel-SQLite
//
//  Unit tests for the `ModelData` <-> table row conversions, covering the error
//  paths not reached through the normal insert/fetch round trip.
//

import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

private var personEntity: EntityDescription {
    testModel.entities.first { $0.id == "Person" }!
}

// MARK: - columnValues

@Test func columnValuesRejectsToManyOnToOneRelationship() throws {
    // "team" is a to-one relationship; a to-many value can't be a foreign key column.
    let person = ModelData(
        entity: "Person",
        id: "person1",
        attributes: ["name": .string("Alice")],
        relationships: ["team": .toMany(["a", "b"])]
    )
    #expect(throws: SQLiteDatabaseError.self) {
        _ = try person.columnValues(for: personEntity)
    }
}

// MARK: - init(row:)

@Test func decodeRowRoundTrip() throws {
    let row: [String: Binding?] = [
        SQLiteDatabase.primaryKeyColumn: .text("person1"),
        "name": .text("Alice"),
        "age": .integer(30),
        "team": .text("team1")
    ]
    let value = try ModelData(row: row, entity: personEntity)
    #expect(value.id == "person1")
    #expect(value.attributes["name"] == .string("Alice"))
    #expect(value.attributes["age"] == .int32(30))
    #expect(value.relationships["team"] == .toOne("team1"))
}

@Test func decodeRowMissingPrimaryKeyThrows() throws {
    // No primary key column present at all.
    #expect(throws: SQLiteDatabaseError.self) {
        _ = try ModelData(row: ["name": .text("Alice")], entity: personEntity)
    }
}

@Test func decodeRowNonTextPrimaryKeyThrows() throws {
    // Primary key present but stored with a non-text storage class.
    let row: [String: Binding?] = [SQLiteDatabase.primaryKeyColumn: .integer(5)]
    #expect(throws: SQLiteDatabaseError.self) {
        _ = try ModelData(row: row, entity: personEntity)
    }
}
