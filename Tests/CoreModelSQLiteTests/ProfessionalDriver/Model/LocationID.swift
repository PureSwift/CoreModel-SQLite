//
//  LocationID.swift
//
//
//  Created by Alsey Coleman Miller on 8/29/23.
//

import Foundation
import CoreModel

/// Location Identifier
public struct LocationID: RawRepresentable, Codable, Equatable, Hashable, Sendable {

    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension LocationID: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: UInt) {
        self.init(rawValue: value)
    }
}

// MARK: - AttributeCodable

extension LocationID: AttributeCodable {}

// MARK: - CustomStringConvertible

extension LocationID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue.description
    }

    public var debugDescription: String {
        rawValue.description
    }
}
