//
//  ImageName.swift
//
//
//  Created by Alsey Coleman Miller  on 8/23/23.
//

import Foundation

/// Downloadable image resource name.
public struct ImageName: RawRepresentable, Codable, Equatable, Hashable, Sendable {

    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.isEmpty == false else {
            return nil
        }
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension ImageName: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(rawValue: value)!
    }
}

// MARK: - CustomStringConvertible

extension ImageName: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
