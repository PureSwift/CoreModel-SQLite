//
//  Meters.swift
//  CoreModel
//
//  Created by cmiller11 on 4/23/26.
//

/// Meters Distance
public struct Meters: RawRepresentable, Equatable, Hashable, Sendable, Comparable, ExpressibleByFloatLiteral, Codable {

    public var rawValue: Double

    public init(rawValue: Double) {
        self.rawValue = rawValue
    }
}

// MARK: - DistanceUnit

extension Meters: DistanceUnit {

    public init(meters: Meters) {
        self = meters
    }

    public var meters: Meters {
        self
    }
}
