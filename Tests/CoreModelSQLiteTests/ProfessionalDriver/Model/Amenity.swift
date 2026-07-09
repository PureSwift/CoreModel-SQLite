//
//  Amenity.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 8/29/23.
//

import Foundation
import CoreModel

/// Amenity
@Entity
public struct Amenity: Equatable, Hashable, Codable, Identifiable, Sendable, CachedEntity {

    public let id: ID

    @Attribute
    public var name: String

    @Attribute(.string)
    public var type: AmenityType

    @Attribute
    public var open24x7: Bool?

    @Attribute
    public var website: URL?

    @Attribute
    public var image: URL?

    @Relationship(destination: Site.self, inverse: .amenities)
    public var sites: [Site.ID]

    @Relationship(destination: AmenitySchedule.self, inverse: .amenity)
    public var schedules: [AmenitySchedule.ID]

    @Attribute
    public var lastCached: Date

    public enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case open24x7
        case website
        case image
        case sites
        case schedules
        case lastCached
    }
}

// MARK: - Filtering

public extension Amenity {

    enum Query: Equatable, Hashable, Sendable {

        case site(Site.ID)
        case name(String, StringOperator = .contains)
        case type(AmenityType)

        case and([Query])
        case or([Query])
    }
}

public extension Amenity.Query {

    typealias StringOperator = CoreModel.FetchRequest.Predicate.StringOperator

    typealias NumberOperator = CoreModel.FetchRequest.Predicate.NumberOperator
}

public extension Amenity.Query {

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
            return Amenity.CodingKeys.name.contains(text)
        case .name(let text, .equalTo):
            return Amenity.CodingKeys.name.equalTo(text)
        case .type(let type):
            return Amenity.CodingKeys.type == type.rawValue
        case .site(let site):
            return Amenity.CodingKeys.sites.compare(.contains, .relationship(.toOne(ObjectID(site))))
        }
    }
}
