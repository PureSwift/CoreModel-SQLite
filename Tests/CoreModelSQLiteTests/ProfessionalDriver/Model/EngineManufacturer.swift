//
//  EngineManufacturer.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/29/25.
//

import Foundation
import CoreModel

/// ProfessionalDriver Engine Manufacturer
@Entity
public struct EngineManufacturer: Equatable, Hashable, Codable, Identifiable, Sendable {

    public let id: ID

    @Attribute
    public var name: String

    public init(
        id: ID,
        name: String
    ) {
        self.id = id
        self.name = name
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}

// MARK: - Supporting Types

public extension EngineManufacturer {

    struct ID: RawRepresentable, Codable, Equatable, Hashable, Sendable {

        public let rawValue: String

        public init?(rawValue: String) {
            guard rawValue.isEmpty == false else {
                return nil
            }
            self.init(rawValue)
        }

        private init(_ raw: String) {
            assert(raw.isEmpty == false)
            self.rawValue = raw
        }
    }
}

// MARK: - CoreModel

extension EngineManufacturer.ID: ObjectIDConvertible {}

// MARK: - ExpressibleByStringLiteral

extension EngineManufacturer.ID: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        guard let value = EngineManufacturer.ID(rawValue: value) else {
            fatalError("Invalid raw value for \(EngineManufacturer.ID.self): \(value)")
        }
        self = value
    }
}

// MARK: - CustomStringConvertible

extension EngineManufacturer.ID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
