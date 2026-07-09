//
//  ParkingConstraint.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/2/25.
//

public enum ParkingConstraint: String, Codable, CaseIterable, Sendable {

    case unconstrained = "Unconstrained"
    case fairlyConstrained = "Fairly Constrained"
    case somewhatConstrained = "Somewhat Constrained"
    case mostConstrained = "Most Constrained"
    case notVeryConstrained = "Not very constrained"
}
