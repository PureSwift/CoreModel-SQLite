//
//  Miles.swift
//  CoreModel
//
//  Created by cmiller11 on 4/23/26.
//

// Miles
public struct Miles: DistanceUnit {

    public var rawValue: Double

    public init(rawValue: Double) {
        self.rawValue = rawValue
    }
}

public extension Miles {

    init(meters: Meters) {
        self.init(rawValue: meters.rawValue / 1609.344)
    }

    var meters: Meters {
        .init(rawValue: self.rawValue * 1609.344)
    }
}
