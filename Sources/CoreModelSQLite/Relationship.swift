//
//  Relationship.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import CoreModel
import SQLite

extension ColumnDefinition {
    
    init(
        relationship: Relationship
    ) {
        switch relationship.type {
        case .toOne:
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
                    toColumn: "id" // destination table primary key
                )
            )
        case .toMany:
            self.init(
                name: relationship.inverseRelationship.rawValue,
                primaryKey: nil,
                type: .TEXT,
                nullable: true,
                unique: false,
                defaultValue: .NULL,
                references: .init(
                    fromColumn: relationship.inverseRelationship.rawValue,
                    toTable: relationship.destinationEntity.rawValue,
                    toColumn: "id"
                )
            )
        }
    }
}
