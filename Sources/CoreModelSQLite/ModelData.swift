//
//  ModelData.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

#if canImport(FoundationEssentials)
import FoundationEssentials
#elseif canImport(Foundation)
import Foundation
#endif
import CoreModel
import SQLite

internal extension ModelData {

    /// Column name and binding pairs for the entity table row, e.g. for `INSERT`.
    ///
    /// Includes the primary key, all attribute columns and to-one relationship
    /// foreign key columns. To-many relationships are not stored on this table.
    func columnValues(for entity: EntityDescription) throws -> [(column: String, binding: Binding?)] {
        assert(entity.id == self.entity)
        var values: [(String, Binding?)] = [(SQLiteDatabase.primaryKeyColumn, id.rawValue.binding)]
        values.reserveCapacity(1 + entity.attributes.count + entity.relationships.count)
        for attribute in entity.attributes {
            let value = attributes[attribute.id] ?? .null
            values.append((attribute.id.rawValue, value.binding))
        }
        for relationship in entity.relationships where relationship.type == .toOne {
            let binding: Binding?
            switch relationships[relationship.id] ?? .null {
            case .null:
                binding = nil
            case let .toOne(objectID):
                binding = objectID.rawValue.binding
            case .toMany:
                throw SQLiteDatabaseError.invalidProperty(relationship.id, entity.id)
            }
            values.append((relationship.id.rawValue, binding))
        }
        return values
    }

    /// Column names explicitly present in `attributes`/to-one `relationships`, as opposed
    /// to columns simply absent from a partial `ModelData`. Used to build an `ON CONFLICT
    /// DO UPDATE` that only overwrites columns the caller actually supplied.
    func providedColumnNames(for entity: EntityDescription) -> Set<String> {
        var names = Set<String>()
        for attribute in entity.attributes where attributes[attribute.id] != nil {
            names.insert(attribute.id.rawValue)
        }
        for relationship in entity.relationships where relationship.type == .toOne && relationships[relationship.id] != nil {
            names.insert(relationship.id.rawValue)
        }
        return names
    }

    /// Decode a row fetched from the entity table.
    ///
    /// Only attributes and to-one relationships are decoded from the row itself;
    /// to-many relationships require separate queries and are filled in by the database.
    init(row: [String: Binding?], entity: EntityDescription) throws {
        guard let idBinding = row[SQLiteDatabase.primaryKeyColumn] ?? nil,
              let idString = idBinding.textValue else {
            throw SQLiteDatabaseError.invalidBinding(row[SQLiteDatabase.primaryKeyColumn] ?? nil, .string)
        }
        var attributes = [PropertyKey: AttributeValue]()
        attributes.reserveCapacity(entity.attributes.count)
        for attribute in entity.attributes {
            let binding = row[attribute.id.rawValue] ?? nil
            attributes[attribute.id] = try AttributeValue(binding: binding, type: attribute.type)
        }
        var relationships = [PropertyKey: RelationshipValue]()
        relationships.reserveCapacity(entity.relationships.count)
        for relationship in entity.relationships where relationship.type == .toOne {
            let binding = row[relationship.id.rawValue] ?? nil
            if let string = binding?.textValue {
                relationships[relationship.id] = .toOne(ObjectID(rawValue: string))
            } else {
                relationships[relationship.id] = .null
            }
        }
        self.init(
            entity: entity.id,
            id: ObjectID(rawValue: idString),
            attributes: attributes,
            relationships: relationships
        )
    }
}

