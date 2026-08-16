//
//  CompositeAttributeTests.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

import Foundation
import Testing
import CoreModel
import SQLite
@testable import CoreModelSQLite

/// Composite attributes, which are expanded into one column per leaf element.
@Suite struct CompositeAttributeTests {

    /// `location` is a flat composite; `address` nests one composite inside another.
    static var model: Model { Model(entities: [
        EntityDescription(
            id: "Facility",
            attributes: [
                .init(id: "name", type: .string),
                .init(id: "location", elements: [
                    .init(id: "latitude", type: .double),
                    .init(id: "longitude", type: .double)
                ]),
                .init(id: "address", elements: [
                    .init(id: "street", type: .string),
                    .init(id: "location", elements: [
                        .init(id: "latitude", type: .double),
                        .init(id: "longitude", type: .double)
                    ])
                ])
            ],
            relationships: []
        )
    ]) }

    static func makeDatabase() throws -> SQLiteDatabase {
        try SQLiteDatabase(path: temporaryDatabasePath(named: "Composite"), model: model)
    }

    static func facility(
        id: ObjectID,
        name: String,
        latitude: Double,
        longitude: Double,
        street: String = "1 Main",
        innerLatitude: Double = 1.5
    ) -> ModelData {
        ModelData(
            entity: "Facility",
            id: id,
            attributes: [
                "name": .string(name),
                "location": .composite([
                    "latitude": .double(latitude),
                    "longitude": .double(longitude)
                ]),
                "address": .composite([
                    "street": .string(street),
                    "location": .composite([
                        "latitude": .double(innerLatitude),
                        "longitude": .double(2.5)
                    ])
                ])
            ]
        )
    }

    // MARK: - Column expansion

