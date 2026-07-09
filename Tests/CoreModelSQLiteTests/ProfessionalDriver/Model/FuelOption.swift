//
//  FuelingOption.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/3/25.

import Foundation
import CoreModel

/// FuelOption
@Entity
public struct FuelOption: Equatable, Hashable, Codable, Identifiable, Sendable {

    public let id: ID

    @Attribute
    public var name: String

    @Relationship(destination: Site.self, inverse: .fuelOptions)
    public var sites: [Site.ID]

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case sites
    }
}

// MARK: - Supporting Types

public extension FuelOption {

    struct ID: RawRepresentable, Codable, Equatable, Hashable, Sendable {

        public let rawValue: String

        public init?(rawValue: String) {
            guard rawValue.isEmpty == false else {
                return nil
            }
            self.init(rawValue)
        }

        private init(_ raw: String) {
            assert(raw.isEmpty == false)
            self.rawValue = raw
        }
    }
}

public extension FuelOption.ID {

    init?(name: String) {
        let id =
            name
            .lowercased()
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "-")
        self.init(rawValue: id)
    }
}

// MARK: - CoreModel

extension FuelOption.ID: ObjectIDConvertible {}

// MARK: - ExpressibleByStringLiteral

extension FuelOption.ID: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        guard let value = FuelOption.ID(rawValue: value) else {
            fatalError("Invalid raw value for \(FuelOption.ID.self): \(value)")
        }
        self = value
    }
}

// MARK: - CustomStringConvertible

extension FuelOption.ID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

// MARK: - Constants

public extension FuelOption.ID {

    /// Diesel
    static var diesel: FuelOption.ID { "diesel" }
    /// Auto Diesel
    static var autoDiesel: FuelOption.ID { "auto-diesel" }
    /// Biodiesel Blend
    static var biodieselBlend: FuelOption.ID { "biodiesel-blend" }
    /// DEF - 2.5 Gallon Jugs
    static var def25GallonJugs: FuelOption.ID { "def--2.5-gallon-jugs" }
    /// DEF - Bulk Shop Dispenser
    static var defBulkShopDispenser: FuelOption.ID { "def-bulk-shop-dispenser" }
    /// DEF Island Fueling
    static var defIslandFueling: FuelOption.ID { "def-island-fueling" }
    /// Freewire Boost Electric Charging Stations
    static var freewireBoostElectricChargingStations: FuelOption.ID { "freewire-boost-electric-charging-stations" }
    /// Hydrogen
    static var hydrogen: FuelOption.ID { "hydrogen" }
    /// Satellite Pumps
    static var satellitePumps: FuelOption.ID { "satellite-pumps" }
    /// Tesla Charging Stations
    static var teslaChargingStations: FuelOption.ID { "tesla-charging-stations" }
    /// Unleaded Gasoline
    static var unleadedGasoline: FuelOption.ID { "unleaded-gasoline" }
}
