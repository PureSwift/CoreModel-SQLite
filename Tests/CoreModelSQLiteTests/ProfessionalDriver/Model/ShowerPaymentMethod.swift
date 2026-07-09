//
//  ShowerPaymentMethod.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller  on 5/7/25.
//

/// ProfessionalDriver Payment method
public enum ShowerPaymentMethod: Equatable, Hashable, Codable, Sendable {

    case points
    case credits
    case creditCard(ShowerCreditCardType?)
}

public extension ShowerPaymentMethod {

    static var creditCard: ShowerPaymentMethod {
        .creditCard(nil)
    }
}

internal extension ShowerPaymentMethod {

    enum RawString: String, Codable, Sendable, CaseIterable {

        case points = "Points"
        case credits = "Credits"
        case creditCard = "CreditCard"
        case visa = "VISA"
        case masterCard = "MASTERCARD"
        case discover = "DISCOVER"
        case americanExpress = "AMERICAN EXPRESS"
    }
}

// MARK: - RawRepresentable

extension ShowerPaymentMethod: RawRepresentable {

    public init?(rawValue string: String) {
        guard let raw = RawString(rawValue: string) else {
            return nil
        }
        switch raw {
        case .points:
            self = .points
        case .credits:
            self = .credits
        case .creditCard:
            self = .creditCard
        case .visa,
            .masterCard,
            .discover,
            .americanExpress:
            guard let showerCreditCardType = ShowerCreditCardType(rawValue: string) else {
                return nil
            }
            self = .creditCard(showerCreditCardType)
        }
    }

    public var rawValue: String {
        switch self {
        case .points:
            return RawString.points.rawValue
        case .credits:
            return RawString.credits.rawValue
        case .creditCard(let showerCreditCardType):
            return showerCreditCardType?.rawValue ?? RawString.creditCard.rawValue
        }
    }
}
