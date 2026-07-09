//
//  CardExpiration.swift
//  CoreModel
//
//  Created by cmiller11 on 10/21/25.
//

import Foundation

/// Credit Card Expiration in the form of `MM/YY`
public struct CardExpiration: Equatable, Hashable, Codable, Sendable {

    public var month: Month

    public var year: Year

    public init(month: Month, year: Year) {
        self.month = month
        self.year = year
    }
}

public extension CardExpiration {

    typealias Month = Date.Month

    typealias Year = UInt
}

extension CardExpiration: RawRepresentable, CustomDateRawRepresentable, CustomStringConvertible {

    public init?(rawValue: String) {
        guard let date = Date.`MM/YY`(rawValue: rawValue) else {
            return nil
        }
        self.init(date)
    }

    public var rawValue: String {
        Date.`MM/YY`(self).rawValue
    }
}

internal extension CardExpiration {

    init(_ date: Date.`MM/YY`) {
        self.init(month: date.month, year: UInt(date.year))
    }
}

internal extension Date.`MM/YY` {

    init(_ date: CardExpiration) {
        precondition(date.year <= 99)
        self.init(month: date.month, year: date.year)!
    }
}

public extension CardExpiration {

    init(_ date: Date.MMYY) {
        self.init(month: date.month, year: UInt(date.year))
    }
}

public extension CardExpiration {

    /// Check if the expiration date is valid (not expired)
    func isValid(for date: Date = Date(), calendar: Calendar = .current) -> Bool {
        let currentMonth = calendar.component(.month, from: date)
        let currentYear = calendar.component(.year, from: date)
        if year > currentYear {
            return true
        } else if year == currentYear {
            return month.rawValue >= currentMonth
        } else {
            return false
        }
    }
}
