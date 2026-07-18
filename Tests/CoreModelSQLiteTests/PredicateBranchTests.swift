//
//  PredicateBranchTests.swift
//  CoreModel-SQLite
//
//  Covers the remaining predicate-translation branches: invalid expression
//  shapes, function-call comparison edge cases (NULL, nested arguments,
//  unsupported operators), and the scalar/collection binding error paths.
//

import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

/// Returns the absolute value of an integer argument, or `nil` for anything else.
private let magnitude = DatabaseFunction(name: "magnitude", argumentCount: 1) { arguments in
    guard case let .int64(value) = arguments[0] else { return nil }
    return .int64(abs(value))
}

private func makeMagnitudeDatabase() async throws -> SQLiteDatabase {
    let database = try makeDatabase()
    try await database.register(function: magnitude)
    try await database.insert([
        ModelData(entity: "Person", id: "a", attributes: ["name": .string("A"), "age": .int32(30)]),
        ModelData(entity: "Person", id: "b", attributes: ["name": .string("B"), "age": .int32(40)])
    ])
    return database
}

private func magnitudeOfAge() -> FetchRequest.Predicate.Expression {
    .function(.init(name: "magnitude", arguments: [.keyPath("age")]))
}

// MARK: - Invalid expression shapes

@Test func comparisonWithNonKeyPathLeftThrows() async throws {
    let database = try await makeMagnitudeDatabase()
    // Left side is a constant, which is neither a keyPath nor a function.
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .attribute(.int32(5)), right: .attribute(.int32(5)), type: .equalTo))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}

@Test func comparisonWithKeyPathRightThrows() async throws {
    let database = try await makeMagnitudeDatabase()
    // A column-to-column comparison has no constant binding on the right.
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("age"), right: .keyPath("weight"), type: .equalTo))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}

@Test func inWithSingleConstantValue() async throws {
    let database = try await makeMagnitudeDatabase()
    // `IN` with a single (non-collection) constant falls through to the scalar binding path.
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("age"), right: .attribute(.int32(30)), type: .in))
    )
    #expect(try await database.fetchID(request) == ["a"])
}

// MARK: - Function-call comparisons

@Test func functionComparisonAgainstNull() async throws {
    let database = try makeDatabase()
    let probe = DatabaseFunction(name: "probe", argumentCount: 1) { _ in nil }
    try await database.register(function: probe)
    try await database.insert(ModelData(entity: "Person", id: "a", attributes: ["name": .string("A")]))

    // probe(probe(name)) == NULL  -> nested function argument + IS NULL translation
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(
            left: .function(.init(name: "probe", arguments: [
                .function(.init(name: "probe", arguments: [.keyPath("name")]))
            ])),
            right: .attribute(.null),
            type: .equalTo
        ))
    )
    #expect(try await database.count(request) == 1)
}

@Test func functionComparisonWithModifierThrows() async throws {
    let database = try await makeMagnitudeDatabase()
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(
            left: magnitudeOfAge(),
            right: .attribute(.int32(30)),
            type: .equalTo,
            modifier: .any
        ))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}

@Test func functionComparisonWithUnsupportedOperatorThrows() async throws {
    let database = try await makeMagnitudeDatabase()
    // Only ordering/equality operators are valid against a function result.
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: magnitudeOfAge(), right: .attribute(.string("3")), type: .contains))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}

// MARK: - To-many relationship membership

@Test func toManyMembershipWithUnsupportedOperatorThrows() async throws {
    let database = try makeDatabase()
    // `<` has no membership-subquery translation for a to-many relationship.
    let request = FetchRequest(
        entity: "Person",
        predicate: .comparison(.init(left: .keyPath("events"), right: .relationship(.toOne("e1")), type: .lessThan))
    )
    await #expect(throws: SQLiteDatabaseError.self) {
        try await database.count(request)
    }
}
