//
//  Unit.swift
//  CoreModel
//
//  Created by cmiller11 on 4/23/26.
//

/// Distance Unit
public protocol DistanceUnit: RawRepresentable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral {

    init(rawValue: Double)

    var rawValue: Double { get }

    init(meters: Meters)

    var meters: Meters { get }
}

public extension DistanceUnit {

    init<Unit: DistanceUnit>(_ unit: Unit) {
        self.init(meters: unit.meters)
    }
}

// MARK: - ExpressibleByFloatLiteral

extension DistanceUnit {

    public init(floatLiteral value: Double) {
        self.init(rawValue: value)
    }
}

// MARK: - Comparable

extension DistanceUnit {

    public static func > (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue > rhs.rawValue
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
