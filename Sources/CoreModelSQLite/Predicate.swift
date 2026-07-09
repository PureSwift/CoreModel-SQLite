//
//  Predicate.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import Foundation
import CoreModel
import SQLite

/// A SQL fragment with its positional bindings.
internal struct SQLFragment {

    var sql: String

    var bindings: [Binding?]
}

internal extension FetchRequest.Predicate {

    /// Translate the predicate into a SQL `WHERE` clause fragment.
    func sqlFragment(for entity: EntityDescription) throws -> SQLFragment {
        switch self {
        case let .value(value):
            return SQLFragment(sql: value ? "1" : "0", bindings: [])
        case let .compound(compound):
            return try compound.sqlFragment(for: entity)
        case let .comparison(comparison):
            return try comparison.sqlFragment(for: entity, predicate: self)
        }
    }
}

internal extension FetchRequest.Predicate.Compound {

    func sqlFragment(for entity: EntityDescription) throws -> SQLFragment {
        switch self {
        case let .and(subpredicates):
            return try .joined(subpredicates, separator: " AND ", entity: entity)
        case let .or(subpredicates):
            return try .joined(subpredicates, separator: " OR ", entity: entity)
        case let .not(subpredicate):
            let fragment = try subpredicate.sqlFragment(for: entity)
            return SQLFragment(sql: "NOT (" + fragment.sql + ")", bindings: fragment.bindings)
        }
    }
}

private extension SQLFragment {

    static func joined(
        _ predicates: [FetchRequest.Predicate],
        separator: String,
        entity: EntityDescription
    ) throws -> SQLFragment {
        guard predicates.isEmpty == false else {
            return SQLFragment(sql: "1", bindings: [])
        }
        let fragments = try predicates.map { try $0.sqlFragment(for: entity) }
        return SQLFragment(
            sql: "(" + fragments.map(\.sql).joined(separator: separator) + ")",
            bindings: fragments.flatMap(\.bindings)
        )
    }
}

internal extension FetchRequest.Predicate.Comparison {

    func sqlFragment(
        for entity: EntityDescription,
        predicate: FetchRequest.Predicate
    ) throws -> SQLFragment {

        // Only `keyPath <operator> constant` comparisons map directly to columns.
        guard case let .keyPath(keyPath) = left else {
            throw SQLiteDatabaseError.invalidPredicate(predicate)
        }
        guard modifier == nil else {
            throw SQLiteDatabaseError.invalidPredicate(predicate)
        }
        let column = try entity.validateColumn(
            PropertyKey(rawValue: keyPath.rawValue),
            predicate: predicate
        )

        switch type {
        case .lessThan, .lessThanOrEqualTo, .greaterThan, .greaterThanOrEqualTo:
            let value = try right.constantBinding(predicate: predicate)
            return SQLFragment(sql: "\(column) \(type.rawValue) ?", bindings: [value])
        case .equalTo, .notEqualTo:
            let value = try right.constantBinding(predicate: predicate)
            let sqlOperator = (type == .equalTo) ? "=" : "<>"
            guard let value else {
                let nullOperator = (type == .equalTo) ? "IS NULL" : "IS NOT NULL"
                return SQLFragment(sql: "\(column) \(nullOperator)", bindings: [])
            }
            let collation = options.contains(.caseInsensitive) ? " COLLATE NOCASE" : ""
            return SQLFragment(sql: "\(column) \(sqlOperator) ?\(collation)", bindings: [value])
        case .beginsWith:
            let pattern = try right.likePattern(predicate: predicate)
            return .like(column: column, pattern: pattern + "%")
        case .endsWith:
            let pattern = try right.likePattern(predicate: predicate)
            return .like(column: column, pattern: "%" + pattern)
        case .contains:
            let pattern = try right.likePattern(predicate: predicate)
            return .like(column: column, pattern: "%" + pattern + "%")
        case .like:
            // Translate Cocoa-style wildcards (`*`, `?`) to SQL (`%`, `_`).
            let pattern = try right.likePattern(predicate: predicate)
                .replacingOccurrences(of: "*", with: "%")
                .replacingOccurrences(of: "?", with: "_")
            return .like(column: column, pattern: pattern)
        case .in:
            let values = try right.constantBindings(predicate: predicate)
            guard values.isEmpty == false else {
                return SQLFragment(sql: "0", bindings: [])
            }
            let placeholders = repeatElement("?", count: values.count).joined(separator: ", ")
            return SQLFragment(sql: "\(column) IN (\(placeholders))", bindings: values)
        case .between:
            let values = try right.constantBindings(predicate: predicate)
            guard values.count == 2 else {
                throw SQLiteDatabaseError.invalidPredicate(predicate)
            }
            return SQLFragment(sql: "\(column) BETWEEN ? AND ?", bindings: values)
        case .matches:
            // Regular expressions require a custom SQL function.
            throw SQLiteDatabaseError.invalidPredicate(predicate)
        }
    }
}

private extension SQLFragment {

    static func like(column: String, pattern: String) -> SQLFragment {
        SQLFragment(sql: "\(column) LIKE ? ESCAPE '\\'", bindings: [pattern])
    }
}

private extension FetchRequest.Predicate.Expression {

    /// The expression as a single constant binding.
    func constantBinding(predicate: FetchRequest.Predicate) throws -> Binding? {
        switch self {
        case let .attribute(value):
            return value.binding
        case let .relationship(value):
            switch value {
            case .null:
                return nil
            case let .toOne(objectID):
                return objectID.rawValue
            case .toMany:
                throw SQLiteDatabaseError.invalidPredicate(predicate)
            }
        case .keyPath:
            throw SQLiteDatabaseError.invalidPredicate(predicate)
        }
    }

    /// The expression as a list of constant bindings (for `IN` and `BETWEEN`).
    func constantBindings(predicate: FetchRequest.Predicate) throws -> [Binding?] {
        switch self {
        case let .relationship(.toMany(objectIDs)):
            return objectIDs.map { $0.rawValue }
        default:
            return [try constantBinding(predicate: predicate)]
        }
    }

    /// The expression as a `LIKE` pattern, escaping SQL wildcard characters.
    func likePattern(predicate: FetchRequest.Predicate) throws -> String {
        guard case let .attribute(.string(value)) = self else {
            throw SQLiteDatabaseError.invalidPredicate(predicate)
        }
        return value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }
}

internal extension EntityDescription {

    /// Validate that the key path refers to a column of this entity's table
    /// and return the quoted column name.
    func validateColumn(
        _ property: PropertyKey,
        predicate: FetchRequest.Predicate
    ) throws -> String {
        guard hasColumn(for: property) else {
            throw SQLiteDatabaseError.invalidPredicate(predicate)
        }
        return property.rawValue.quotedIdentifier
    }

    func hasColumn(for property: PropertyKey) -> Bool {
        if property.rawValue == SQLiteDatabase.primaryKeyColumn {
            return true
        }
        if attributes.contains(where: { $0.id == property }) {
            return true
        }
        return relationships.contains(where: { $0.id == property && $0.type == .toOne })
    }
}

internal extension String {

    /// Quote as a SQL identifier.
    var quotedIdentifier: String {
        "\"" + replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
