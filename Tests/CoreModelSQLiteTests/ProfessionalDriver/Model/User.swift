//
//  User.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller  on 5/20/25.
//

import Foundation
import CoreModel

/// ProfessionalDriver Loyalty User
@Entity
public struct User: Equatable, Hashable, Codable, Identifiable, Sendable {

    public let id: AccountID

    @Attribute
    public var firstName: String

    @Attribute
    public var lastName: String

    @Attribute(.string)
    public var email: EmailAddress

    @Attribute(.string)
    public var mobilePhone: PhoneNumber

    @Attribute
    public var memberID: String

    @Attribute(.string)
    public var zip: ZipCode?

    @Attribute(.string)
    public var birthday: Birthday?

    @Attribute
    public var address1: String?

    @Attribute
    public var address2: String?

    @Attribute
    public var city: String?

    @Attribute(.string)
    public var state: State?

    @Attribute(.string)
    public var driverType: DriverType?

    @Attribute
    public var optInEmail: Bool

    @Attribute
    public var optInSMS: Bool

    @Attribute
    public var autoEmailReceipt: Bool

    @Attribute
    public var pumpSmartEnabled: Bool

    @Attribute
    public var termsAccepted: Bool

    @Attribute
    public var privacyAccepted: Bool

    @Attribute
    public var thirdPartyAccepted: Bool

    @Relationship(destination: WalletCard.self, inverse: .user)
    public var walletCards: [WalletCard.ID]

    @Relationship(destination: FleetCard.self, inverse: .user)
    public var fleetCards: [FleetCard.ID]

    @Relationship(destination: ParkingReservation.self, inverse: .user)
    public var parkingReservations: [ParkingReservation.ID]

    @Relationship(destination: ShowerReservation.self, inverse: .user)
    public var showerReservations: [ShowerReservation.ID]

    public enum CodingKeys: String, CodingKey, CaseIterable, Sendable {

        case id
        case firstName
        case lastName
        case email
        case mobilePhone
        case memberID
        case zip
        case birthday
        case address1
        case address2
        case city
        case state
        case driverType
        case walletCards
        case fleetCards
        case parkingReservations
        case showerReservations
        case optInEmail
        case optInSMS
        case autoEmailReceipt
        case pumpSmartEnabled
        case termsAccepted
        case privacyAccepted
        case thirdPartyAccepted
    }
}

// MARK: - Supporting Types

public extension User {

    typealias State = TerritorialState
}

public extension User {

    /// ProfessionalDriver Loyalty User Registration
    struct Create: Equatable, Hashable, Codable, Sendable {

        public var firstName: String

        public var lastName: String

        public var zip: ZipCode?

        public var birthday: Birthday?

        public var address1: String?

        public var address2: String?

        public var city: String?

        public var state: User.State?

        public var driverType: DriverType?

        public var optInEmail: Bool

        public var optInSMS: Bool

        public init(
            firstName: String,
            lastName: String,
            zip: ZipCode? = nil,
            birthday: Birthday? = nil,
            address1: String? = nil,
            address2: String? = nil,
            city: String? = nil,
            state: State? = nil,
            driverType: DriverType? = nil,
            optInEmail: Bool = false,
            optInSMS: Bool = false
        ) {
            self.firstName = firstName
            self.lastName = lastName
            self.zip = zip
            self.birthday = birthday
            self.address1 = address1
            self.address2 = address2
            self.city = city
            self.state = state
            self.driverType = driverType
            self.optInEmail = optInEmail
            self.optInSMS = optInSMS
        }
    }
}

public extension User {

    /// User Birthday in the form of MM-dd
    struct Birthday: Equatable, Hashable, Codable, Sendable {

        public var day: Day

        public var month: Month

        public init(
            day: Day = 1,
            month: Month = .january
        ) {
            self.day = day
            self.month = month
        }
    }
}

public extension User.Birthday {

    typealias Month = Date.Month

    typealias Day = Date.Day
}

extension User.Birthday: RawRepresentable, CustomDateRawRepresentable, CustomStringConvertible {

    public init?(rawValue: String) {
        guard let date = Date.MM_DD(rawValue: rawValue) else {
            return nil
        }
        self.init(date)
    }

    public var rawValue: String {
        Date.MM_DD(self).rawValue
    }
}

// MARK: - AttributeCodable

extension User.Birthday: AttributeCodable {}

internal extension User.Birthday {

    init(_ date: Date.MM_DD) {
        self.init(day: date.day, month: date.month)
    }
}

internal extension Date.MM_DD {

    init(_ date: User.Birthday) {
        self.init(day: date.day, month: date.month)
    }
}
