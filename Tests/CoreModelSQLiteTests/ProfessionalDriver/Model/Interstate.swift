//
//  Interstate.swift
//
//
//  Created by Alsey Coleman Miller on 8/29/23.
//

import Foundation
import CoreModel

/// Interstate
public struct Interstate: RawRepresentable, Codable, Equatable, Hashable, Sendable {

    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension Interstate: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension Interstate: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

// MARK: - CoreModel

extension Interstate: AttributeCodable {}

extension Array: @retroactive AttributeEncodable where Element == Interstate {

    public var attributeValue: AttributeValue {
        let string = self.reduce("", { $0 + ($0.isEmpty ? "" : ",") + $1.rawValue })
        return .string(string)
    }
}

extension Array: @retroactive AttributeDecodable where Element == Interstate {

    public init?(attributeValue: AttributeValue) {
        guard let string = String(attributeValue: attributeValue) else {
            return nil
        }
        guard string.isEmpty == false else {
            self = []
            return
        }
        let components = string.components(separatedBy: ",")
        self = components.map { Element(rawValue: $0) }
    }
}
