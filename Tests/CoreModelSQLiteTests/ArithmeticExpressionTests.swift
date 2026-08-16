//
//  ArithmeticExpressionTests.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

/// Arithmetic expressions, which compile to native SQL operators.
@Suite struct ArithmeticExpressionTests {

    static func makeDatabase() throws -> SQLiteDatabase {
        try SQLiteDatabase(path: temporaryDatabasePath(named: "Arithmetic"), model: testModel)
    }

    static func person(_ id: ObjectID, name: String, age: Int32, weight: Double) -> ModelData {
        ModelData(
            entity: "Person",
            id: id,
            attributes: [
                "name": .string(name),
                "age": .int32(age),
                "weight": .double(weight)
            ]
        )
    }

    static func insertPeople(_ database: SQLiteDatabase) async throws {
        try await database.insert(person("alice", name: "Alice", age: 30, weight: 60.5))
        try await database.insert(person("bob", name: "Bob", age: 41, weight: 80.0))
    }

    private static func arithmetic(
        _ function: FetchRequest.Predicate.ArithmeticExpression.Function,
        _ left: FetchRequest.Predicate.Expression,
        _ right: FetchRequest.Predicate.Expression
    ) -> FetchRequest.Predicate.Expression {
        .arithmetic(.init(function: function, left: left, right: right))
    }

    // MARK: - Integer arithmetic

    @Test func integerAddition() async throws {
        let database = try Self.makeDatabase()
        try await Self.insertPeople(database)
        // age + 10 > 45 — matches Bob (51), not Alice (40)
        let request = FetchRequest(
            entity: "Person",
            predicate: Self.arithmetic(.add, .keyPath("age"), .attribute(.int32(10)))
                .compare(.greaterThan, .attribute(.int64(45)))
        )
        let results = try await database.fetch(request)
        #expect(results.map(\.id) == ["bob"])
    }

    /// Integer division truncates, matching the in-memory engine (`7 / 2` is `3`).
    @Test func integerDivisionTruncates() async throws {
        let database = try Self.makeDatabase()
        try await Self.insertPeople(database)
        // age / 7 == 4 — Alice: 30/7 = 4 (truncated). Bob: 41/7 = 5.
        let request = FetchRequest(
            entity: "Person",
            predicate: Self.arithmetic(.divide, .keyPath("age"), .attribute(.int64(7)))
                .compare(.equalTo, .attribute(.int64(4)))
        )
        let results = try await database.fetch(request)
        #expect(results.map(\.id) == ["alice"])
    }

    @Test func integerModulus() async throws {
        let database = try Self.makeDatabase()
        try await Self.insertPeople(database)
        // age % 2 == 0 — Alice (30), not Bob (41)
        let request = FetchRequest(
            entity: "Person",
            predicate: Self.arithmetic(.modulus, .keyPath("age"), .attribute(.int64(2)))
                .compare(.equalTo, .attribute(.int64(0)))
        )
        let results = try await database.fetch(request)
        #expect(results.map(\.id) == ["alice"])
    }

    /// Division by zero yields SQL `NULL`, which fails every comparison — the same
    /// outcome as the in-memory engine's `nil`.
    @Test func divisionByZeroMatchesNothing() async throws {
        let database = try Self.makeDatabase()
        try await Self.insertPeople(database)
        for op: FetchRequest.Predicate.Comparison.Operator in [.equalTo, .greaterThan, .lessThan] {
            let request = FetchRequest(
                entity: "Person",
                predicate: Self.arithmetic(.divide, .keyPath("age"), .attribute(.int64(0)))
                    .compare(op, .attribute(.int64(0)))
            )
            let results = try await database.fetch(request)
            #expect(results.isEmpty, "\(op) against a division by zero should match nothing")
        }
    }

    // MARK: - Floating point

    @Test func floatingPointArithmetic() async throws {
        let database = try Self.makeDatabase()
        try await Self.insertPeople(database)
        // weight * 2 > 130 — Bob (160), not Alice (121)
        let request = FetchRequest(
            entity: "Person",
            predicate: Self.arithmetic(.multiply, .keyPath("weight"), .attribute(.int64(2)))
                .compare(.greaterThan, .attribute(.double(130)))
        )
        let results = try await database.fetch(request)
        #expect(results.map(\.id) == ["bob"])
    }

