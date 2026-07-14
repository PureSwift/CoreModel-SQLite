//
//  ProductName.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 7/23/25.
//

import CoreModel

/// Parking Product Name
public enum ParkingProductName: String, Codable, CaseIterable, Sendable {

    case standard = "Standard"

    case bobtail = "Bobtail"

    case wideLoad = "Wide Load"
}

// MARK: - AttributeCodable

extension ParkingProductName: AttributeCodable {}
