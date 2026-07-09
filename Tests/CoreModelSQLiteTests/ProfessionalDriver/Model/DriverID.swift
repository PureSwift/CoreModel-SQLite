//
//  DriverID.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller  on 5/6/25.
//

/// Driver ID
public struct DriverID: RawRepresentable, Codable, Equatable, Hashable, Sendable {

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

extension DriverID: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(value)
    }
}

// MARK: - CustomStringConvertible

extension DriverID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
