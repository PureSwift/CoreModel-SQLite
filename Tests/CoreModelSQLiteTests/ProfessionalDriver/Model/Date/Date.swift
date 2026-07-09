//
//  Date.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 5/20/25.
//

import Foundation
import CoreModel

// MARK: - Protocol

public protocol CustomDateComponentsRepresentable {

    /// Date Components
    var dateComponents: DateComponents { get }
}

public protocol CustomFormattedDate {

    /// Format for DateFormatter
    static var format: String { get }

    static func string(from date: Date) -> String

    static func date(from string: String) -> Date?

    init(date: Date)

    var date: Date { get }
}

public extension CustomFormattedDate {

    /// Initialize with current date.
    init() {
        self.init(date: Date())
    }
}

internal protocol CustomFormattedDateInternal: CustomFormattedDate {

    associatedtype DateFormatter: Foundation.Formatter

    /// Cached date formatter
    static var dateFormatter: DateFormatter { get }
}

extension CustomFormattedDateInternal where DateFormatter == Foundation.DateFormatter {

    static var _dateFormatter: DateFormatter {
        DateFormatter(
            dateFormat: format,
            timeZone: .init(secondsFromGMT: 0)!
        )
    }

    static func _string(from date: Date) -> String {
        Self.dateFormatter.string(from: date)
    }

    static func _date(from string: String) -> Date? {
        Self.dateFormatter.date(from: string)
    }
}

public protocol CustomDateRawRepresentable: RawRepresentable where RawValue == String {

    init?(rawValue: String)

    var rawValue: String { get }
}

extension CustomDateRawRepresentable where Self: CustomFormattedDate {

    public init?(rawValue: String) {
        guard let date = Self.date(from: rawValue) else {
            return nil
        }
        self.init(date: date)
    }

    public var rawValue: String {
        Self.string(from: date)
    }
}

extension CustomDateRawRepresentable where Self: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

extension CustomDateRawRepresentable where Self: CustomDebugStringConvertible {

    public var debugDescription: String {
        rawValue
    }
}

// MARK: - MMDDYY

public extension Date {

    /// Unvalidated date represented as "yyyy-DD-mm"
    struct YYYY_MM_DD: Equatable, Hashable, Codable, Sendable {

        public let day: Day

        public let month: Month

        public let year: Year

        public init?(
            day: Day = 1,
            month: Month = .january,
            year: UInt
        ) {
            guard let date = Self.date(day: day, month: month, year: year) else {
                return nil
            }
            self.init(unsafe: (day: day, month: month, year: year))
            assert(self.date == date)
        }

        internal init(unsafe: (day: Day, month: Month, year: UInt)) {
            assert(unsafe.day.rawValue >= 1 && unsafe.day.rawValue <= 31)
            assert(unsafe.month.rawValue >= 1 && unsafe.month.rawValue <= 12)
            self.day = unsafe.day
            self.month = unsafe.month
            self.year = unsafe.year
        }
    }
}

public extension Date.YYYY_MM_DD {

    typealias Day = Date.Day

    typealias Month = Date.Month

    typealias Year = UInt
}

internal extension Date.YYYY_MM_DD {

    static func string(day: Date.Day, month: Date.Month, year: UInt) -> String? {
        guard let date = date(day: day, month: month, year: year) else {
            return nil
        }
        return string(from: date)
    }

    static func date(day: Date.Day, month: Date.Month, year: UInt) -> Date? {
        let components = DateComponents(
            calendar: Self.dateFormatter.calendar,
            timeZone: Self.dateFormatter.timeZone,
            year: Int(year),
            month: Int(month.rawValue),
            day: Int(day.rawValue)
        )
        return components.date
    }

    static func components(from date: Date) -> (day: Day, month: Month, year: UInt) {
        let rawDay = Self.dateFormatter.calendar.component(.day, from: date)
        let rawMonth = Self.dateFormatter.calendar.component(.month, from: date)
        let year = Self.dateFormatter.calendar.component(.year, from: date)
        guard let day = Day(rawValue: UInt(rawDay)) else {
            fatalError("Invalid day \(rawDay)")
        }
        guard let month = Month(rawValue: UInt(rawMonth)) else {
            fatalError("Invalid month \(rawMonth)")
        }
        return (day, month, UInt(year))
    }
}

extension Date.YYYY_MM_DD: CustomStringConvertible, CustomDebugStringConvertible {}

