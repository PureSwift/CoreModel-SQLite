//
//  Weekday.swift
//  CoreModel
//
//  Created by cmiller11 on 10/3/25.
//

import Foundation
import CoreModel

public extension Date {

    enum Weekday: String, Codable, Sendable, CaseIterable {

        case sunday

        case monday

        case tuesday

        case wednesday

        case thursday

        case friday

        case saturday
    }
}

// MARK: - AttributeCodable

extension Date.Weekday: AttributeCodable {}

// MARK: - Comparable

extension Date.Weekday: Comparable {

    public var sortOrder: UInt {
        switch self {
        case .sunday:
            return 0
        case .monday:
            return 1
        case .tuesday:
            return 2
        case .wednesday:
            return 3
        case .thursday:
            return 4
        case .friday:
            return 5
        case .saturday:
            return 6
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    public static func > (lhs: Self, rhs: Self) -> Bool {
        lhs.sortOrder > rhs.sortOrder
    }
}

// MARK: - CustomStringConvertible

extension Date.Weekday: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue.description
    }

    public var debugDescription: String {
        rawValue.description
    }
}
