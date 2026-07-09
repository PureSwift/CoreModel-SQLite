//
//  Site.swift
//
//
//  Created by Alsey Coleman Miller  on 8/23/23.
//

import Foundation
import CoreModel

/// ProfessionalDriver Site (location)
@Entity
public struct Site: Equatable, Hashable, Codable, Identifiable, Sendable, CachedEntity {

    public let id: ID

    @Relationship(destination: Amenity.self, inverse: .sites)
    public var amenities: [Amenity.ID]

    @Relationship(destination: AmenitySchedule.self, inverse: .site)
    public var schedules: [Amenity.Schedule.ID]

    @Relationship(destination: ParkingReservation.self, inverse: .site)
    public var parkingReservations: [ParkingReservation.ID]

    @Relationship(destination: ShowerReservation.self, inverse: .site)
    public var showerReservations: [ShowerReservation.ID]

    @Relationship(destination: FuelProduct.self, inverse: .site)
    public var fuelProducts: [FuelProduct.ID]

    @Relationship(destination: FuelOption.self, inverse: .sites)
    public var fuelOptions: [FuelOption.ID]

    @Attribute(.int64)
    public let location: LocationID?

    @Attribute
    public var name: String

    @Attribute
    public var address: String

    @Attribute
    public var city: String

    @Attribute(.string)
    public var state: State

    @Attribute(.string)
    public var zipCode: ZipCode

    @Attribute(.string)
    public var phone: PhoneNumber

    @Attribute(.string)
    public var fax: PhoneNumber?

    @Attribute
    public var directions: String?

    @Attribute
    public var latitude: Double

    @Attribute
    public var longitude: Double

    @Attribute(.string)
    public var store: StoreVendor

    @Attribute(.string)
    public var gas: GasVendor?

    @Attribute(.int16)
    public var dieselDispenserLanes: Int

    @Attribute
    public var shopPits: Float

    @Attribute(.int16)
    public var shopBays: Int

    @Attribute(.int16)
    public var truckParkingSpaces: Int

    @Attribute(.int16)
    public var carParkingSpaces: Int

    @Attribute(.int16)
    public var privateShowers: Int

    @Attribute(.string)
    public var facilities: List<Facility>

    @Attribute(.string)
    public var serviceOptions: List<String>

    @Attribute(.string)
    public var parkingOptions: List<ParkingOption>

    @Attribute
    public var parking: Bool

    @Attribute
    public var showers: Bool

    @Attribute
    public var truckService: Bool

    @Attribute
    public var truckServiceHours: String?

    @Attribute(.string)
    public var truckServicePhoneNumber: PhoneNumber?

    @Attribute
    public var storeOpen24x7: Bool

    @Attribute
    public var shopOpen24x7: Bool

    @Attribute(.string)
    public var storeOpenTime: Date.Time?

    @Attribute(.string)
    public var storeCloseTime: Date.Time?

    @Attribute
    public var lastCached: Date

    @Attribute
    public var lastViewed: Date?

    public enum CodingKeys: String, CaseIterable, CodingKey {
        case id
        case location
        case amenities
        case schedules
        case fuelProducts
        case fuelOptions
        case parkingReservations
        case showerReservations
        case name
        case address
        case city
        case state
        case zipCode
        case phone
        case fax
        case directions
        case latitude
        case longitude
        case store
        case gas
        case dieselDispenserLanes
        case shopPits
        case shopBays
        case truckParkingSpaces
        case carParkingSpaces
        case privateShowers
        case facilities
        case parkingOptions
        case serviceOptions
        case parking
        case showers
        case truckService
        case truckServiceHours
        case truckServicePhoneNumber
        case storeOpen24x7
        case shopOpen24x7
        case storeOpenTime
        case storeCloseTime
        case lastCached
        case lastViewed
    }
}

public extension Site {

    typealias State = TerritorialState
}

// MARK: - CoreModel

extension Site.ID: ObjectIDConvertible {

    public init?(objectID: CoreModel.ObjectID) {
        guard let rawValue = UInt(objectID.rawValue) else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}

// MARK: - Filtering

public extension Site {

    enum Query: Equatable, Hashable, Sendable {

        case location(LocationID?)
        case name(String, StringOperator = .contains)
        case directions(String, StringOperator = .contains)
        case city(String, StringOperator = .contains)
        case address(String, StringOperator = .contains)
        case zipCode(String)
        case state(Site.State)
        case gas(String?, StringOperator = .equalTo)
        case store(StoreVendor)
        case amenity(Amenity.ID)
        case fuelOption(FuelOption.ID)
        case parking(Bool)
        case showers(Bool)
        case truckService(Bool)
        case lastViewed

        case and([Query])
        case or([Query])
    }
}

public extension Site.Query {

    typealias StringOperator = FetchRequest.Predicate.StringOperator

    typealias NumberOperator = FetchRequest.Predicate.NumberOperator
}

public extension Site.Query {