    @Test func columnExpansion() {
        let entity = Self.model.entities[0]
        let names = entity.attributeColumns.map(\.name).sorted()
        #expect(names == [
            "address.location.latitude",
            "address.location.longitude",
            "address.street",
            "location.latitude",
            "location.longitude",
            "name"
        ])
        // every expanded column is a scalar type
        #expect(entity.attributeColumns.allSatisfy { $0.type.isComposite == false })
        // and the leaf path is preserved
        let deep = entity.attributeColumns.first { $0.name == "address.location.latitude" }
        #expect(deep?.path == ["address", "location", "latitude"])
        #expect(deep?.type == .double)
    }

    /// The table has a real, natively typed column per leaf — no JSON, no blob.
    @Test func schemaHasLeafColumns() throws {
        let path = temporaryDatabasePath(named: "CompositeSchema")
        _ = try SQLiteDatabase(path: path, model: Self.model)
        let reader = try Connection(path: path, isReadOnly: true)
        let statement = try reader.prepare("SELECT name, type FROM pragma_table_info('Facility')")
        var byName = [String: String]()
        while let row = try statement.failableNext() {
            byName[row[0]?.textValue ?? ""] = row[1]?.textValue ?? ""
        }
        #expect(byName["location.latitude"] == "REAL")
        #expect(byName["address.location.latitude"] == "REAL")
        #expect(byName["address.street"] == "TEXT")
        // the composite itself is not a column
        #expect(byName["location"] == nil)
        #expect(byName["address"] == nil)
    }

    // MARK: - Round trip

    @Test func compositeRoundTrip() async throws {
        let database = try Self.makeDatabase()
        let facility = Self.facility(id: "north", name: "North", latitude: 40.7, longitude: -74.0)
        try await database.insert(facility)
        let fetched = try #require(try await database.fetch("Facility", for: "north"))
        #expect(fetched.attributes["location"] == .composite([
            "latitude": .double(40.7),
            "longitude": .double(-74.0)
        ]))
        #expect(fetched.attributes["address"] == .composite([
            "street": .string("1 Main"),
            "location": .composite([
                "latitude": .double(1.5),
                "longitude": .double(2.5)
            ])
        ]))
    }

    @Test func compositeUpdate() async throws {
        let database = try Self.makeDatabase()
        try await database.insert(Self.facility(id: "north", name: "North", latitude: 40.7, longitude: -74.0))
        try await database.insert(Self.facility(id: "north", name: "North", latitude: 1.0, longitude: 2.0, street: "3 Elm"))
        let fetched = try #require(try await database.fetch("Facility", for: "north"))
        #expect(fetched.attributes["location"] == .composite([
            "latitude": .double(1.0),
            "longitude": .double(2.0)
        ]))
        guard case let .composite(address)? = fetched.attributes["address"] else {
            Issue.record("expected composite address")
            return
        }
        #expect(address["street"] == .string("3 Elm"))
    }

    /// An expanded column layout cannot distinguish an absent composite from one whose
    /// elements are all null — the same lossy behavior CoreData has.
    @Test func absentCompositeIsNull() async throws {
        let database = try Self.makeDatabase()
        let bare = ModelData(entity: "Facility", id: "bare", attributes: ["name": .string("Bare")])
        try await database.insert(bare)
        let fetched = try #require(try await database.fetch("Facility", for: "bare"))
        #expect(fetched.attributes["location"] == .null)
        #expect(fetched.attributes["address"] == .null)
    }

    /// A partially specified composite keeps its set elements and nulls the rest.
    @Test func partialComposite() async throws {
        let database = try Self.makeDatabase()
        let partial = ModelData(
            entity: "Facility",
            id: "partial",
            attributes: [
                "name": .string("Partial"),
                "location": .composite(["latitude": .double(40.7)])
            ]
        )
        try await database.insert(partial)
        let fetched = try #require(try await database.fetch("Facility", for: "partial"))
        #expect(fetched.attributes["location"] == .composite([
            "latitude": .double(40.7),
            "longitude": .null
        ]))
    }

    // MARK: - Predicates and sorting

    @Test func elementPredicate() async throws {
        let database = try Self.makeDatabase()
        try await database.insert(Self.facility(id: "north", name: "North", latitude: 40.7, longitude: -74.0))
        try await database.insert(Self.facility(id: "south", name: "South", latitude: 25.8, longitude: -80.2))
        let results = try await database.fetch(FetchRequest(
            entity: "Facility",
            predicate: "location.latitude" > 30
        ))
        #expect(results.map(\.id) == ["north"])
    }

    /// A key path two levels deep is still an ordinary column reference.
    @Test func nestedElementPredicate() async throws {
        let database = try Self.makeDatabase()
        try await database.insert(Self.facility(id: "north", name: "North", latitude: 40.7, longitude: -74.0, innerLatitude: 9.5))
        try await database.insert(Self.facility(id: "south", name: "South", latitude: 25.8, longitude: -80.2, innerLatitude: 1.5))
        let results = try await database.fetch(FetchRequest(
            entity: "Facility",
            predicate: "address.location.latitude" > 5
        ))
        #expect(results.map(\.id) == ["north"])
    }

    @Test func elementSort() async throws {
        let database = try Self.makeDatabase()
        try await database.insert(Self.facility(id: "north", name: "North", latitude: 40.7, longitude: -74.0))
        try await database.insert(Self.facility(id: "south", name: "South", latitude: 25.8, longitude: -80.2))
        let ascending = try await database.fetch(FetchRequest(
            entity: "Facility",
            sortDescriptors: [.init(property: "location.latitude", ascending: true)]
        ))
        #expect(ascending.map(\.id) == ["south", "north"])
        let descending = try await database.fetch(FetchRequest(
            entity: "Facility",
            sortDescriptors: [.init(property: "address.location.latitude", ascending: false)]
        ))
        #expect(descending.count == 2)
    }

    /// A composite has no single column, so comparing one as a whole is rejected rather
    /// than silently mis-compiled.
    @Test func wholeCompositePredicateRejected() async throws {
        let database = try Self.makeDatabase()
        try await database.insert(Self.facility(id: "north", name: "North", latitude: 40.7, longitude: -74.0))
        await #expect(throws: (any Error).self) {
            try await database.fetch(FetchRequest(
                entity: "Facility",
                predicate: "location".compare(.equalTo, .attribute(.composite(["latitude": .double(40.7)])))
            ))
        }
    }
}
