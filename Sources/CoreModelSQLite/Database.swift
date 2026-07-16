//
//  Database.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import Foundation
import CoreModel
import SQLite

public actor SQLiteDatabase {

    /// Column name used as the primary key on every entity table.
    public static let primaryKeyColumn = "id"

    public let model: Model

    internal let connection: SQLite.Connection

    /// Fetched objects by entity and ID, mirroring CoreData's row cache: a repeated
    /// `fetch(_:for:)` returns the cached value without touching SQLite, skipping both
    /// the row query and the per-relationship queries that derive to-many values.
    /// Predicate fetches also register their results, so ID lookups following a list
    /// fetch are free.
    ///
    /// Writes drop the cached objects of every entity whose stored or derived values
    /// they can change (see `invalidateCache(for:)`). The cache assumes this
    /// actor is the database's only writer — the same coherency contract as separate
    /// CoreData stacks on one store file. `SQLiteViewContext` reads its own connection
    /// directly and always observes committed state.
    internal var cache = [EntityName: [ObjectID: ModelData]]()

    /// Creates the schema eagerly, synchronously, as part of initialization — not lazily
    /// on first use. A `SQLiteViewContext` opens its own read-only connection to the same
    /// file and, being read-only, can never create the schema itself; without this, a
    /// fetch through the view context before any write happens throws "no such table".
    public init(
        connection: SQLite.Connection,
        model: Model
    ) throws {
        self.connection = connection
        self.model = model
        try connection.createTables(model: model)
    }
}

public extension SQLiteDatabase {

    /// Open or create a database file at the specified path.
    init(path: String, model: Model) throws {
        let connection = try Connection(path)
        try self.init(connection: connection, model: model)
    }
}

extension SQLiteDatabase: ModelStorage {

    public func fetch(_ entity: EntityName, for id: ObjectID) async throws -> ModelData? {
        try await asyncYield()
        if let cached = cache[entity]?[id] {
            return cached
        }
        let value = try connection.fetch(entity, for: id, model: model)
        if let value {
            cache[entity, default: [:]][id] = value
        }
        return value
    }

    public func fetch(_ fetchRequest: FetchRequest) async throws -> [ModelData] {
        try await asyncYield()
        let values = try connection.fetch(fetchRequest, model: model)
        // register results so subsequent ID lookups are cache hits
        for value in values {
            cache[fetchRequest.entity, default: [:]][value.id] = value
        }
        return values
    }

    public func fetchID(_ fetchRequest: FetchRequest) async throws -> [ObjectID] {
        try await asyncYield()
        return try connection.fetchID(fetchRequest, model: model)
    }

    public func count(_ fetchRequest: FetchRequest) async throws -> UInt {
        try await asyncYield()
        return try connection.count(fetchRequest, model: model)
    }

    public func insert(_ value: ModelData) async throws {
        try await asyncYield()
        try connection.insert(value, model: model)
        invalidateCache(for: [value.entity])
    }

    public func insert(_ values: [ModelData]) async throws {
        try await asyncYield()
        try connection.insert(values, model: model)
        invalidateCache(for: Set(values.lazy.map { $0.entity }))
    }

    public func delete(_ entity: EntityName, for id: ObjectID) async throws {
        try await asyncYield()
        try connection.delete(entity, for: id, model: model)
        invalidateCache(for: [entity])
    }

    public func delete(_ entity: EntityName, for ids: [ObjectID]) async throws {
        try await asyncYield()
        try connection.delete(entity, for: ids, model: model)
        invalidateCache(for: [entity])
    }

    /// Registers a custom scalar function so it can be invoked from a predicate or sort
    /// descriptor via ``FetchRequest/Predicate/Expression/function(_:)``.
    public func register(function: DatabaseFunction) async throws {
        try connection.register(function: function)
    }
}

public extension SQLiteDatabase {

    /// Execute raw SQL against the underlying connection — e.g. to create and
    /// maintain an R*Tree or other virtual table. CoreModelSQLite does not create,
    /// sync, or otherwise know about any virtual table itself; that is entirely the
    /// caller's responsibility.
    func execute(_ sql: String, _ bindings: [Binding?] = []) throws {
        try connection.run(sql, bindings)
    }
}

