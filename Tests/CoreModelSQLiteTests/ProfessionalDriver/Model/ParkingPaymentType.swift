//
//  PaymentType.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 7/23/25.
//

/// Parking Payment Type
public enum ParkingPaymentType: String, Codable, CaseIterable, Sendable {

    /// UltraOne Points
    case ultraOnePoints = "UltraOnePoints"

    /// UltraCredits
    case ultraCredits = "UltraCredits"

    /// Credit/Debit Card
    case creditCard = "CreditDebitCard"

    /// Cash
    case cash = "Cash"
}