extension Date.YYYY_MM_DD: CustomFormattedDate {

    public static var format: String { "yyyy-MM-dd" }

    public static func string(from date: Date) -> String {
        _string(from: date)
    }

    public static func date(from string: String) -> Date? {
        _date(from: string)
    }

    public init(date: Date) {
        let components = Self.components(from: date)
        self.init(unsafe: (day: components.day, month: components.month, year: components.year))
    }

    public var date: Date {
        guard let date = Self.date(day: day, month: month, year: year) else {
            assertionFailure("Invalid date \(self)")
            return .distantPast
        }
        return date
    }
}

extension Date.YYYY_MM_DD: CustomFormattedDateInternal {

    internal static let dateFormatter = Foundation.DateFormatter(
        dateFormat: format,
        timeZone: .init(secondsFromGMT: 0)!
    )
}

extension Date.YYYY_MM_DD: CustomDateComponentsRepresentable {

    public var dateComponents: DateComponents {
        DateComponents(
            calendar: Self.dateFormatter.calendar,
            timeZone: Self.dateFormatter.timeZone,
            year: Int(year),
            month: Int(month.rawValue),
            day: Int(day.rawValue)
        )
    }
}

extension Date.YYYY_MM_DD: CustomDateRawRepresentable {}

// MARK: - MM/YY

internal extension Date {

    /// Credit card expiration represented as "MM/YY"
    struct `MM/YY`: Equatable, Hashable, Codable, Sendable {

        public let month: Month

        /// Two-digit year (e.g., 25 for 2025)
        public let year: UInt8

        public init?(month: Month, year: UInt) {
            guard year <= 99 else { return nil }
            self.month = month
            self.year = UInt8(year)
        }
    }
}

internal extension Date.`MM/YY` {

    typealias Month = Date.Month
}

extension Date.`MM/YY`: CustomDateRawRepresentable {

    public init?(rawValue: String) {
        // Expecting format MM/YY
        let components = rawValue.split(separator: "/")
        guard components.count == 2,
            let rawMonth = UInt(components[0]),
            let month = Month(rawValue: rawMonth),
            let rawYear = UInt(components[1]), rawYear <= 99
        else {
            return nil
        }
        self.init(month: month, year: rawYear)
    }

    public var rawValue: String {
        // MM/YY format with zero padding
        var monthString = month.rawValue.description
        while monthString.count < 2 { monthString = "0" + monthString }
        var yearString = String(year)
        while yearString.count < 2 { yearString = "0" + yearString }
        return monthString + "/" + yearString
    }
}

extension Date.`MM/YY`: CustomStringConvertible, CustomDebugStringConvertible {}

// MARK: - MMYY

public extension Date {

    /// Date represented as "MMYY" format
    struct MMYY: Equatable, Hashable, Codable, Sendable {

        public let month: Month

        /// Two-digit year (e.g., 25 for 2025)
        public let year: UInt8

        public init?(month: Month, year: UInt) {
            guard year <= 99 else { return nil }
            self.month = month
            self.year = UInt8(year)
        }
    }
}

public extension Date.MMYY {

    typealias Month = Date.Month
}

extension Date.MMYY: CustomDateRawRepresentable {

    public init?(rawValue: String) {
        // Expecting format MMYY (4 characters)
        guard rawValue.count == 4,
            let rawMonth = UInt(String(rawValue.prefix(2))),
            let month = Month(rawValue: rawMonth),
            let rawYear = UInt(String(rawValue.suffix(2))), rawYear <= 99
        else {
            return nil
        }
        self.init(month: month, year: rawYear)
    }

    public var rawValue: String {
        // MMYY format with zero padding
        var monthString = month.rawValue.description
        while monthString.count < 2 { monthString = "0" + monthString }
        var yearString = String(year)
        while yearString.count < 2 { yearString = "0" + yearString }
        return monthString + yearString
    }
}

extension Date.MMYY: CustomStringConvertible, CustomDebugStringConvertible {}

// MARK: - MMDD

internal extension Date {

    /// Unvalidated date represented as "DD-mm"
    struct MM_DD: Equatable, Hashable, Codable, Sendable {

        public let day: Day

        public let month: Month

        public init(
            day: Day = 1,
            month: Month = .january
        ) {
            self.day = day
            self.month = month
        }
    }
}

internal extension Date.MM_DD {

    typealias Day = Date.Day

