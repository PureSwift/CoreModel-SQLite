//
//  FleetPaymentType.swift
//  ProfessionalDriver
//
//  Created on 10/21/25.
//

import Foundation
import CoreModel

/// PumpSmart Fleet Payment Identifier
public struct FleetPaymentType: Equatable, Hashable, Codable, Sendable, RawRepresentable {

    /// The raw payment type ID value
    public let rawValue: UInt

    /// Creates a new FleetPaymentType with the specified raw value
    /// - Parameter rawValue: The payment type ID
    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }
}

// MARK: - AttributeCodable

extension FleetPaymentType: AttributeCodable {}

// MARK: - ExpressibleByIntegerLiteral

extension FleetPaymentType: ExpressibleByIntegerLiteral {

    /// Creates a FleetPaymentType from an integer literal
    /// - Parameter value: The integer literal value
    public init(integerLiteral value: UInt) {
        self.init(rawValue: value)
    }
}

// MARK: - Constants

public extension FleetPaymentType {

    /// Pending payment type - Waiting on response from FIPay
    static var pending: FleetPaymentType { 1 }

    /// ABS Fleet payment type
    static var absFleet: FleetPaymentType { 2 }

    /// Comdata payment type
    static var comdata: FleetPaymentType { 3 }

    /// Comdata Credit payment type
    static var comdataCredit: FleetPaymentType { 4 }

    /// Comdata Mastercard payment type
    static var comdataMastercard: FleetPaymentType { 5 }

    /// EFS Standard payment type
    static var efsStandard: FleetPaymentType { 6 }

    /// EFS Universal payment type
    static var efsUniversal: FleetPaymentType { 7 }

    /// FleetOne payment type
    static var fleetOne: FleetPaymentType { 8 }

    /// Mastercard Fleet payment type (inactive)
    static var mastercardFleet: FleetPaymentType { 9 }

    /// MSTS (MultiService) payment type
    static var msts: FleetPaymentType { 10 }

    /// TCH payment type
    static var tch: FleetPaymentType { 11 }

    /// TCH Mastercard payment type
    static var tchMastercard: FleetPaymentType { 12 }

    /// TChek payment type
    static var tChek: FleetPaymentType { 13 }

    /// US Bank payment type
    static var usBank: FleetPaymentType { 14 }

    /// Visa Fleet payment type (inactive)
    static var visaFleet: FleetPaymentType { 15 }

    /// Voyager Fleet payment type (inactive)
    static var voyagerFleet: FleetPaymentType { 16 }

    /// WEX payment type (inactive)
    static var wex: FleetPaymentType { 17 }

    /// Fuelman payment type (inactive)
    static var fuelman: FleetPaymentType { 18 }

    /// CFN (Commercial Fueling Network) payment type (inactive)
    static var cfn: FleetPaymentType { 19 }

    /// QuikQ payment type
    static var quikQ: FleetPaymentType { 20 }

    /// Ultramar payment type (inactive)
    static var ultramar: FleetPaymentType { 21 }

    /// Compass payment type (inactive)
    static var compass: FleetPaymentType { 22 }
}
