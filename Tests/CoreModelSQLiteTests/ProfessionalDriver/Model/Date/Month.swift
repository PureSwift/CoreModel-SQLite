//
//  Month.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Milleron 10/3/25.
//

import Foundation
import CoreModel

public extension Date {

    /// Represents the months of the Gregorian calendar year.
    enum Month: UInt, Codable, Sendable, CaseIterable {

        /// January (1)
        case january = 1

        /// February (2)
        case february = 2

        /// March (3)
        case march = 3

        /// April (4)
        case april = 4

        /// May (5)
        case may = 5

        /// June (6)
        case june = 6

        /// July (7)
        case july = 7

        /// August (8)
        case august = 8

        /// September (9)
        case september = 9

        /// October (10)
        case october = 10

        /// November (11)
        case november = 11

        /// December (12)
        case december = 12
    }
}

public extension Date.Month {

    var maxDays: Int {
        switch self {
        case .january, .march, .may, .july, .august, .october, .december:
            return 31
        case .april, .june, .september, .november:
            return 30
        case .february:
            return 29  // if birthday allows Feb 29 generally
        }
    }
}

// MARK: - AttributeCodable

extension Date.Month: AttributeCodable {}

// MARK: - CustomStringConvertible

extension Date.Month: CustomStringConvertible {

    public var description: String {
        switch self {
        case .january: return "January"
        case .february: return "February"
        case .march: return "March"
        case .april: return "April"
        case .may: return "May"
        case .june: return "June"
        case .july: return "July"
        case .august: return "August"
        case .september: return "September"
        case .october: return "October"
        case .november: return "November"
        case .december: return "December"
        }
    }
}
