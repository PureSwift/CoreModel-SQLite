//
//  Attribute.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import CoreModel
import SQLite

extension ColumnDefinition {
    
    /// - Note: A composite attribute has no single column; use ``init(column:isOptional:)``
    /// with each of its expanded ``AttributeColumn`` values instead.
    init(
        attribute: Attribute,
        isOptional: Bool = true
    ) {
        assert(attribute.type.isComposite == false, "Composite attributes are expanded into leaf columns")
        self.init(
            name: attribute.id.rawValue,
            primaryKey: nil,
            type: .init(attributeType: attribute.type),
            nullable: isOptional,
            unique: false,
            defaultValue: .NULL,
            references: nil
        )
    }

    /// A column contributed by an attribute, which for a composite is one of its leaves.
    init(
        column: AttributeColumn,
        isOptional: Bool = true
    ) {
        self.init(
            name: column.name,
            primaryKey: nil,
            type: .init(attributeType: column.type),
            nullable: isOptional,
            unique: false,
            defaultValue: .NULL,
            references: nil
        )
    }
}
