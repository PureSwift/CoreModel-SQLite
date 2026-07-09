//
//  ServiceOption.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/7/25.
//

import Foundation
import CoreModel

/// Service Option
public extension Site {

    enum Facility: String, CaseIterable, Codable, Sendable {

        case store = "Store"
        case fuel = "Fuel"
        case gas = "Gas"
        case shop = "Shop"
        case quickServiceRestaurant = "QSR"
        case fullServiceRestaurant = "Restaurant"
        case wireless = "Wireless"
        case casino = "Casino"
        case motel = "Motel"
    }
}

extension Site.Facility: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

extension Site.Facility: AttributeCodable {}
