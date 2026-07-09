//
//  ParkingOption.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/7/25.
//

import Foundation
import CoreModel

/// ProfessionalDriver Parking Option
public struct ParkingOption: RawRepresentable, Equatable, Hashable, Codable, Sendable {

    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.isEmpty == false else {
            return nil
        }
        self.rawValue = rawValue
    }

    private init(_ raw: String) {
        assert(raw.isEmpty == false)
        self.rawValue = raw
    }
}

// MARK: - Constants

public extension ParkingOption {

    static var handicapped: ParkingOption { "Handicapped Parking" }

    static var reserveIt: ParkingOption { "Reserve-It Parking" }

    static var gated: ParkingOption { "Gated Parking" }

    static var preferred: ParkingOption { "Preferred Parking" }

    static var paid: ParkingOption { "Paid Parking" }

    static var rv: ParkingOption { "RV Parking" }
}

// MARK: - CustomStringConvertible

extension ParkingOption: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension ParkingOption: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - CoreModel

extension ParkingOption: AttributeCodable {}
