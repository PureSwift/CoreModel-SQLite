//
//  ViewContext.swift
//  CoreModel-SQLite
//
//  Created by Alsey Coleman Miller on 7/9/26.
//

import Foundation
#if canImport(Combine)
import Combine
#endif
import CoreModel
@preconcurrency import SQLite

@MainActor
public final class SQLiteViewContext: ViewContext {
    
    internal let model: Model
    
    internal let connection: SQLite.Connection
    
    public init(
        _ location: SQLite.Connection.Location,
        model: Model
    ) async throws {
        let connection = try SQLite.Connection.init(location, readonly: true)
        self.model = model
        self.connection = connection
    }
    
    /// Fetch managed object.
    public func fetch(_ entity: EntityName, for id: ObjectID) throws -> ModelData? {
        try connection.fetch(entity, for: id, model: model)
    }
    
    /// Fetch managed objects.
    public func fetch(_ fetchRequest: FetchRequest) throws -> [ModelData] {
        try connection.fetch(fetchRequest, model: model)
    }
    
    /// Fetch managed objects IDs.
    public func fetchID(_ fetchRequest: FetchRequest) throws -> [ObjectID] {
        try connection.fetchID(fetchRequest, model: model)
    }
    
    /// Fetch and return result count.
    public func count(_ fetchRequest: FetchRequest) throws -> UInt {
        try connection.count(fetchRequest, model: model)
    }
}
