//
//  TruckManufacturer.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 3/26/26.
//

import Foundation
import CoreModel

/// ProfessionalDriver Truck Manufacturer
@Entity
public struct TruckManufacturer: Equatable, Hashable, Codable, Identifiable, Sendable {

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

public extension TruckManufacturer {

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

extension TruckManufacturer.ID: ObjectIDConvertible {}

// MARK: - ExpressibleByStringLiteral

extension TruckManufacturer.ID: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        guard let value = TruckManufacturer.ID(rawValue: value) else {
            fatalError("Invalid raw value for \(TruckManufacturer.ID.self): \(value)")
        }
        self = value
    }
}

// MARK: - CustomStringConvertible

extension TruckManufacturer.ID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
