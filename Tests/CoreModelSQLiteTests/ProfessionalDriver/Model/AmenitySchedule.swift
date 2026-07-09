//
//  AmenitySchedule.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/3/25.
//

import Foundation
import CoreModel

public extension Amenity {

    typealias Schedule = AmenitySchedule
}

@Entity("AmenitySchedule")
public struct AmenitySchedule: Equatable, Hashable, Codable, Sendable, Identifiable, CachedEntity {

    public let id: ID

    @Relationship(destination: Amenity.self, inverse: .schedules)
    public let amenity: Amenity.ID

    @Relationship(destination: Site.self, inverse: .schedules)
    public let site: Site.ID

    /// Indicates the day of the week.
    @Attribute(.string)
    public let day: Date.Weekday

    @Attribute(.string)
    public var openingTime: Date.Time?

    @Attribute(.string)
    public var closingTime: Date.Time?

    @Attribute
    public var isClosed: Bool

    @Attribute
    public var lastCached: Date

    public init(
        amenity: Amenity.ID,
        site: Site.ID,
        day: Date.Weekday,
        openingTime: Date.Time? = nil,
        closingTime: Date.Time? = nil,
        isClosed: Bool = true,
        lastCached: Date = Date()
    ) {
        self.id = .init(amenity: amenity, site: site, day: day)
        self.amenity = amenity
        self.site = site
        self.day = day
        self.openingTime = openingTime
        self.closingTime = closingTime
        self.isClosed = isClosed
        self.lastCached = lastCached
    }

    // MARK: - CodingKeys

    public enum CodingKeys: String, CodingKey {
        case id
        case site
        case amenity
        case day
        case openingTime
        case closingTime
        case isClosed
        case lastCached
    }
}

// MARK: - Supporting Types

public extension AmenitySchedule {

    /// ProfessionalDriver Amenity Schedule ID
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

public extension AmenitySchedule.ID {

    init(
        amenity: Amenity.ID,
        site: Site.ID,
        day: Date.Weekday
    ) {
        let id =
            Site.ID.Prefixed(id: site).description
            + "/" + amenity.description
            + "/" + day.rawValue.lowercased()
        self.init(id)
    }
}

// MARK: - CoreModel

extension AmenitySchedule.ID: ObjectIDConvertible {}

// MARK: - ExpressibleByStringLiteral

extension AmenitySchedule.ID: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        guard let value = AmenitySchedule.ID(rawValue: value) else {
            fatalError("Invalid raw value for \(AmenitySchedule.ID.self): \(value)")
        }
        self = value
    }
}

// MARK: - CustomStringConvertible

extension AmenitySchedule.ID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

// MARK: - Filtering

public extension AmenitySchedule {

    enum Query: Equatable, Hashable, Sendable {

        case site(Site.ID)
        case amenity(Amenity.ID)

        case and([Query])
        case or([Query])
    }
}

public extension AmenitySchedule.Query {

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
        case .site(let site):
            return AmenitySchedule.CodingKeys.site.compare(.equalTo, .relationship(.toOne(ObjectID(site))))
        case .amenity(let amenity):
            return AmenitySchedule.CodingKeys.amenity.compare(.equalTo, .relationship(.toOne(ObjectID(amenity))))
        }
    }
}
