//
//  DriverType.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller  on 4/15/25.
//

/// ProfessionalDriver Driver Type
public enum DriverType: String, Codable, CaseIterable, Sendable {

    /// Independent
    case independent = "TC"

    /// Owner
    case owner = "TW"

    /// Fleet
    case fleet = "TF"
}

extension DriverType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .independent: return "Independent"
        case .owner: return "Owner"
        case .fleet: return "Fleet"
        }
    }
}
