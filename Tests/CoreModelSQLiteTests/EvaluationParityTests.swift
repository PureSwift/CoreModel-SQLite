//
//  EvaluationParityTests.swift
//  CoreModel-SQLite
//
//  The same requests answered by SQLite and by CoreModel's in-memory
//  evaluation (`FetchRequest.evaluate`), which defines what a request returns.
//

import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

private let parityModel = Model(entities: [
    EntityDescription(
        id: "Person",
        attributes: [
            Attribute(id: "name", type: .string),
            Attribute(id: "age", type: .int32),
            Attribute(id: "joined", type: .date),
        ],
        relationships: []
    )
])

private let parityPeople: [ModelData] = [
    ModelData(entity: "Person", id: "ada", attributes: ["name": .string("Ada"), "age": .int32(36), "joined": .date(Date(timeIntervalSince1970: 30))]),
    ModelData(entity: "Person", id: "alan", attributes: ["name": .string("alan"), "age": .int32(41), "joined": .null]),
    ModelData(entity: "Person", id: "edsger", attributes: ["name": .string("Édsger"), "age": .int32(17), "joined": .date(Date(timeIntervalSince1970: 10))]),
    ModelData(entity: "Person", id: "grace", attributes: ["name": .string("Grace"), "age": .int32(45), "joined": .null]),
    ModelData(entity: "Person", id: "linus", attributes: ["name": .string("Linus"), "age": .int32(17), "joined": .date(Date(timeIntervalSince1970: 20))]),
    ModelData(entity: "Person", id: "star", attributes: ["name": .string("a*b?[c]"), "age": .int32(1), "joined": .null]),
    ModelData(entity: "Person", id: "eve", attributes: ["name": .string("ÉVE"), "age": .int32(2), "joined": .null]),
]

private func string(
    _ type: FetchRequest.Predicate.Comparison.Operator,
    _ value: String,
    _ options: Set<FetchRequest.Predicate.Comparison.Option> = []
) -> FetchRequest.Predicate {
    .comparison(.init(left: .keyPath("name"), right: .attribute(.string(value)), type: type, options: options))
}

@Test func requestsAnswerAsCoreModelEvaluatesThem() async throws {
    let database = try SQLiteDatabase(path: ":memory:", model: parityModel)
    try await database.insert(parityPeople)
    let predicates: [FetchRequest.Predicate?] = [
        nil,
        .compound(.and([])),
        .compound(.or([])),
        .compound(.not(.compound(.or([])))),
        // Case-sensitive by default.
        string(.beginsWith, "a"),
        string(.beginsWith, "A"),
        string(.endsWith, "S"),
        string(.contains, "ra"),
        string(.contains, "ds"),
        string(.contains, ""),
        string(.like, "a*"),
        string(.like, "?d?"),
        // Case-insensitive, beyond ASCII.
        string(.beginsWith, "a", [.caseInsensitive]),
        string(.equalTo, "éve", [.caseInsensitive]),
        string(.beginsWith, "éd", [.caseInsensitive]),
        string(.contains, "VE", [.caseInsensitive]),
        string(.like, "É*", [.caseInsensitive]),
        // Wildcard characters in a pattern are literal.
        string(.beginsWith, "a*"),
        string(.contains, "b?["),
        string(.endsWith, "[c]"),
        string(.like, "a[*]*"),
        // IN against a string is a substring test.
        string(.in, "Ada Lovelace"),
        string(.in, "ada lovelace"),
        string(.in, "ada lovelace", [.caseInsensitive]),
    ]
    let sorts: [[FetchRequest.SortDescriptor]] = [
        [],
        [.init(property: "age")],
        [.init(property: "age", ascending: false)],
        [.init(property: "joined")],
        [.init(property: "joined", ascending: false)],
    ]
    for predicate in predicates {
        for sort in sorts {
            for (limit, offset) in [(0, 0), (2, 0), (2, 1), (0, 5), (3, 9)] {
                let request = FetchRequest(entity: "Person", sortDescriptors: sort, predicate: predicate, fetchLimit: limit, fetchOffset: offset)
                let expected = request.evaluate(parityPeople).map(\.id)
                #expect(try await database.fetchID(request) == expected, "\(String(describing: predicate)) \(sort) \(limit) \(offset)")
                #expect(try await database.fetch(request).map(\.id) == expected)
                #expect(try await database.count(request) == UInt(expected.count), "\(String(describing: predicate)) \(limit) \(offset)")
            }
        }
    }
}

@Test func theViewContextLowercasesAsSwiftDoes() async throws {
    let path = FileManager.default.temporaryDirectory.appendingPathComponent("parity-\(UUID()).sqlite").path
    defer { try? FileManager.default.removeItem(atPath: path) }
    let database = try SQLiteDatabase(path: path, model: parityModel)
    try await database.insert(parityPeople)
    let context = try await SQLiteViewContext(path: path, model: parityModel)
    let request = FetchRequest(entity: "Person", predicate: string(.equalTo, "éve", [.caseInsensitive]))
    #expect(try await context.fetchID(request) == ["eve"])
}
