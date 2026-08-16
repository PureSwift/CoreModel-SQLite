//
//  EntityDescription.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import CoreModel
import SQLite

internal extension SchemaChanger {
    
    func create(model: Model, ifNotExists: Bool = true) throws {
        for entity in model.entities {
            try create(entity: entity, ifNotExists: ifNotExists)
        }
    }
    
    func create(entity: EntityDescription, ifNotExists: Bool = true) throws {
        try create(table: entity.id.rawValue, ifNotExists: ifNotExists) { table in
            table.addColumns(entity)
        }
    }
}

internal extension SchemaChanger.CreateTableDefinition {
    
    mutating func addColumns(_ entity: EntityDescription) {
        
        // add ID column
        let id = ColumnDefinition(
            name: SQLiteDatabase.primaryKeyColumn,
            primaryKey: .init(autoIncrement: false), type: .TEXT, nullable: false, unique: true, defaultValue: .NULL, references: nil)
        add(column: id)
        
        // add attribute columns, expanding composite attributes into one column per leaf
        for column in entity.attributeColumns {
            add(column: ColumnDefinition(column: column))
        }
        
        // add to-one relationship columns
        for relationship in entity.relationships where relationship.type == .toOne {
            add(column: ColumnDefinition(relationship: relationship))
        }
    }
}
