//
//  Relationship.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import CoreModel
import SQLite

extension ColumnDefinition {

    /// Foreign key column for a to-one relationship.
    ///
    /// To-many relationships are not stored as columns: one-to-many is derived
    /// from the inverse foreign key on the destination table, and many-to-many
    /// uses a ``JoinTable``.
    init(relationship: Relationship) {
        assert(relationship.type == .toOne)
        self.init(
            name: relationship.id.rawValue,
            primaryKey: nil,
            type: .TEXT,
            nullable: true,
            unique: false,
            defaultValue: .NULL,
            references: .init(
                fromColumn: relationship.id.rawValue, // local column
                toTable: relationship.destinationEntity.rawValue, // destination table
                toColumn: SQLiteDatabase.primaryKeyColumn // destination table primary key
            )
        )
    }
}

internal extension Model {

    func entity(_ name: EntityName) throws -> EntityDescription {
        guard let entity = entities.first(where: { $0.id == name }) else {
            throw CoreModelError.invalidEntity(name)
        }
        return entity
    }

    /// The declared type of the inverse relationship on the destination entity.
    func inverseType(of relationship: Relationship) throws -> RelationshipType {
        let destination = try entity(relationship.destinationEntity)
        guard let inverse = destination.relationships.first(where: { $0.id == relationship.inverseRelationship }) else {
            throw CoreModelError.invalidEntity(relationship.destinationEntity)
        }
        return inverse.type
    }
}

/// Join table for a many-to-many relationship.
///
/// Both sides of the relationship resolve to the same table via a canonical
/// name derived from the sorted `Entity.relationship` pairs, so the table is
/// only created once and each stored row `(left, right)` represents one link.
internal struct JoinTable {

    /// Canonical table name.
    let name: String

    /// Column holding the object ID of this relationship's source entity.
    let thisColumn: String

    /// Column holding the object ID of the destination entity.
    let otherColumn: String

    /// Whether the relationship is its own inverse (symmetric self-relationship).
    let isSymmetric: Bool

    init(entity: EntityName, relationship: Relationship) {
        assert(relationship.type == .toMany)
        let thisSide = "\(entity.rawValue).\(relationship.id.rawValue)"
        let otherSide = "\(relationship.destinationEntity.rawValue).\(relationship.inverseRelationship.rawValue)"
        let isSymmetric = thisSide == otherSide
        let left = min(thisSide, otherSide)
        let right = isSymmetric ? otherSide + "#inverse" : max(thisSide, otherSide)
        self.name = left + "—" + right
        self.isSymmetric = isSymmetric
        if thisSide == left {
            self.thisColumn = left
            self.otherColumn = right
        } else {
            self.thisColumn = right
            self.otherColumn = left
        }
    }
}

internal extension JoinTable {

    func create(connection: Connection) throws {
        let sql = """
        CREATE TABLE IF NOT EXISTS \(name.quotedIdentifier) (
        \(thisColumn.quotedIdentifier) TEXT NOT NULL,
        \(otherColumn.quotedIdentifier) TEXT NOT NULL,
        PRIMARY KEY (\(thisColumn.quotedIdentifier), \(otherColumn.quotedIdentifier))
        )
        """
        try connection.run(sql)
    }

    /// Fetch the object IDs linked to the specified object.
    func fetch(_ id: ObjectID, connection: Connection) throws -> [ObjectID] {
        var sql = "SELECT \(otherColumn.quotedIdentifier) FROM \(name.quotedIdentifier) WHERE \(thisColumn.quotedIdentifier) = ?"
        var bindings: [Binding?] = [id.rawValue]
        if isSymmetric {
            sql += " UNION SELECT \(thisColumn.quotedIdentifier) FROM \(name.quotedIdentifier) WHERE \(otherColumn.quotedIdentifier) = ?"
            bindings.append(id.rawValue)
        }
        let statement = try connection.prepare(sql, bindings)
        var results = [ObjectID]()
        while let row = try statement.failableNext() {
            guard let value = row[0] as? String else { continue }
            results.append(ObjectID(rawValue: value))
        }
        return results
    }

    /// Replace all links of the specified object with the provided destination IDs.
    func replace(_ id: ObjectID, with destinationIDs: [ObjectID], connection: Connection) throws {
        try removeAll(id, connection: connection)
        let sql = "INSERT OR IGNORE INTO \(name.quotedIdentifier) (\(thisColumn.quotedIdentifier), \(otherColumn.quotedIdentifier)) VALUES (?, ?)"
        for destination in destinationIDs {
            try connection.run(sql, [id.rawValue, destination.rawValue])
        }
    }

    /// Remove all links involving the specified object.
    func removeAll(_ id: ObjectID, connection: Connection) throws {
        var sql = "DELETE FROM \(name.quotedIdentifier) WHERE \(thisColumn.quotedIdentifier) = ?"
        var bindings: [Binding?] = [id.rawValue]
        if isSymmetric {
            sql += " OR \(otherColumn.quotedIdentifier) = ?"
            bindings.append(id.rawValue)
        }
        try connection.run(sql, bindings)
    }
}
