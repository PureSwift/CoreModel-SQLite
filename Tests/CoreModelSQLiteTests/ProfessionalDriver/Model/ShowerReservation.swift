//
//  ShowerReservation.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 8/14/25.
//

import Foundation
import CoreModel

/// ProfessionalDriver Shower Reservation
@Entity
public struct ShowerReservation: Equatable, Hashable, Codable, Sendable, CachedEntity {

    public let id: ID

    @Relationship(destination: Site.self, inverse: .showerReservations)
    public var site: Site.ID

    @Relationship(destination: User.self, inverse: .showerReservations)
    public var user: User.ID?

    @Attribute(.string)
    public var driver: DriverID

    @Attribute(.string)
    public var status: ShowerStatus

    @Attribute
    public var message: String

    @Attribute
    public var pinNumber: String?

    @Attribute
    public var showerNumber: String?

    @Attribute
    public var unlockingEnabled: Bool

    @Attribute(.string)
    public var paymentType: ShowerPaymentMethod

    @Attribute
    public var price: Double

    @Attribute
    public var created: Date

    @Attribute
    public var lastCached: Date

    public enum CodingKeys: String, CodingKey, CaseIterable, Sendable {
        case id
        case site
        case user
        case driver
        case status
        case message
        case pinNumber
        case showerNumber
        case unlockingEnabled
        case paymentType
        case price
        case created
        case lastCached
    }
}

// MARK: - Supporting Types

public extension ShowerReservation {

    struct ID: Codable, Equatable, Hashable, Sendable {

        public let site: Site.ID

        public let transaction: TransactionID

        public init(site: Site.ID, transaction: TransactionID) {
            self.site = site
            self.transaction = transaction
        }
    }
}

// MARK: - RawRepresentable

extension ShowerReservation.ID: RawRepresentable {

    public init?(rawValue: String) {
        // Expected format: "site/<siteID>/shower/<index>"
        let components = rawValue.split(separator: "/", omittingEmptySubsequences: true)
        guard components.count == 4,
            components[0] == "site",
            components[2] == "shower"
        else {
            return nil
        }
        let siteRaw = String(components[1])
        let index = String(components[3])
        guard let siteID = Site.ID.Prefixed(rawValue: siteRaw),
            let transaction = TransactionID(rawValue: index)
        else {
            return nil
        }
        self.init(site: Site.ID(siteID), transaction: transaction)
    }

    public var rawValue: String {
        "site/\(Site.ID.Prefixed(id: site))/shower/\(transaction)"
    }
}

// MARK: - CustomStringConvertible

extension ShowerReservation.ID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

// MARK: - ObjectIDConvertible

extension ShowerReservation.ID: ObjectIDConvertible {

    public init?(objectID: ObjectID) {
        self.init(rawValue: objectID.rawValue)
    }
}
