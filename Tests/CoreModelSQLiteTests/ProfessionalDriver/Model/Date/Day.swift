//
//  Day.swift
//  CoreModel
//
//  Created by cmiller11 on 10/3/25.
//

import Foundation

public extension Date {

    struct Day: RawRepresentable, Equatable, Hashable, Codable, Sendable {

        public let rawValue: UInt

        public init?(rawValue: UInt) {
            guard Self.validate(rawValue) else {
                return nil
            }
            self.rawValue = rawValue
        }

        private init(_ unsafe: UInt) {
            assert(Self.validate(unsafe), "Invalid day \(unsafe)")
            self.rawValue = unsafe
        }
    }
}

extension Date.Day: CaseIterable {

    static public var allCases: [Self] {
        (Self.min.rawValue...Self.max.rawValue).map { Self($0) }
    }
}

internal extension Date.Day {

    static func validate(_ rawValue: UInt) -> Bool {
        rawValue >= 1 && rawValue <= 31
    }
}

public extension Date.Day {

    static var min: Self { 1 }

    static var max: Self { 31 }
}

extension Date.Day: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: UInt) {
        self.init(value)
    }
}

extension Date.Day: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue.description
    }

    public var debugDescription: String {
        rawValue.description
    }
}
