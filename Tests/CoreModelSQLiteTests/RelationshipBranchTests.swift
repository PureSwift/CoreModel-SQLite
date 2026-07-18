//
//  RelationshipBranchTests.swift
//  CoreModel-SQLite
//
//  Covers the symmetric (self-inverse) many-to-many relationship paths — the
//  `UNION` halves of the join-table fetch, delete, and membership subquery — plus
//  a missing inverse relationship and a fetch offset with no limit.
//

import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

/// A single entity with a symmetric self-relationship (`friends` is its own inverse),
/// which resolves to a symmetric join table.
private var symmetricModel: Model {
    Model(entities: [
        EntityDescription(
            id: "Node",
            attributes: [.init(id: "name", type: .string)],
            relationships: [
                .init(id: "friends", type: .toMany, destinationEntity: "Node", inverseRelationship: "friends")
            ]
        )
    ])
}

@Test func symmetricManyToManyRelationship() async throws {
    let database = try SQLiteDatabase(path: temporaryDatabasePath(named: "Symmetric"), model: symmetricModel)
    let nodes = ["a", "b", "c"].map {
        ModelData(entity: "Node", id: ObjectID(rawValue: $0), attributes: ["name": .string($0)])
    }
    try await database.insert(nodes)

    // a befriends b and c; symmetry means b and c befriend a in return.
    var a = nodes[0]
    a.relationships["friends"] = .toMany(["b", "c"])
    try await database.insert(a)

    // Reading back exercises the symmetric UNION in JoinTable.fetch.
    let fetchedA = try #require(try await database.fetch("Node", for: "a"))
    #expect(fetchedA.relationships["friends"] == .toMany(["b", "c"]))
    let fetchedB = try #require(try await database.fetch("Node", for: "b"))
    #expect(fetchedB.relationships["friends"] == .toMany(["a"]))

    // Membership predicate exercises the symmetric UNION in the query subquery:
    // which nodes count `a` among their friends? -> b and c.
    let request = FetchRequest(
        entity: "Node",
        predicate: .comparison(.init(left: .keyPath("friends"), right: .relationship(.toOne("a")), type: .contains))
    )
    let ids = try await database.fetchID(request).sorted { $0.rawValue < $1.rawValue }
    #expect(ids == ["b", "c"])

    // Re-writing the set exercises the symmetric branch of removeAll.
    a.relationships["friends"] = .toMany(["b"])
    try await database.insert(a)
    let updatedC = try #require(try await database.fetch("Node", for: "c"))
    #expect(updatedC.relationships["friends"] == .toMany([]))
}

/// A to-many relationship whose declared inverse doesn't exist on the destination.
private var missingInverseModel: Model {
    Model(entities: [
        EntityDescription(
            id: "A",
            attributes: [.init(id: "name", type: .string)],
            relationships: [
                .init(id: "items", type: .toMany, destinationEntity: "B", inverseRelationship: "missing")
            ]
        ),
        EntityDescription(id: "B", attributes: [.init(id: "name", type: .string)], relationships: [])
    ])
}

@Test func missingInverseRelationshipThrows() async throws {
    let path = temporaryDatabasePath(named: "MissingInverse")
    // Building the schema resolves the to-many relationship's inverse type, which fails
    // because the destination entity has no relationship named "missing".
    await #expect(throws: CoreModelError.self) {
        let database = try SQLiteDatabase(path: path, model: missingInverseModel)
        try await database.insert(ModelData(entity: "B", id: "b1", attributes: ["name": .string("B")]))
    }
}

@Test func fetchOffsetWithoutLimit() async throws {
    let database = try makeDatabase()
    let people = (0..<5).map { index in
        ModelData(
            entity: "Person",
            id: ObjectID(rawValue: "p\(index)"),
            attributes: ["name": .string("P\(index)"), "age": .int32(Int32(index))]
        )
    }
    try await database.insert(people)
    // Offset with no limit -> `LIMIT -1 OFFSET n`.
    let request = FetchRequest(
        entity: "Person",
        sortDescriptors: [.init(property: "age", ascending: true)],
        fetchOffset: 2
    )
    #expect(try await database.fetchID(request) == ["p2", "p3", "p4"])
}
