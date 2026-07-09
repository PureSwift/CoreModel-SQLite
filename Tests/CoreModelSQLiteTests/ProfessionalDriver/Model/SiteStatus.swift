//
//  SiteStatus.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/2/25.
//

public extension Site {

    /// Site Status
    enum Status: String, Codable, CaseIterable, Sendable {

        case open = "Open"
        case closed = "Closed"
        case sold = "Sold"
        case converted = "Converted"
        case new = "New"
        case agreementCancelled = "Agreement Cancelled"
        case deBranded = "De-Branded"
    }
}
