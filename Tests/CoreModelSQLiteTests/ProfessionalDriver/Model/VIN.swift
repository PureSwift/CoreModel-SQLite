//
//  VIN.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 4/13/26.
//

import Foundation

/// Vehicle Identification Number
public struct VehicleIdentificationNumber: Equatable, Hashable, Codable, Sendable {

    public let rawValue: String

    public init?(rawValue: String) {
        var rawValue = rawValue
        guard Self.isValid(&rawValue) else {
            return nil
        }
        self.rawValue = rawValue
    }
}

internal extension VehicleIdentificationNumber {

    static func isValid(_ vin: inout String) -> Bool {
        vin = vin.uppercased()
        #if canImport(Darwin)
        if #available(iOS 16.0, *) {
            return vin.wholeMatch(of: /^[A-HJ-NPR-Z0-9]{17}$/) != nil
        } else {
            return Self.predicate.evaluate(with: vin)
        }
        #else
        return vin.wholeMatch(of: /^[A-HJ-NPR-Z0-9]{17}$/) != nil
        #endif
    }

    #if canImport(Darwin)
    nonisolated(unsafe) static let predicate = NSPredicate(format: "SELF MATCHES %@", "^[A-HJ-NPR-Z0-9]{17}$")
    #endif
}

// MARK: - CustomStringConvertible

extension VehicleIdentificationNumber: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
