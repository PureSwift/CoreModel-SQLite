//
//  ShowerStatus.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 5/6/25.
//

import CoreModel

/// Shower Status
public enum ShowerStatus: String, Codable, CaseIterable, Sendable {

    /// Waiting Assigned
    case waitingAssigned = "WAS"

    /// Shower Assigned
    case assigned = "SAS"

    /// Showering
    case showering = "SHO"

    /// Done
    case complete = "DON"

    /// See Cashier
    case seeCashier = "SEE"
}

// MARK: - AttributeCodable

extension ShowerStatus: AttributeCodable {}
