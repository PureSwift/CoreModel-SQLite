//
//  ZipCode.swift
//  CoreModel
//
//  Created by cmiller11 on 2/10/26.
//

import Foundation
#if canImport(RegexBuilder)
import RegexBuilder
#endif

/// Zip Code
public struct ZipCode: RawRepresentable, Codable, Equatable, Hashable, Sendable {

    public let rawValue: String

    public init?(rawValue: String) {
        guard Self.validate(rawValue) else {
            return nil
        }
        self.rawValue = rawValue.uppercased()
    }
}

internal extension ZipCode {

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
        // US Zip Code: 12345 or 12345-6789
        let usZipPattern = Regex {
            Repeat(count: 5) {
                CharacterClass(("0"..."9"))
            }
            Optionally {
                "-"
                Repeat(count: 4) {
                    CharacterClass(("0"..."9"))
                }
            }
        }

        // Canadian Postal Code: A1A 1A1 or A1A1A1
        let canadianPostalPattern = Regex {
            CharacterClass(("A"..."Z"), ("a"..."z"))
            CharacterClass(("0"..."9"))
            CharacterClass(("A"..."Z"), ("a"..."z"))
            Optionally {
                " "
            }
            CharacterClass(("0"..."9"))
            CharacterClass(("A"..."Z"), ("a"..."z"))
            CharacterClass(("0"..."9"))
        }

        return string.wholeMatch(of: usZipPattern) != nil || string.wholeMatch(of: canadianPostalPattern) != nil
    }
    #endif

    #if canImport(Darwin)
    static func validatePredicate<S>(_ string: S) -> Bool where S: StringProtocol, S.SubSequence == Substring {
        // US Zip Code: 12345 or 12345-6789
        let usZipRegex = #"^\d{5}(-\d{4})?$"#
        // Canadian Postal Code: A1A 1A1 or A1A1A1 (case insensitive)
        let canadianPostalRegex = #"^[A-Za-z]\d[A-Za-z] ?\d[A-Za-z]\d$"#

        let usZipPredicate = NSPredicate(format: "SELF MATCHES %@", usZipRegex)
        let canadianPostalPredicate = NSPredicate(format: "SELF MATCHES %@", canadianPostalRegex)

        let stringValue = String(string)
        return usZipPredicate.evaluate(with: stringValue) || canadianPostalPredicate.evaluate(with: stringValue)
    }
    #endif
}

// MARK: - CustomStringConvertible

extension ZipCode: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
