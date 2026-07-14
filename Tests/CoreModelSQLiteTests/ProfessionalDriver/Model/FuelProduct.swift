//
//  FuelProduct.swift
//  ProfessionalDriver
//
//
//  Created by Alsey Coleman Miller on 9/2/23.
//

import Foundation
import CoreModel

/// Fuel Product sold at TA locations.
@Entity
public struct FuelProduct: Codable, Equatable, Hashable, Identifiable, Sendable, CachedEntity {

    public let id: ID

    @Relationship(destination: Site.self, inverse: .fuelProducts)
    public let site: Site.ID

    @Attribute
    public let updated: Date

    @Attribute
    public var price: Double

    @Attribute
    public var descriptionText: String

    @Attribute
    public var lastCached: Date

    public init(
        id: FuelProduct.ID,
        site: Site.ID,
        updated: Date,
        price: Double,
        descriptionText: String,
        lastCached: Date = Date()
    ) {
        self.id = id
        self.site = site
        self.updated = updated
        self.price = price
        self.descriptionText = descriptionText
        self.lastCached = lastCached
    }

    public enum CodingKeys: CodingKey {
        case id
        case site
        case updated
        case price
        case descriptionText
        case lastCached
    }
}

// MARK: - Supporting Types

public extension FuelProduct {

    struct ID: Codable, Equatable, Hashable, Sendable {

        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

extension FuelProduct.ID: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

extension FuelProduct.ID: ObjectIDConvertible {

    public init?(objectID: ObjectID) {
        self.init(rawValue: objectID.rawValue)
    }
}

public extension FuelProduct.ID {

    static func fuelPrice(
        _ id: String,
        site: Site.ID
    ) -> Self {
        .init(rawValue: site.description + "/fuelprice/" + id)
    }
}