internal extension SQLiteDatabase {

    func asyncYield() async throws {
        await Task.yield()
        try Task.checkCancellation()
    }

    /// Drop cached objects of every entity a write to the given entities can affect.
    ///
    /// A write to entity E touches E's own table, the foreign key columns of E's
    /// relationship destinations, and their shared join tables. Derived to-many values
    /// are computed only from those same foreign keys and join tables, so the affected
    /// set is exactly E plus E's destination entities — including E-typed rows other
    /// than the one written (e.g. reassigning a person to a new team also changes the
    /// old team's `members`), which is why whole entity caches are dropped rather than
    /// single objects.
    func invalidateCache(for entities: Set<EntityName>) {
        var affected = entities
        for entity in entities {
            guard let description = model.entities.first(where: { $0.id == entity }) else { continue }
            for relationship in description.relationships {
                affected.insert(relationship.destinationEntity)
            }
        }
        for entity in affected {
            cache[entity] = nil
        }
    }
}

internal extension Connection {
    
    func createTables(model: Model) throws {
        let schemaChanger = SchemaChanger(connection: self)
        try schemaChanger.create(model: model, ifNotExists: true)
        // create join tables for many-to-many relationships
        for entity in model.entities {
            for relationship in entity.relationships where relationship.type == .toMany {
                guard try model.inverseType(of: relationship) == .toMany else { continue }
                let joinTable = JoinTable(entity: entity.id, relationship: relationship)
                try joinTable.create(connection: self)
            }
        }
    }

    func fetch(_ entity: EntityName, for id: ObjectID, model: Model) throws -> ModelData? {
        let entityDescription = try model.entity(entity)
        let sql = "SELECT * FROM \(entity.rawValue.quotedIdentifier) WHERE \(SQLiteDatabase.primaryKeyColumn.quotedIdentifier) = ?"
        let statement = try prepare(sql, [id.rawValue])
        guard let row = try statement.rowDictionaries().first else {
            return nil
        }
        var value = try ModelData(row: row, entity: entityDescription)
        try fetchToManyRelationships(&value, entity: entityDescription, model: model)
        return value
    }

    func fetch(_ fetchRequest: FetchRequest, model: Model) throws -> [ModelData] {
        let entityDescription = try model.entity(fetchRequest.entity)
        let query = try fetchRequest.sqlFragment(for: entityDescription, model: model, columns: "*")
        let statement = try prepare(query.sql, query.bindings)
        var results = [ModelData]()
        for row in try statement.rowDictionaries() {
            var value = try ModelData(row: row, entity: entityDescription)
            try fetchToManyRelationships(&value, entity: entityDescription, model: model)
            results.append(value)
        }
        return results
    }

    func fetchID(_ fetchRequest: FetchRequest, model: Model) throws -> [ObjectID] {
        let entityDescription = try model.entity(fetchRequest.entity)
        let query = try fetchRequest.sqlFragment(
            for: entityDescription,
            model: model,
            columns: SQLiteDatabase.primaryKeyColumn.quotedIdentifier
        )
        let statement = try prepare(query.sql, query.bindings)
        var results = [ObjectID]()
        while let row = try statement.failableNext() {
            guard let value = row[0] as? String else { continue }
            results.append(ObjectID(rawValue: value))
        }
        return results
    }

    func count(_ fetchRequest: FetchRequest, model: Model) throws -> UInt {
        let entityDescription = try model.entity(fetchRequest.entity)
        let query = try fetchRequest.sqlFragment(for: entityDescription, model: model, columns: "COUNT(*)")
        guard let count = try scalar(query.sql, query.bindings) as? Int64 else {
            return 0
        }
        return UInt(count)
    }

    func insert(_ value: ModelData, model: Model) throws {
        try transaction {
            try upsert(value, model: model)
        }
    }

    func insert(_ values: [ModelData], model: Model) throws {
        try transaction {
            for value in values {
                try upsert(value, model: model)
            }
        }
    }

