//
//  WalletCard.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/21/25.
//

import Foundation
import CoreModel

@Entity
public struct WalletCard: Equatable, Hashable, Identifiable, Codable, CachedEntity {

    public let id: ID

    @Relationship(destination: User.self, inverse: .walletCards)
    public var user: User.ID

    /// A boolean flag indicating whether this payment method is set as the default payment method.
    @Attribute
    public var isDefault: Bool

    @Attribute
    public var cardholderName: String

    /// The last four digits of the payment card.
    @Attribute
    public var lastFour: String

    @Attribute(.int16)
    public var expirationMonth: Date.Month

    @Attribute(.int16)
    public var expirationYear: Int

    /// Creation timestamp
    @Attribute
    public var created: Date

    /// Last modification timestamp
    @Attribute
    public var modified: Date

    /// Last modification timestamp
    @Attribute
    public var lastCached: Date

    public enum CodingKeys: String, CodingKey, CaseIterable, Sendable {
        case id
        case user
        case isDefault
        case cardholderName
        case expirationMonth
        case expirationYear
        case lastFour
        case created
        case modified
        case lastCached
    }
}

// MARK: - Supporting Types

public extension WalletCard {

    /// Wallet Card Unique Identifier
    struct ID: RawRepresentable, Codable, Equatable, Hashable, Sendable {

        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
}

extension WalletCard.ID: ObjectIDConvertible {

    public init?(objectID: ObjectID) {
        guard let value = UInt(objectID.rawValue) else {
            return nil
        }
        self.init(rawValue: value)
    }
}

// MARK: ExpressibleByStringLiteral

extension WalletCard.ID: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: UInt) {
        self.init(rawValue: value)
    }
}

// MARK: CustomStringConvertible

extension WalletCard.ID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue.description
    }

    public var debugDescription: String {
        rawValue.description
    }
}
