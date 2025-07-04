//
//  Database.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/4/25.
//

import CoreModel
import SQLite

public actor SQLiteDatabase {
    
    public let model: Model
    
    let connection: Connection
    
    internal private(set) var didCreateTables = false
    
    public init(connection: Connection, model: Model) {
        self.connection = connection
        self.model = model
    }
}

extension SQLiteDatabase: ModelStorage {
    
    /// Fetch managed object.
    public func fetch(_ entity: EntityName, for id: ObjectID) async throws -> ModelData? {
        try createTables()
        
    }
    
    /// Fetch managed objects.
    public func fetch(_ fetchRequest: FetchRequest) async throws -> [ModelData] {
        try createTables()
    }
    
    /// Fetch managed objects IDs.
    public func fetchID(_ fetchRequest: FetchRequest) async throws -> [ObjectID] {
        try createTables()
    }
    
    /// Fetch and return result count.
    public func count(_ fetchRequest: FetchRequest) async throws -> UInt {
        try createTables()
    }
    
    /// Create or edit a managed object.
    public func insert(_ value: ModelData) async throws {
        try createTables()
    }
    
    /// Create or edit multiple managed objects.
    public func insert(_ values: [ModelData]) async throws {
        try createTables()
    }
    
    /// Delete the specified managed object.
    public func delete(_ entity: EntityName, for id: ObjectID) async throws {
        try createTables()
    }
}

internal extension SQLiteDatabase {
    
    func createTables() throws {
        guard didCreateTables == false else { return }
        let schemaChanger = SchemaChanger(connection: connection)
        try schemaChanger.create(model: model, ifNotExists: true)
    }
    
    func model(for entityName: EntityName) throws -> EntityDescription {
        guard let entity = self.model.entities.first(where: { $0.id == entityName }) else {
            throw CoreModelError.invalidEntity(entityName)
        }
        return entity
    }
}
