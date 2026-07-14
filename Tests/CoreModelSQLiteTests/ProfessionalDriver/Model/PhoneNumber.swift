//
//  PhoneNumber.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 1/3/25.
//

import Foundation
import CoreModel

/// Phone Number
public struct PhoneNumber: RawRepresentable, Codable, Equatable, Hashable, Sendable {

    public private(set) var rawValue: String

    public init?(rawValue: String) {
        guard rawValue.isEmpty == false else {
            return nil
        }
        self.rawValue = rawValue
    }
}

internal extension PhoneNumber {

    static func prefix(for countryCode: UInt) -> String {
        "+" + countryCode.description
    }
}

public extension PhoneNumber {

    var url: URL? {
        URL(string: "tel:\(rawValue)")
    }

    /// Whether a phone number contains a specified country code.
    func hasCountryCode(_ countryCode: UInt) -> Bool {
        let prefix = Self.prefix(for: countryCode)
        return rawValue.hasPrefix(prefix)
    }

    /// Remove the specified country code and return the result.
    func removing(countryCode: UInt) -> PhoneNumber {
        var value = self
        _ = value.remove(countryCode: countryCode)
        return value
    }

    /// Remove the specified country code and return whether the code was found.
    @discardableResult
    mutating func remove(countryCode: UInt) -> Bool {
        guard hasCountryCode(countryCode) else {
            return false
        }
        let prefix = Self.prefix(for: countryCode)
        rawValue.removeFirst(prefix.count)
        return true
    }
}

// MARK: - AttributeCodable

extension PhoneNumber: AttributeCodable {}

// MARK: - ExpressibleByStringLiteral

extension PhoneNumber: ExpressibleByStringLiteral {

    public init(stringLiteral string: String) {
        guard let value = PhoneNumber(rawValue: string) else {
            fatalError("Invalid \(PhoneNumber.self) string literal: \(string)")
        }
        self = value
    }
}

// MARK: - CustomStringConvertible

extension PhoneNumber: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
