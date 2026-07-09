//
//  FleetCard.swift
//
//
//  Created by Alsey Coleman Miller on 10/27/23.
//

import Foundation
import CoreModel

/// PumpSmart Fleet Card
@Entity
public struct FleetCard: Equatable, Hashable, Identifiable, Codable, CachedEntity {

    /// The unique identifier for this fleet card.
    public let id: ID

    @Relationship(destination: User.self, inverse: .fleetCards)
    public var user: User.ID

    /// The type or category of the payment method.
    @Attribute(.int16)
    public var paymentType: FleetPaymentType

    /// A description of the payment type, such as "FleetOne".
    @Attribute
    public var paymentTypeDescription: String

    /// A boolean flag indicating whether this payment method is set as the default payment method.
    @Attribute
    public var isDefault: Bool

    /// The last four digits of the payment card.
    @Attribute
    public var lastFour: String

    /// The year of card expiration.
    @Attribute(.int16)
    public var expirationYear: Int

    /// The month of card expiration.
    @Attribute(.int16)
    public var expirationMonth: Date.Month

    /// A user-friendly name or label for this payment method.
    @Attribute
    public var friendlyName: String

    /// Last modification timestamp
    @Attribute
    public var lastCached: Date

    public enum CodingKeys: String, CodingKey, CaseIterable, Sendable {
        case id
        case user
        case paymentType
        case paymentTypeDescription
        case lastFour
        case expirationYear
        case expirationMonth
        case friendlyName
        case isDefault
        case lastCached
    }
}

// MARK: - Supporting Types

public extension FleetCard {

    /// Fleet Card Unique Identifier
    struct ID: RawRepresentable, Codable, Equatable, Hashable, Sendable {

        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
}

extension FleetCard.ID: ObjectIDConvertible {

    public init?(objectID: ObjectID) {
        guard let value = UInt(objectID.rawValue) else {
            return nil
        }
        self.init(rawValue: value)
    }
}

// MARK: ExpressibleByStringLiteral

extension FleetCard.ID: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: UInt) {
        self.init(rawValue: value)
    }
}

// MARK: CustomStringConvertible

extension FleetCard.ID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue.description
    }

    public var debugDescription: String {
        rawValue.description
    }
}
