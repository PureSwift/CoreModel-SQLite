//
//  ParkingReservation.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 8/13/25.
//

import Foundation
import CoreModel

/// ProfessionalDriver Parking Reservation
@Entity
public struct ParkingReservation: Equatable, Hashable, Codable, Identifiable, Sendable, CachedEntity {

    public let id: ID

    @Relationship(destination: Site.self, inverse: .parkingReservations)
    public var site: Site.ID

    @Relationship(destination: User.self, inverse: .parkingReservations)
    public var user: User.ID?

    @Attribute(.string)
    public var deviceID: Device.ID?

    @Attribute
    public var confirmationNumber: String

    @Attribute
    public var created: Date

    @Attribute
    public var start: Date

    @Attribute
    public var end: Date

    @Attribute(.string)
    public var productName: ParkingProductName

    @Attribute(.string)
    public var paymentType: ParkingPaymentType

    @Attribute
    public var totalCost: Double

    @Attribute
    public var firstName: String?

    @Attribute
    public var lastName: String?

    @Attribute(.string)
    public var email: EmailAddress?

    @Attribute(.string)
    public var phone: PhoneNumber?

    @Attribute(.string)
    public var notificationType: ParkingNotificationType

    @Attribute
    public var assetTruckNumber: String

    @Attribute
    public var truckMake: String?

    @Attribute
    public var truckColor: String?

    @Attribute
    public var lastCached: Date

    public init(
        id: ID, confirmationNumber: String, site: Site.ID, user: User.ID? = nil, deviceID: Device.ID? = nil, created: Date, start: Date, end: Date, productName: ParkingProductName,
        paymentType: ParkingPaymentType, totalCost: Double, firstName: String? = nil, lastName: String? = nil, email: EmailAddress? = nil, phone: PhoneNumber? = nil,
        notificationType: ParkingNotificationType, assetTruckNumber: String, truckMake: String? = nil, truckColor: String? = nil, lastCached: Date = Date()
    ) {
        self.id = id
        self.site = site
        self.user = user
        self.deviceID = deviceID
        self.created = created
        self.start = start
        self.end = end
        self.productName = productName
        self.paymentType = paymentType
        self.totalCost = totalCost
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.notificationType = notificationType
        self.assetTruckNumber = assetTruckNumber
        self.truckMake = truckMake
        self.truckColor = truckColor
        self.confirmationNumber = confirmationNumber
        self.lastCached = lastCached
    }

    public enum CodingKeys: CodingKey {
        case id
        case confirmationNumber
        case site
        case user
        case deviceID
        case created
        case start
        case end
        case productName
        case paymentType
        case totalCost
        case firstName
        case lastName
        case email
        case phone
        case notificationType
        case assetTruckNumber
        case truckMake
        case truckColor
        case lastCached
    }
}

// MARK: - Supporting Types

public extension ParkingReservation {

    struct ID: Codable, Equatable, Hashable, Sendable {

        public let site: Site.ID

        public let index: UInt64

        public init(site: Site.ID, index: UInt64) {
            self.site = site
            self.index = index
        }
    }
}

// MARK: - RawRepresentable

extension ParkingReservation.ID: RawRepresentable {

    public init?(rawValue: String) {
        // Expected format: "site/<siteID>/parking/<index>"
        let components = rawValue.split(separator: "/", omittingEmptySubsequences: true)
        guard components.count == 4,
            components[0] == "site",
            components[2] == "parking"
        else {
            return nil
        }
        let siteRaw = String(components[1])
        let indexRaw = String(components[3])
        guard let siteID = Site.ID.Prefixed(rawValue: siteRaw),
            let index = UInt64(indexRaw)
        else {
            return nil
        }
        self.init(site: Site.ID(siteID), index: index)
    }

    public var rawValue: String {
        "site/\(Site.ID.Prefixed(id: site))/parking/\(index)"
    }
}

// MARK: - CustomStringConvertible

extension ParkingReservation.ID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

// MARK: - ObjectIDConvertible

extension ParkingReservation.ID: ObjectIDConvertible {

    public init?(objectID: ObjectID) {
        self.init(rawValue: objectID.rawValue)
    }
}
