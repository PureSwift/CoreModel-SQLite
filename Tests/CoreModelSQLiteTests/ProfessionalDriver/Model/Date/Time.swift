//
//  Time.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/3/25.
//

import Foundation
import CoreModel

public extension Date {

    /// Represents a time of day with hour, minute, and second components
    struct Time: Equatable, Hashable, Codable, Sendable {

        public var hour: UInt

        public var minute: UInt

        public var second: UInt

        public init(hour: UInt, minute: UInt, second: UInt = 0) {
            self.hour = hour
            self.minute = minute
            self.second = second
        }
    }
}

// MARK: - CustomStringConvertible

extension Date.Time: CustomStringConvertible {

    public var description: String {
        return rawValue
    }
}

// MARK: - RawRepresentable

extension Date.Time: RawRepresentable {

    /// Initialize from a time string in format "HH:mm:ss" or "HH:mm"
    public init?(rawValue string: String) {
        let components =
            string
            .split(separator: ":")
            .compactMap { UInt($0) }

        guard components.count >= 2 && components.count <= 3 else {
            return nil
        }

        let hour = components[0]
        let minute = components[1]
        let second = components.count > 2 ? components[2] : 0

        guard hour >= 0 && hour <= 23,
            minute >= 0 && minute <= 59,
            second >= 0 && second <= 59
        else {
            return nil
        }

        self.hour = hour
        self.minute = minute
        self.second = second
    }

    /// Convert to string in format "HH:mm:ss"
    public var rawValue: String {
        Self.description(for: hour)
            + ":" + Self.description(for: minute)
            + ":" + Self.description(for: second)
    }

    static private func description(for component: UInt) -> String {
        var description = component.description
        while description.count < 2 {
            description = "0" + description
        }
        assert(description.count == 2)
        return description
    }
}

// MARK: - Time Interval

public extension TimeInterval {

    init(_ time: Date.Time) {
        self =
            TimeInterval(time.hour) * 60 * 60
            + TimeInterval(time.minute) * 60
            + TimeInterval(time.second)
    }
}

public extension Date.Time {

    init(seconds: TimeInterval) {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60

        self.hour = UInt(hours)
        self.minute = UInt(minutes)
        self.second = UInt(remainingSeconds)
    }
}

// MARK: - CoreModel

extension Date.Time: AttributeCodable {}
