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
    func sqlFragment(for entity: EntityDescription, model: Model) throws -> SQLFragment {
        switch self {
        case let .value(value):
            return SQLFragment(sql: value ? "1" : "0", bindings: [])
        case let .compound(compound):
            return try compound.sqlFragment(for: entity, model: model)
        case let .comparison(comparison):
            return try comparison.sqlFragment(for: entity, model: model, predicate: self)
        }
    }
}

internal extension FetchRequest.Predicate.Compound {

    func sqlFragment(for entity: EntityDescription, model: Model) throws -> SQLFragment {
        switch self {
        case let .and(subpredicates):
            return try .joined(subpredicates, separator: " AND ", entity: entity, model: model)
        case let .or(subpredicates):
            return try .joined(subpredicates, separator: " OR ", entity: entity, model: model)
        case let .not(subpredicate):
            let fragment = try subpredicate.sqlFragment(for: entity, model: model)
            return SQLFragment(sql: "NOT (" + fragment.sql + ")", bindings: fragment.bindings)
        }
    }
}

private extension SQLFragment {

    static func joined(
        _ predicates: [FetchRequest.Predicate],
        separator: String,
        entity: EntityDescription,
        model: Model
    ) throws -> SQLFragment {
        guard predicates.isEmpty == false else {
            return SQLFragment(sql: "1", bindings: [])
        }
        let fragments = try predicates.map { try $0.sqlFragment(for: entity, model: model) }
        return SQLFragment(
            sql: "(" + fragments.map(\.sql).joined(separator: separator) + ")",
            bindings: fragments.flatMap(\.bindings)
        )
    }
}

internal extension FetchRequest.Predicate.Comparison {