    static func search(_ text: String) -> Site.Query {
        var queries: [Site.Query] = [
            .name(text, .contains),
            .city(text, .contains),
            .directions(text, .contains),
            .address(text, .contains),
            .zipCode(text)
        ]
        if let state = Site.State(rawValue: text) {
            queries.append(.state(state))
        } else if let name = Site.State.Name(rawValue: text) {
            queries.append(.state(.init(name: name)))
        }
        return .or(queries)
    }

    static func states(_ states: Set<Site.State>) -> Site.Query {
        .or(states.map { .state($0) })
    }

    static func gas(_ gas: GasVendor?) -> Site.Query {
        .gas(gas?.rawValue, .equalTo)
    }

    static func gas(_ gas: Set<GasVendor>) -> Site.Query {
        .or(gas.map { .gas($0) })
    }

    static func store(_ store: Set<StoreVendor>) -> Site.Query {
        .or(store.map { .store($0) })
    }

    static func amenities(_ amenities: Set<Amenity.ID>) -> Site.Query {
        .and(amenities.map { .amenity($0) })
    }

    static func fuelOptions(_ fuelOptions: Set<FuelOption.ID>) -> Site.Query {
        .and(fuelOptions.map { .fuelOption($0) })
    }

    static func search(
        _ text: String? = nil,
        states: Set<Site.State> = []
    ) -> Site.Query? {
        var query = [Site.Query]()
        // filter by search text
        if let searchText = text, searchText.isEmpty == false {
            query.append(.search(searchText))
        }
        // filter by states
        if states.isEmpty == false {
            query.append(.states(states))
        }
        // return all sites if no filters applied
        guard query.isEmpty == false else {
            return nil
        }
        return .and(query)
    }
}

public extension Site.Query {

    var predicate: CoreModel.FetchRequest.Predicate {
        switch self {
        case .and(let queries):
            guard queries.isEmpty == false else {
                return .value(true)
            }
            return .compound(.and(queries.map({ $0.predicate })))
        case .or(let queries):
            guard queries.isEmpty == false else {
                return .value(true)
            }
            return .compound(.or(queries.map({ $0.predicate })))
        case .name(let text, .contains):
            return Site.CodingKeys.name.contains(text)
        case .name(let text, .equalTo):
            return Site.CodingKeys.name.equalTo(text)
        case .directions(let text, .contains):
            return Site.CodingKeys.directions.contains(text)
        case .directions(let text, .equalTo):
            return Site.CodingKeys.directions.equalTo(text)
        case .city(let text, .contains):
            return Site.CodingKeys.city.contains(text)
        case .city(let text, .equalTo):
            return Site.CodingKeys.city.equalTo(text)
        case .state(let state):
            return Site.CodingKeys.state == state.rawValue
        case .location(let location):
            return Site.CodingKeys.location == location?.rawValue
        case .zipCode(let zipCode):
            return Site.CodingKeys.zipCode.contains(zipCode)
        case .address(let address, .contains):
            return Site.CodingKeys.address.contains(address)
        case .address(let address, .equalTo):
            return Site.CodingKeys.address == address
        case .gas(let gasVendor, .equalTo):
            return gasVendor.flatMap { Site.CodingKeys.gas.equalTo($0) } ?? Site.CodingKeys.gas.compare(.equalTo, .attribute(.null))
        case .gas(let gasVendor, .contains):
            return gasVendor.flatMap { Site.CodingKeys.gas.contains($0) } ?? Site.CodingKeys.gas.compare(.equalTo, .attribute(.null))
        case .store(let store):
            return Site.CodingKeys.store == store.rawValue
        case .amenity(let amenity):
            return Site.CodingKeys.amenities.compare(.any, .in, [], .relationship(.toMany([.init(amenity)])))
        case .fuelOption(let fuelOption):
            return Site.CodingKeys.fuelOptions.compare(.any, .in, [], .relationship(.toMany([.init(fuelOption)])))
        case .lastViewed:
            return Site.CodingKeys.lastViewed.compare(.notEqualTo, .attribute(.null))
        case .parking(let service):
            return Site.CodingKeys.parking == service
        case .showers(let service):
            return Site.CodingKeys.showers == service
        case .truckService(let service):
            return Site.CodingKeys.truckService == service
        }
    }
}

public extension ViewContext {

    /// Filter and sort sites by id.
    func fetch(
        _ type: Site.Type,
        text: String?,
        states: Set<Site.State> = [],
    ) throws -> [Site] {
        let predicate = Site.Query.search(
            text,
            states: states
        )?.predicate
        return try self.fetch(type, predicate: predicate)
    }
}

public extension ModelStorage {

    /// Filter and sort sites by id.
    func fetch(
        _ type: Site.Type,
        text: String?,
        states: Set<Site.State> = [],
    ) async throws -> [Site] {
        let predicate = Site.Query.search(
            text,
            states: states
        )?.predicate
        return try await fetch(type, predicate: predicate)
    }

    func didView(
        _ id: Site.ID,
        date: Date = Date()
    ) async throws {
        let modelData = ModelData(
            entity: Site.entityName,
            id: ObjectID(id),
            attributes: [
                PropertyKey(Site.CodingKeys.lastViewed): .date(date)
            ]
        )
        try await insert(modelData)
    }
}
