//
//  ProgramID.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller  on 4/15/25.
//

/// ProfessionalDriver Program ID
public enum ProgramID: String, Codable, CaseIterable, Sendable {

    /// Expediter
    case expediter = "E"

    /// Over the Road
    case overRoad = "U"
}
