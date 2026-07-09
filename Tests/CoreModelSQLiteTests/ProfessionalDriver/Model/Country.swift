//
//  Country.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/2/25.
//

/// Country
public enum Country: String, Codable, CaseIterable, Sendable {

    case unitedStates = "US"
    case canada = "CA"
}

public extension Country {

    /// Full name of the country
    enum Name: String, Codable, CaseIterable, Sendable {
        case unitedStates = "United States"
        case canada = "Canada"
    }
}

extension Country.Name: CustomStringConvertible {
    public var description: String { rawValue }
}

public extension Country {
    var name: Name {
        switch self {
        case .unitedStates: return .unitedStates
        case .canada: return .canada
        }
    }
}