    func delete(_ entity: EntityName, for id: ObjectID, model: Model) throws {
        let entityDescription = try model.entity(entity)
        try transaction {
            // Nullify all references to the deleted row (mirrors CoreData's nullify delete rule).
            for relationship in entityDescription.relationships {
                switch relationship.type {
                case .toMany:
                    switch try model.inverseType(of: relationship) {
                    case .toOne:
                        // one/many-to-many: nullify the foreign key on the destination table
                        let sql = "UPDATE \(relationship.destinationEntity.rawValue.quotedIdentifier) SET \(relationship.inverseRelationship.rawValue.quotedIdentifier) = NULL WHERE \(relationship.inverseRelationship.rawValue.quotedIdentifier) = ?"
                        try run(sql, [id.rawValue])
                    case .toMany:
                        // many-to-many: drop this row's links from the join table
                        let joinTable = JoinTable(entity: entity, relationship: relationship)
                        try joinTable.removeAll(id, connection: self)
                    }
                case .toOne:
                    // only a one-to-one inverse (the other table holding a back-reference) needs explicit nullify
                    if try model.inverseType(of: relationship) == .toOne {
                        let sql = "UPDATE \(relationship.destinationEntity.rawValue.quotedIdentifier) SET \(relationship.inverseRelationship.rawValue.quotedIdentifier) = NULL WHERE \(relationship.inverseRelationship.rawValue.quotedIdentifier) = ?"
                        try run(sql, [id.rawValue])
                    }
                }
            }
            let sql = "DELETE FROM \(entity.rawValue.quotedIdentifier) WHERE \(SQLiteDatabase.primaryKeyColumn.quotedIdentifier) = ?"
            try run(sql, [id.rawValue])
        }
    }

    func delete(_ entity: EntityName, for ids: [ObjectID], model: Model) throws {
        for id in ids {
            try delete(entity, for: id, model: model)
        }
    }

    /// Insert or update the row, then synchronize to-many relationships.
    func upsert(_ value: ModelData, model: Model) throws {
        let entity = try model.entity(value.entity)
        let columnValues = try value.columnValues(for: entity)
        let providedColumns = value.providedColumnNames(for: entity)

        // INSERT ... ON CONFLICT (id) DO UPDATE so edits replace existing rows. The insert
        // side always supplies every column (missing attributes/to-one relationships bind
        // NULL, appropriate for a brand new row); the update side only overwrites columns
        // the caller actually provided, so a partial `ModelData` (e.g. patching a couple of
        // fields) doesn't null out everything it left unmentioned — matching CoreData's
        // `NSManagedObject.setValues(for:)`, which only touches keys present in the value.
        let columns = columnValues.map { $0.column.quotedIdentifier }
        let placeholders = repeatElement("?", count: columns.count).joined(separator: ", ")
        var sql = "INSERT INTO \(value.entity.rawValue.quotedIdentifier) (\(columns.joined(separator: ", "))) VALUES (\(placeholders))"
        let updates = columnValues
            .dropFirst()
            .filter { providedColumns.contains($0.column) }
            .map { "\($0.column.quotedIdentifier) = excluded.\($0.column.quotedIdentifier)" }
        if updates.isEmpty == false {
            sql += " ON CONFLICT (\(SQLiteDatabase.primaryKeyColumn.quotedIdentifier)) DO UPDATE SET " + updates.joined(separator: ", ")
        } else {
            sql += " ON CONFLICT (\(SQLiteDatabase.primaryKeyColumn.quotedIdentifier)) DO NOTHING"
        }
        try run(sql, columnValues.map { $0.binding })

        // synchronize to-many relationships
        for relationship in entity.relationships where relationship.type == .toMany {
            guard let relationshipValue = value.relationships[relationship.id] else {
                continue // not provided, leave existing links untouched
            }
            let destinationIDs: [ObjectID]
            switch relationshipValue {
            case .null:
                destinationIDs = []
            case let .toMany(objectIDs):
                destinationIDs = objectIDs
            case .toOne:
                throw SQLiteDatabaseError.invalidProperty(relationship.id, entity.id)
            }
            switch try model.inverseType(of: relationship) {
            case .toOne:
                // one-to-many: rewrite the foreign key on the destination table
                let table = relationship.destinationEntity.rawValue.quotedIdentifier
                let foreignKey = relationship.inverseRelationship.rawValue.quotedIdentifier
                try run("UPDATE \(table) SET \(foreignKey) = NULL WHERE \(foreignKey) = ?", [value.id.rawValue])
                if destinationIDs.isEmpty == false {
                    let placeholders = repeatElement("?", count: destinationIDs.count).joined(separator: ", ")
                    let bindings: [Binding?] = [value.id.rawValue] + destinationIDs.map { $0.rawValue }
                    try run("UPDATE \(table) SET \(foreignKey) = ? WHERE \(SQLiteDatabase.primaryKeyColumn.quotedIdentifier) IN (\(placeholders))", bindings)
                }
            case .toMany:
                let joinTable = JoinTable(entity: entity.id, relationship: relationship)
                try joinTable.replace(value.id, with: destinationIDs, connection: self)
            }
        }
    }

