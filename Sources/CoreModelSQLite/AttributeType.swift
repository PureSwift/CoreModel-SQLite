//
//  AttributeType.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import CoreModel
import SQLite

internal extension ColumnDefinition.Affinity {
    
    init(attributeType: AttributeType) {
        // https://sqlite.org/datatype3.html#determination_of_column_affinity
        switch attributeType {
        case .bool:
            self = .NUMERIC
        case .int16:
            self = .INTEGER
        case .int32:
            self = .INTEGER
        case .int64:
            self = .INTEGER
        case .float:
            self = .REAL
        case .double:
            self = .REAL
        case .string:
            self = .TEXT
        case .data:
            self = .BLOB
        case .date:
            self = .NUMERIC
        case .uuid:
            self = .BLOB
        case .url:
            self = .TEXT
        case .decimal:
            self = .NUMERIC
        }
    }
}
