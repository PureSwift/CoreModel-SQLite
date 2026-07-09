//
//  PointsRedemption.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller  on 7/1/25.
//

import Foundation

/// Points Redemption
public struct PointsRedemption: Equatable, Hashable, Identifiable, Codable, Sendable {

    public let id: TransactionID

    public let date: String

    public let serial: String

    public let barcode: Barcode

    public init(id: PointsRedemption.ID, date: String, serial: String, barcode: Barcode) {
        self.id = id
        self.date = date
        self.serial = serial
        self.barcode = barcode
    }

    public enum CodingKeys: String, CodingKey {
        case id = "TransactionId"
        case date = "TransactionDate"
        case serial = "SerialId"
        case barcode = "Barcode"
    }
}

// MARK: - Supporting Types

public extension PointsRedemption {

    struct Barcode: Codable, Equatable, Hashable, Sendable {

        internal let value: UInt64
    }
}

extension PointsRedemption.Barcode: RawRepresentable {

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

extension PointsRedemption.Barcode: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: UInt64) {
        self.init(value: value)
    }
}

extension PointsRedemption.Barcode: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