    typealias Month = Date.Month
}

extension Date.MM_DD: CustomDateRawRepresentable {

    public init?(rawValue: String) {
        let components = rawValue.components(separatedBy: "-")
        guard components.count == 2,
            let month = UInt(components[0]).flatMap({ Month(rawValue: $0) }),
            let day = UInt(components[1]).flatMap({ Day(rawValue: $0) })
        else { return nil }
        self.init(day: day, month: month)
    }

    public var rawValue: String {
        // MM-dd format
        var day = day.rawValue.description
        while day.count < 2 {
            day = "0" + day
        }
        var month = month.rawValue.description
        while month.count < 2 {
            month = "0" + month
        }
        return month + "-" + day
    }
}

// MARK: - MM/dd/yyyy

public extension Date {

    /// Date represented as "MM/dd/yyyy"
    struct `MM/dd/yyyy`: Equatable, Hashable, Codable, Sendable {

        public let day: Day

        public let month: Month

        public let year: Year

        public init?(
            day: Day = 1,
            month: Month = .january,
            year: UInt
        ) {
            guard let date = Self.date(day: day, month: month, year: year) else {
                return nil
            }
            self.init(unsafe: (day: day, month: month, year: year))
            assert(self.date == date)
        }

        internal init(unsafe: (day: Day, month: Month, year: UInt)) {
            assert(unsafe.day.rawValue >= 1 && unsafe.day.rawValue <= 31)
            assert(unsafe.month.rawValue >= 1 && unsafe.month.rawValue <= 12)
            self.day = unsafe.day
            self.month = unsafe.month
            self.year = unsafe.year
        }
    }
}

public extension Date.`MM/dd/yyyy` {

    typealias Day = Date.Day

    typealias Month = Date.Month

    typealias Year = UInt
}

internal extension Date.`MM/dd/yyyy` {

    static func string(day: Date.Day, month: Date.Month, year: UInt) -> String? {
        guard let date = date(day: day, month: month, year: year) else {
            return nil
        }
        return string(from: date)
    }

    static func date(day: Date.Day, month: Date.Month, year: UInt) -> Date? {
        let components = DateComponents(
            calendar: Self.dateFormatter.calendar,
            timeZone: Self.dateFormatter.timeZone,
            year: Int(year),
            month: Int(month.rawValue),
            day: Int(day.rawValue)
        )
        return components.date
    }

    static func components(from date: Date) -> (day: Day, month: Month, year: UInt) {
        let rawDay = Self.dateFormatter.calendar.component(.day, from: date)
        let rawMonth = Self.dateFormatter.calendar.component(.month, from: date)
        let year = Self.dateFormatter.calendar.component(.year, from: date)
        guard let day = Day(rawValue: UInt(rawDay)) else {
            fatalError("Invalid day \(rawDay)")
        }
        guard let month = Month(rawValue: UInt(rawMonth)) else {
            fatalError("Invalid month \(rawMonth)")
        }
        return (day, month, UInt(year))
    }
}

extension Date.`MM/dd/yyyy`: CustomStringConvertible, CustomDebugStringConvertible {}

extension Date.`MM/dd/yyyy`: CustomFormattedDate {

    public static var format: String { "MM/dd/yyyy" }

    public static func string(from date: Date) -> String {
        _string(from: date)
    }

    public static func date(from string: String) -> Date? {
        _date(from: string)
    }

    public init(date: Date) {
        let components = Self.components(from: date)
        self.init(unsafe: (day: components.day, month: components.month, year: components.year))
    }

    public var date: Date {
        guard let date = Self.date(day: day, month: month, year: year) else {
            assertionFailure("Invalid date \(self)")
            return .distantPast
        }
        return date
    }
}

extension Date.`MM/dd/yyyy`: CustomFormattedDateInternal {

    internal static let dateFormatter = Foundation.DateFormatter(
        dateFormat: format,
        timeZone: .init(secondsFromGMT: 0)!
    )
}

extension Date.`MM/dd/yyyy`: CustomDateComponentsRepresentable {

    public var dateComponents: DateComponents {
        DateComponents(
            calendar: Self.dateFormatter.calendar,
            timeZone: Self.dateFormatter.timeZone,
            year: Int(year),
            month: Int(month.rawValue),
            day: Int(day.rawValue)
        )
    }
}

extension Date.`MM/dd/yyyy`: CustomDateRawRepresentable {}
