//
//  EmailAddress.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller  on 1/3/25.
//

import Foundation
import CoreModel
#if canImport(RegexBuilder)
import RegexBuilder
#endif

/// Email Address
public struct EmailAddress: RawRepresentable, Codable, Equatable, Hashable, Sendable {

    public let rawValue: String

    public init?(rawValue: String) {
        guard Self.validate(rawValue) else {
            return nil
        }
        self.rawValue = rawValue.lowercased()
    }
}

internal extension EmailAddress {

    static func validate<S>(_ string: S) -> Bool where S: StringProtocol, S.SubSequence == Substring {
        #if canImport(Darwin)
        if #available(iOS 16.0, *) {
            validateRegexBuilder(string)
        } else {
            validatePredicate(string)
        }
        #else
        validateRegexBuilder(string)
        #endif
    }

    #if canImport(RegexBuilder)
    @available(iOS 16.0, *)
    static func validateRegexBuilder<S>(_ string: S) -> Bool where S: StringProtocol, S.SubSequence == Substring {
        let emailPattern = Regex {
            OneOrMore {
                CharacterClass(.anyOf("._%+-"), ("a"..."z"), ("A"..."Z"), ("0"..."9"))
            }
            "@"
            OneOrMore {
                CharacterClass(.anyOf(".-"), ("a"..."z"), ("A"..."Z"), ("0"..."9"))
            }
            "."
            Repeat(2...) { CharacterClass(("a"..."z"), ("A"..."Z")) }
        }
        return string.wholeMatch(of: emailPattern) != nil
    }
    #endif

    #if canImport(Darwin)
    static func validatePredicate<S>(_ string: S) -> Bool where S: StringProtocol, S.SubSequence == Substring {
        let emailRegex = #"^[\w\.-]+@[a-zA-Z\d-]+(?:\.[a-zA-Z\d-]+)*\.[a-zA-Z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: String(string))
    }
    #endif
}

// MARK: - AttributeCodable

extension EmailAddress: AttributeCodable {}

// MARK: - CustomStringConvertible

extension EmailAddress: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
