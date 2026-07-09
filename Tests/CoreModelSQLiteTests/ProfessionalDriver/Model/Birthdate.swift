//
//  Birthdate.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller  on 1/13/25.
//

import Foundation

/// Birthdate
public struct Birthdate: Codable, Equatable, Hashable, Sendable {

    public let day: Day

    public let month: Month

    public let year: UInt

    public init?(
        day: Day = 1,
        month: Month = .january,
        year: UInt
    ) {
        guard let date = Date.YYYY_MM_DD(day: day, month: month, year: year) else {
            return nil
        }
        self.init(date)
    }

    internal init(unsafe: (day: Day, month: Month, year: UInt)) {
        assert(unsafe.day.rawValue >= 1 && unsafe.day.rawValue <= 31)
        assert(unsafe.month.rawValue >= 1 && unsafe.month.rawValue <= 12)
        self.day = unsafe.day
        self.month = unsafe.month
        self.year = unsafe.year
    }
}

internal extension Birthdate {

    init(_ date: Date.YYYY_MM_DD) {
        self.init(unsafe: (day: date.day, month: date.month, year: date.year))
    }
}

internal extension Date.YYYY_MM_DD {

    init(_ date: Birthdate) {
        self.init(unsafe: (day: date.day, month: date.month, year: date.year))
    }
}

public extension Birthdate {

    /// Current date
    init() {
        self.init(date: Date())
    }

    /// Jan 1 1900
    static var distantPast: Self {
        .init(unsafe: (day: 1, month: .january, year: 1900))
    }
}

// MARK: - Date Conversion

public extension Birthdate {

    init(date: Date) {
        let value = Self.components(from: date)
        self.init(unsafe: value)
    }

    var date: Date {
        guard let date = Self.date(day: day, month: month, year: year) else {
            fatalError("Invalid date")
        }
        return date
    }
}

internal extension Birthdate {

    static func date(from string: String) -> Date? {
        Date.YYYY_MM_DD.date(from: string)
    }

    static func string(from date: Date) -> String {
        Date.YYYY_MM_DD.string(from: date)
    }

    static func string(day: Day, month: Month, year: UInt) -> String? {
        Date.YYYY_MM_DD.string(day: day, month: month, year: year)
    }

    static func date(day: Day, month: Month, year: UInt) -> Date? {
        Date.YYYY_MM_DD.date(day: day, month: month, year: year)
    }

    static func components(from date: Date) -> (day: Day, month: Month, year: UInt) {
        Date.YYYY_MM_DD.components(from: date)
    }
}

// MARK: - RawRepresentable

extension Birthdate: RawRepresentable, CustomDateRawRepresentable {

    public init?(rawValue: String) {
        guard let date = Date.YYYY_MM_DD(rawValue: rawValue) else {
            return nil
        }
        self.init(date)
    }

    public var rawValue: String {
        Date.YYYY_MM_DD(self).rawValue
    }
}

// MARK: - CustomStringConvertible

extension Birthdate: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

// MARK: - Supporting Types

public extension Birthdate {

    typealias Month = Date.Month

    typealias Day = Date.Day
}

public extension Birthdate {

    struct Legacy: Codable, Equatable, Hashable, Sendable {

        internal let value: Birthdate

        public init(_ date: Birthdate) {
            self.value = date
        }
    }
}

public extension Birthdate {

    init(_ legacy: Birthdate.Legacy) {
        self = legacy.value
    }
}

public extension Birthdate.Legacy {

    init(date: Date) {
        self.init(Birthdate(date: date))
    }

    var date: Date {
        value.date
    }

    var day: UInt {
        value.day.rawValue
    }

    var month: UInt {
        value.month.rawValue
    }

    var year: UInt {
        value.year
    }
}

internal extension Birthdate.Legacy {

    static let dateFormatter = DateFormatter(
        dateFormat: "dd-MMM-yyyy",
        timeZone: .autoupdatingCurrent
    )

    static func date(from string: String) -> Date? {
        Self.dateFormatter.date(from: string)
    }

    static func string(from date: Date) -> String {
        Self.dateFormatter
            .string(from: date)
            .lowercased(with: dateFormatter.locale)
    }

    static func string(day: UInt, month: UInt, year: UInt) -> String? {
        guard let date = date(day: day, month: month, year: year) else {
            return nil
        }
        return string(from: date)
    }

    static func date(day: UInt, month: UInt, year: UInt) -> Date? {
        let components = DateComponents(
            calendar: Self.dateFormatter.calendar,
            timeZone: Self.dateFormatter.timeZone,
            year: Int(year),
            month: Int(month),
            day: Int(day)
        )
        return components.date
    }

    static func components(from date: Date) -> (day: UInt, month: UInt, year: UInt) {
        let day = Self.dateFormatter.calendar.component(.day, from: date)
        let month = Self.dateFormatter.calendar.component(.month, from: date)
        let year = Self.dateFormatter.calendar.component(.year, from: date)
        return (UInt(day), UInt(month), UInt(year))
    }
}

// MARK: RawRepresentable

extension Birthdate.Legacy: RawRepresentable {

    public init?(rawValue: String) {
        guard let date = Self.date(from: rawValue) else {
            return nil
        }
        self.init(date: date)
    }

    public var rawValue: String {
        guard let rawValue = Self.string(day: day, month: month, year: year) else {
            fatalError("Invalid date")
        }
        return rawValue
    }
}

// MARK: CustomStringConvertible

extension Birthdate.Legacy: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
