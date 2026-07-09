//
//  MemberGUID.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller  on 5/6/25.
//

/// Member GUID
public struct MemberGUID: RawRepresentable, Codable, Equatable, Hashable, Sendable {

    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.isEmpty == false else {
            return nil
        }
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension MemberGUID: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        guard let value = MemberGUID(rawValue: value) else {
            fatalError("Invalid raw value for \(MemberGUID.self): \(value)")
        }
        self = value
    }
}

// MARK: - CustomStringConvertible

extension MemberGUID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
