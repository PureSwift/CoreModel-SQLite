//
//  Configuration.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 8/14/25.
//

import Foundation
import CoreModel

/// ProfessionalDriver Loyalty User
@Entity
public struct Configuration: Equatable, Hashable, Codable, Identifiable, Sendable {

    public let id: Key

    @Attribute(.string)
    public var value: Value

    public init(id: Key, value: Value) {
        self.id = id
        self.value = value
    }

    public enum CodingKeys: String, CodingKey {
        case id
        case value
    }
}

// MARK: - Supporting Types

public extension Configuration {

    typealias Value = String

    struct Key: RawRepresentable, Equatable, Hashable, Codable, Sendable {

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
}

// MARK: ExpressibleByStringLiteral

extension Configuration.Key: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: CustomStringConvertible

extension Configuration.Key: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

// MARK: ObjectIDConvertible

extension Configuration.Key: ObjectIDConvertible {

    public init?(objectID: ObjectID) {
        self.init(objectID.rawValue)
    }
}

// MARK: Definitions

public extension Configuration.Key {

    static var privacyPolicy: Configuration.Key { "privacypolicy_url" }

    static var faqs: Configuration.Key { "faqs_url" }

    static var termsOfUse: Configuration.Key { "termsofuse_url" }

    static var u1OfficialRules: Configuration.Key { "u1officialrules_url" }

    static var roadSquad: Configuration.Key { "roadsquad_ph" }

    static var customerService: Configuration.Key { "customerservice_ph" }

    static var reserveItParking: Configuration.Key { "reserveitparking_ph" }

    static var aboutRewards: Configuration.Key { "aboutrewards_url" }

    static var showerFilterDistance: Configuration.Key { "showerfilterdistance_int" }
}