    /// Fill in to-many relationship values with queries against the inverse.
    func fetchToManyRelationships(_ value: inout ModelData, entity: EntityDescription, model: Model) throws {
        for relationship in entity.relationships where relationship.type == .toMany {
            let destinationIDs: [ObjectID]
            switch try model.inverseType(of: relationship) {
            case .toOne:
                let sql = "SELECT \(SQLiteDatabase.primaryKeyColumn.quotedIdentifier) FROM \(relationship.destinationEntity.rawValue.quotedIdentifier) WHERE \(relationship.inverseRelationship.rawValue.quotedIdentifier) = ?"
                let statement = try prepare(sql, [value.id.rawValue])
                var results = [ObjectID]()
                while let row = try statement.failableNext() {
                    guard let idString = row[0] as? String else { continue }
                    results.append(ObjectID(rawValue: idString))
                }
                destinationIDs = results
            case .toMany:
                let joinTable = JoinTable(entity: entity.id, relationship: relationship)
                destinationIDs = try joinTable.fetch(value.id, connection: self)
            }
            // always report `.toMany`, even when empty — CoreData's equivalent never reports `.null` for a to-many relationship
            value.relationships[relationship.id] = .toMany(destinationIDs)
        }
    }
}

internal extension FetchRequest {

    /// Build the `SELECT` statement for this fetch request.
    func sqlFragment(for entity: EntityDescription, model: Model, columns: String) throws -> SQLFragment {
        var sql = "SELECT \(columns) FROM \(self.entity.rawValue.quotedIdentifier)"
        var bindings = [Binding?]()
        if let predicate {
            let fragment = try predicate.sqlFragment(for: entity, model: model)
            sql += " WHERE " + fragment.sql
            bindings += fragment.bindings
        }
        if sortDescriptors.isEmpty == false {
            let placeholderPredicate = FetchRequest.Predicate.value(true)
            let fragments = try sortDescriptors.map { sort -> SQLFragment in
                switch sort.term {
                case let .property(property):
                    guard entity.hasColumn(for: property) else {
                        throw SQLiteDatabaseError.invalidProperty(property, entity.id)
                    }
                    let sql = property.rawValue.quotedIdentifier + (sort.ascending ? " ASC" : " DESC")
                    return SQLFragment(sql: sql, bindings: [])
                case let .function(function):
                    let functionFragment = try function.sqlFragment(for: entity, predicate: placeholderPredicate)
                    let sql = functionFragment.sql + (sort.ascending ? " ASC" : " DESC")
                    return SQLFragment(sql: sql, bindings: functionFragment.bindings)
                }
            }
            sql += " ORDER BY " + fragments.map(\.sql).joined(separator: ", ")
            bindings += fragments.flatMap(\.bindings)
        } else {
            // match CoreData's default behavior of sorting by object ID when no sort descriptors are provided
            sql += " ORDER BY \(SQLiteDatabase.primaryKeyColumn.quotedIdentifier) ASC"
        }
        if fetchLimit > 0 {
            sql += " LIMIT \(fetchLimit)"
            if fetchOffset > 0 {
                sql += " OFFSET \(fetchOffset)"
            }
        } else if fetchOffset > 0 {
            sql += " LIMIT -1 OFFSET \(fetchOffset)"
        }
        return SQLFragment(sql: sql, bindings: bindings)
    }
}
