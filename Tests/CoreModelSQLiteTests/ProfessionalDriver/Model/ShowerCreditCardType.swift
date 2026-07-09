//
//  ShowerCreditCardType.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 11/12/25.
//

/// ProfessionalDriver Shower Credit Card Type
public enum ShowerCreditCardType: String, Codable, CaseIterable, Sendable {

    case visa = "VISA"
    case masterCard = "MASTERCARD"
    case discover = "DISCOVER"
    case americanExpress = "AMERICAN EXPRESS"
}
