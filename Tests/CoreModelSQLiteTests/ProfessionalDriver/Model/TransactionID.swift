//
//  TransactionID.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 2/1/26.
//

/// ProfessionalDriver Transaction ID
public struct TransactionID: RawRepresentable, Codable, Equatable, Hashable, Sendable {

    public let rawValue: String

    public init?(rawValue: String) {
        guard rawValue.isEmpty == false else {
            return nil
        }
        self.rawValue = rawValue
    }
}

// MARK: - ExpressibleByStringLiteral

extension TransactionID: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        guard let value = TransactionID(rawValue: value) else {
            fatalError("Invalid raw value for \(TransactionID.self): \(value)")
        }
        self = value
    }
}

// MARK: - CustomStringConvertible

extension TransactionID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
