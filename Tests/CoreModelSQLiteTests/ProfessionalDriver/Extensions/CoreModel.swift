//
//  CoreModel.swift
//
//
//  Created by Alsey Coleman Miller on 8/29/23.
//

import Foundation
import CoreModel

public extension Model {

    static var professionalDriver: Model {
        Model(
            entities:
                Site.self,
            Amenity.self,
            Amenity.Schedule.self,
            FuelProduct.self,
            FuelOption.self,
            User.self,
            Configuration.self,
            ParkingReservation.self,
            ShowerReservation.self,
            WalletCard.self,
            FleetCard.self,
            EngineManufacturer.self,
            TruckManufacturer.self
        )
    }
}

internal extension CodingKey {

    func contains(
        _ text: String,
        options: Set<FetchRequest.Predicate.Comparison.Option> = [.caseInsensitive, .localeSensitive]
    ) -> CoreModel.FetchRequest.Predicate {
        guard text.isEmpty == false else {
            return .value(true)
        }
        return self.stringValue.compare(.contains, options, .attribute(.string(text)))
    }

    func equalTo(
        _ text: String,
        options: Set<FetchRequest.Predicate.Comparison.Option> = [.caseInsensitive, .localeSensitive]
    ) -> CoreModel.FetchRequest.Predicate {
        guard text.isEmpty == false else {
            return .value(true)
        }
        return self.stringValue.compare(.equalTo, options, .attribute(.string(text)))
    }
}

public extension FetchRequest.Predicate {

    enum StringOperator: Equatable, Hashable, Sendable {

        case equalTo
        case contains
    }
}

public extension FetchRequest.Predicate {

    enum NumberOperator: Equatable, Hashable, Sendable {

        case equalTo
        case lessThan
        case lessThanOrEqualTo
        case greaterThan
        case greaterThanOrEqualTo
    }
}

public extension FetchRequest.Predicate.Comparison.Operator {

    init(_ numberOperator: FetchRequest.Predicate.NumberOperator) {
        switch numberOperator {
        case .equalTo:
            self = .equalTo
        case .greaterThan:
            self = .greaterThan
        case .lessThan:
            self = .lessThan
        case .greaterThanOrEqualTo:
            self = .greaterThanOrEqualTo
        case .lessThanOrEqualTo:
            self = .lessThanOrEqualTo
        }
    }
}
