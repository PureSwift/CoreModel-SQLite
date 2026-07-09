//
//  AccountID.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller  on 1/4/25.
//

import CoreModel

/// Truck Smart Loyalty Account ID
public struct AccountID: Codable, Equatable, Hashable, Sendable {

    internal let value: UInt64
}

// MARK: - RawRepresentable

extension AccountID: RawRepresentable {

    public init?(rawValue: String) {
        guard let value = UInt64(rawValue) else {
            return nil
        }
        self.value = value
    }

    public var rawValue: String {
        value.description
    }
}

// MARK: - ExpressibleByStringLiteral

extension AccountID: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: UInt64) {
        self.init(value: value)
    }
}

// MARK: - CustomStringConvertible

extension AccountID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

// MARK: - ObjectIDConvertible

extension AccountID: ObjectIDConvertible {

    public init?(objectID: ObjectID) {
        self.init(rawValue: objectID.rawValue)
    }
}
