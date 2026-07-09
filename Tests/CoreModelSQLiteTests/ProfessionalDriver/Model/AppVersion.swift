//
//  AppVersion.swift
//
//
//  Created by Alsey Coleman Miller on 8/20/25.
//

import Foundation

/// App Version
public struct AppVersion: RawRepresentable, Codable, Equatable, Hashable, Sendable {

    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.isEmpty == false else {
            return nil
        }
        self.init(rawValue)
    }

    private init(_ raw: String) {
        assert(raw.isEmpty == false)
        self.rawValue = raw
    }
}

// MARK: - ExpressibleByStringLiteral

extension AppVersion: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - CustomStringConvertible

extension AppVersion: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