    /// Mixed integer/floating-point operands compute in floating point, so integer
    /// division does not truncate when either side is a float — as in memory.
    @Test func mixedOperandsPromote() async throws {
        let database = try Self.makeDatabase()
        try await Self.insertPeople(database)
        // weight / 2 == 30.25 — Alice (60.5 / 2), floating point division
        let request = FetchRequest(
            entity: "Person",
            predicate: Self.arithmetic(.divide, .keyPath("weight"), .attribute(.int64(2)))
                .compare(.equalTo, .attribute(.double(30.25)))
        )
        let results = try await database.fetch(request)
        #expect(results.map(\.id) == ["alice"])
    }

    /// The in-memory engine defines remainder for integers only; SQLite's `%` would
    /// cast a float to integer and silently diverge, so it is rejected instead.
    @Test func floatModulusRejected() async throws {
        let database = try Self.makeDatabase()
        try await Self.insertPeople(database)
        let request = FetchRequest(
            entity: "Person",
            predicate: Self.arithmetic(.modulus, .keyPath("weight"), .attribute(.int64(2)))
                .compare(.equalTo, .attribute(.int64(0)))
        )
        await #expect(throws: (any Error).self) {
            try await database.fetch(request)
        }
    }

    // MARK: - Composition

    @Test func nestedArithmetic() async throws {
        let database = try Self.makeDatabase()
        try await Self.insertPeople(database)
        // (age + 10) * 2 == 80 — Alice ((30+10)*2), not Bob ((41+10)*2 = 102)
        let inner = Self.arithmetic(.add, .keyPath("age"), .attribute(.int64(10)))
        let request = FetchRequest(
            entity: "Person",
            predicate: Self.arithmetic(.multiply, inner, .attribute(.int64(2)))
                .compare(.equalTo, .attribute(.int64(80)))
        )
        let results = try await database.fetch(request)
        #expect(results.map(\.id) == ["alice"])
    }

    @Test func compoundPredicateWithArithmetic() async throws {
        let database = try Self.makeDatabase()
        try await Self.insertPeople(database)
        // (age + 1 > 31) AND (name == "Bob")
        let request = FetchRequest(
            entity: "Person",
            predicate: .compound(.and([
                Self.arithmetic(.add, .keyPath("age"), .attribute(.int64(1)))
                    .compare(.greaterThan, .attribute(.int64(31))),
                "name".compare(.equalTo, .attribute(.string("Bob")))
            ]))
        )
        let results = try await database.fetch(request)
        #expect(results.map(\.id) == ["bob"])
    }

    /// SQL and the in-memory engine agree on the same inputs.
    @Test func agreesWithInMemoryEvaluation() async throws {
        let database = try Self.makeDatabase()
        try await Self.insertPeople(database)
        let rows = try await database.fetch(FetchRequest(entity: "Person"))
        let cases: [(FetchRequest.Predicate.ArithmeticExpression.Function, Int64, FetchRequest.Predicate.Comparison.Operator, Int64)] = [
            (.add, 10, .greaterThan, 45),
            (.subtract, 5, .lessThanOrEqualTo, 25),
            (.multiply, 3, .equalTo, 90),
            (.divide, 7, .equalTo, 4),
            (.modulus, 2, .equalTo, 0)
        ]
        for (function, operand, op, constant) in cases {
            let predicate = Self.arithmetic(.init(rawValue: function.rawValue)!, .keyPath("age"), .attribute(.int64(operand)))
                .compare(op, .attribute(.int64(constant)))
            let sql = try await database.fetch(FetchRequest(entity: "Person", predicate: predicate)).map(\.id)
            let memory = rows.filter { predicate.evaluate(with: $0) }.map(\.id)
            #expect(Set(sql) == Set(memory), "\(function) diverged: sql=\(sql) memory=\(memory)")
        }
    }
}
