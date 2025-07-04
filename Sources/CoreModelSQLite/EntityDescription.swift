//
//  EntityDescription.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import CoreModel
import SQLite

internal extension Table {
    
    init(entity: EntityName, database: String? = nil) {
        self.init(entity.rawValue, database: database)
    }
    
    func create(entity: EntityDescription) -> String {
        create { table in
            // create `id` column
            let id = Expression<String>("id")
            table.column(id, primaryKey: true)
            // create attribute columns
            for attribute in entity.attributes {
                table.column(attribute)
            }
        }
    }
}

internal extension SchemaChanger.CreateTableDefinition {
    
    func addColumns(_ entity: EntityDescription) {
        
        // add ID column
        let id = ColumnDefinition(
            name: "id",
            primaryKey: .init(), type: .TEXT, nullable: false, unique: true, defaultValue: .NULL, references: nil)
        add(column: id)
        
        // add attribute columns
        for attribute in entity.attributes {
            add(column: ColumnDefinition(attribute: attribute))
        }
        
        // add relationship columns
        for relationship in entity.relationships {
            
        }
    }
}

extension ColumnDefinition {
    
    init(relationship: Relationship) {
        
    }
}

internal extension TableBuilder {
    
    func column(_ attribute: Attribute) {
        let id = attribute.id.rawValue
        switch attribute.type {
        case .bool:
            column(Expression<Bool>(id))
        case .int16:
            column(Expression<Int64>(id))
        case .int32:
            column(Expression<Int64>(id))
        case .int64:
            column(Expression<Int64>(id))
        case .float:
            column(Expression<Double>(id))
        case .double:
            column(Expression<Double>(id))
        case .string:
            column(Expression<String>(id))
        case .data:
            column(Expression<Blob>(id))
        case .date:
            column(Expression<String>(id))
        case .uuid:
            column(Expression<Blob>(id))
        case .url:
            column(Expression<String>(id))
        case .decimal:
            column(Expression<Bool>(id))
        }
    }
}
