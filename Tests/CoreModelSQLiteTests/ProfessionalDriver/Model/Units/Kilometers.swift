//
//  Kilometers.swift
//  CoreModel
//
//  Created by cmiller11 on 4/23/26.
//

/// KM Distance
public struct Kilometers: DistanceUnit {

    public var rawValue: Double

    public init(rawValue: Double) {
        self.rawValue = rawValue
    }
}

public extension Kilometers {

    init(meters: Meters) {
        self.init(rawValue: meters.rawValue / 1000)
    }

    var meters: Meters {
        .init(rawValue: self.rawValue * 1000)
    }
}
