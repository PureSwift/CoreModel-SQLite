//
//  Attribute.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import CoreModel
import SQLite

extension ColumnDefinition {
    
    init(
        attribute: Attribute,
        isOptional: Bool = true
    ) {
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
}
