//
//  CompositeAttribute.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 8/16/26.
//

import CoreModel
import SQLite

// MARK: - Column Expansion

/// A scalar column contributed by an attribute.
///
/// A scalar attribute contributes a single column named after it. A composite attribute
/// contributes one column per *leaf* element, at any nesting depth — the same expansion
/// CoreData performs for `NSCompositeAttributeDescription`, so element key paths are
/// ordinary column references rather than JSON extractions.
///
/// Columns are named by their full dotted path (`address.location.latitude`). CoreData
/// instead names them after the leaf alone and disambiguates collisions with a numeric
/// suffix, which obliges it to persist the mapping; a path name is deterministic and
/// needs no bookkeeping. It also means ``PredicateKeyPath`` `rawValue` is already the
/// column name, so predicates and sort terms need no rewriting.
internal struct AttributeColumn: Equatable, Hashable {

    /// The dotted column name, e.g. `address.location.latitude`.
    let name: String

    /// The property path from the entity to this leaf.
    let path: [PropertyKey]

    /// The leaf type. Never ``AttributeType/composite(_:)``.
    let type: AttributeType
}

internal extension Array where Element == PropertyKey {

    /// The dotted column name for a property path.
    var columnName: String {
        reduce("") { $0 + ($0.isEmpty ? "" : ".") + $1.rawValue }
    }
}

internal extension Attribute {

    /// The columns this attribute contributes, expanding composites into their leaves.
    var columns: [AttributeColumn] {
        Attribute.columns(id: id, type: type, parent: [])
    }

    private static func columns(
        id: PropertyKey,
        type: AttributeType,
        parent: [PropertyKey]
    ) -> [AttributeColumn] {
        let path = parent + [id]
        guard case let .composite(elements) = type else {
            return [AttributeColumn(name: path.columnName, path: path, type: type)]
        }
        return elements.flatMap { columns(id: $0.id, type: $0.type, parent: path) }
    }
}

internal extension EntityDescription {

    /// Every scalar attribute column of this entity, with composites expanded.
    var attributeColumns: [AttributeColumn] {
        attributes.flatMap { $0.columns }
    }
}

// MARK: - Value Expansion

internal extension AttributeValue {

    /// The value at a path within this value, descending through composite elements.
    ///
    /// - Returns: `nil` when the path leaves the value, which a caller binds as SQL `NULL`.
    func value(at path: ArraySlice<PropertyKey>) -> AttributeValue? {
        guard let key = path.first else {
            return self
        }
        guard case let .composite(elements) = self, let element = elements[key] else {
            return nil
        }
        return element.value(at: path.dropFirst())
    }

    /// Rebuild an attribute value from a row's expanded columns.
    ///
    /// - Note: A composite whose every leaf is `NULL` decodes as `.null`. An expanded
    /// column layout has nowhere to record the difference between an absent composite and
    /// one whose elements are all null, so the two are indistinguishable — exactly as they
    /// are in CoreData, which stores composites the same way.
    static func decode(attribute: Attribute, row: [String: Binding?]) throws -> AttributeValue {
        try decode(id: attribute.id, type: attribute.type, parent: [], row: row)
    }

    private static func decode(
        id: PropertyKey,
        type: AttributeType,
        parent: [PropertyKey],
        row: [String: Binding?]
    ) throws -> AttributeValue {
        let path = parent + [id]
        guard case let .composite(elements) = type else {
            return try AttributeValue(binding: row[path.columnName] ?? nil, type: type)
        }
        var values = [PropertyKey: AttributeValue](minimumCapacity: elements.count)
        var isEmpty = true
        for element in elements {
            let value = try decode(id: element.id, type: element.type, parent: path, row: row)
            if value != .null {
                isEmpty = false
            }
            values[element.id] = value
        }
        return isEmpty ? .null : .composite(values)
    }
}