    func sqlFragment(
        for entity: EntityDescription,
        model: Model,
        predicate: FetchRequest.Predicate
    ) throws -> SQLFragment {

        // `function(...) <operator> constant` comparisons compile to a SQL function call.
        if case let .function(function) = left {
            guard modifier == nil else {
                throw SQLiteDatabaseError.invalidPredicate(predicate)
            }
            let functionFragment = try function.sqlFragment(for: entity, predicate: predicate)
            switch type {
            case .lessThan, .lessThanOrEqualTo, .greaterThan, .greaterThanOrEqualTo:
                let value = try right.constantBinding(predicate: predicate)
                return SQLFragment(
                    sql: "\(functionFragment.sql) \(type.rawValue) ?",
                    bindings: functionFragment.bindings + [value]
                )
            case .equalTo, .notEqualTo:
                let value = try right.constantBinding(predicate: predicate)
                let sqlOperator = (type == .equalTo) ? "=" : "<>"
                guard let value else {
                    let nullOperator = (type == .equalTo) ? "IS NULL" : "IS NOT NULL"
                    return SQLFragment(sql: "\(functionFragment.sql) \(nullOperator)", bindings: functionFragment.bindings)
                }
                return SQLFragment(
                    sql: "\(functionFragment.sql) \(sqlOperator) ?",
                    bindings: functionFragment.bindings + [value]
                )
            default:
                throw SQLiteDatabaseError.invalidPredicate(predicate)
            }
        }

        // Only `keyPath <operator> constant` comparisons map directly to columns.
        guard case let .keyPath(keyPath) = left else {
            throw SQLiteDatabaseError.invalidPredicate(predicate)
        }
        let property = PropertyKey(rawValue: keyPath.rawValue)
        // to-many relationships are not columns; translate to a membership subquery
        if let relationship = entity.relationships.first(where: { $0.id == property && $0.type == .toMany }) {
            return try toManySQLFragment(
                relationship,
                entity: entity,
                model: model,
                predicate: predicate
            )
        }
        guard modifier == nil else {
            throw SQLiteDatabaseError.invalidPredicate(predicate)
        }
        let column = try entity.validateColumn(
            property,
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

    /// Translate a comparison against a to-many relationship into a membership subquery.
    ///
    /// Matches CoreData's `ANY <relationship> IN <objects>` / `ANY <relationship> == <object>`
    /// semantics: the row matches if at least one linked destination object is in the given
    /// set. One-to-many relationships resolve through the inverse foreign key on the
    /// destination table; many-to-many through the join table.
    private func toManySQLFragment(
        _ relationship: Relationship,
        entity: EntityDescription,
        model: Model,
        predicate: FetchRequest.Predicate
    ) throws -> SQLFragment {
        // `.any` is the only modifier with a direct SQL translation (`.all` would
        // require set equality); no modifier is treated as `.any`, like NSPredicate.
        guard modifier == nil || modifier == .any else {
            throw SQLiteDatabaseError.invalidPredicate(predicate)
        }
        let destinationIDs: [Binding?]
        switch type {
        case .in:
            destinationIDs = try right.constantBindings(predicate: predicate)
        case .equalTo, .contains:
            destinationIDs = [try right.constantBinding(predicate: predicate)]
        default:
            throw SQLiteDatabaseError.invalidPredicate(predicate)
        }
        guard destinationIDs.isEmpty == false else {
            return SQLFragment(sql: "0", bindings: [])
        }
        let placeholders = repeatElement("?", count: destinationIDs.count).joined(separator: ", ")
        let primaryKey = SQLiteDatabase.primaryKeyColumn.quotedIdentifier
        switch try model.inverseType(of: relationship) {
        case .toOne:
            // one-to-many: the destination table holds the foreign key back to this entity
            let destinationTable = relationship.destinationEntity.rawValue.quotedIdentifier
            let foreignKey = relationship.inverseRelationship.rawValue.quotedIdentifier
            return SQLFragment(
                sql: "\(primaryKey) IN (SELECT \(foreignKey) FROM \(destinationTable) WHERE \(primaryKey) IN (\(placeholders)))",
                bindings: destinationIDs
            )
        case .toMany:
            let joinTable = JoinTable(entity: entity.id, relationship: relationship)
            let table = joinTable.name.quotedIdentifier
            let thisColumn = joinTable.thisColumn.quotedIdentifier
            let otherColumn = joinTable.otherColumn.quotedIdentifier
            var sql = "\(primaryKey) IN (SELECT \(thisColumn) FROM \(table) WHERE \(otherColumn) IN (\(placeholders))"
            var bindings = destinationIDs
            if joinTable.isSymmetric {
                sql += " UNION SELECT \(otherColumn) FROM \(table) WHERE \(thisColumn) IN (\(placeholders))"
                bindings += destinationIDs
            }
            sql += ")"
            return SQLFragment(sql: sql, bindings: bindings)
        }
    }
}

private extension SQLFragment {

    static func like(column: String, pattern: String) -> SQLFragment {
        SQLFragment(sql: "\(column) LIKE ? ESCAPE '\\'", bindings: [pattern])
    }
}

internal extension FetchRequest.Predicate.FunctionExpression {

    /// Translate a function call expression into a SQL function-call fragment,
    /// e.g. `myFunction("lat", "lon", ?, ?)`.
    func sqlFragment(
        for entity: EntityDescription,
        predicate: FetchRequest.Predicate
    ) throws -> SQLFragment {
        let argumentFragments = try arguments.map {
            try $0.argumentSQLFragment(for: entity, predicate: predicate)
        }
        return SQLFragment(
            sql: "\(name)(" + argumentFragments.map(\.sql).joined(separator: ", ") + ")",
            bindings: argumentFragments.flatMap(\.bindings)
        )
    }
}

private extension FetchRequest.Predicate.Expression {

    /// The expression as a SQL fragment suitable for use as a function argument
    /// (a column reference, a constant placeholder, or a nested function call).
    func argumentSQLFragment(
        for entity: EntityDescription,
        predicate: FetchRequest.Predicate
    ) throws -> SQLFragment {
        switch self {
        case let .keyPath(keyPath):
            let column = try entity.validateColumn(PropertyKey(rawValue: keyPath.rawValue), predicate: predicate)
            return SQLFragment(sql: column, bindings: [])
        case let .function(function):
            return try function.sqlFragment(for: entity, predicate: predicate)
        case .attribute, .relationship:
            return SQLFragment(sql: "?", bindings: [try constantBinding(predicate: predicate)])
        }
    }

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
        case .keyPath, .function:
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
