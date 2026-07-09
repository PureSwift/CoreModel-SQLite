//
//  LocationCoordinates.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 7/17/25.
//

/// Location Coordinate
public struct LocationCoordinate: Equatable, Hashable, Codable, Sendable {

    public typealias Degrees = Double  // CLLocationDegrees

    public var latitude: Degrees

    public var longitude: Degrees

    public init(
        latitude: Degrees,
        longitude: Degrees
    ) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Extensions

public extension LocationCoordinate {

    init(site: Site) {
        self.init(
            latitude: site.latitude,
            longitude: site.longitude
        )
    }
}

public extension Site {

    var coordinates: LocationCoordinate {
        .init(site: self)
    }
}
