//
//  AmenityType.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/3/25.
//

import CoreModel

/// ProfessionalDriver Amenity Type
public enum AmenityType: String, Codable, CaseIterable, Sendable {

    /// Amenity
    case amenity

    /// Fast Food
    case fastFood = "fast-food"

    /// Restaurant
    case restaurant

    /// Grab and Go
    case grabGo = "grab-go"

    /// Fitness
    case fitness

    /// Clinic
    case clinic
}

// MARK: - AttributeCodable

extension AmenityType: AttributeCodable {}
