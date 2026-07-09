//
//  CachedEntity.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/7/25.
//

import Foundation
import CoreModel

public protocol CachedEntity: Entity {

    var lastCached: Date { get set }
}

public extension ViewContext {

    /// Fetch lat updated value in set.
    func lastCached<T: CachedEntity>(_ type: T.Type) throws -> Date? {
        try fetch(type, sortDescriptors: [.init(property: "lastCached", ascending: false)], fetchLimit: 1).first?.lastCached
    }
}

public extension ModelStorage {

    /// Fetch lat updated value in set.
    func lastCached<T: CachedEntity>(_ type: T.Type) async throws -> Date? {
        try await fetch(type, sortDescriptors: [.init(property: "lastCached", ascending: false)], fetchLimit: 1).first?.lastCached
    }
}
