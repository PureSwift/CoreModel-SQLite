//
//  Device.swift
//
//
//  Created by Alsey Coleman Miller  on 8/29/23.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(SystemConfiguration)
import SystemConfiguration
#endif

/// Device Information
public struct Device: Equatable, Hashable, Codable, Identifiable, Sendable {

    public let id: ID

    public let type: DeviceType

    public init(id: ID, type: DeviceType = .iOS) {
        self.id = id
        self.type = type
    }
}

public extension Device {

    #if canImport(UIKit)
    @MainActor
    init() {
        self.init(id: ID())
    }
    #else
    init() {
        self.init(id: ID())
    }
    #endif
}

// MARK: - Supporting Types

public enum DeviceType: String, Codable, CaseIterable, Sendable {

    case iOS = "iOS"
    case android = "Android"
}

public extension DeviceType {

    static var current: DeviceType {
        #if canImport(Darwin)
        .iOS
        #elseif canImport(Android)
        .android
        #else
        .iOS
        #endif
    }
}

public extension Device {

    /// Unique Device Identifier
    struct ID: RawRepresentable, Codable, Equatable, Hashable, Sendable {

        public let rawValue: String

        public init(rawValue: String) {
            assert(rawValue.isEmpty == false)
            self.rawValue = rawValue
        }
    }
}

// MARK: - ExpressibleByStringLiteral

extension Device.ID: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

// MARK: - CustomStringConvertible

extension Device.ID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

// MARK: Random Value

public extension Device.ID {

    #if canImport(UIKit)
    @MainActor
    init() {
        let model = UIDevice.current.model
        self.init(model: model)
    }
    #elseif canImport(SystemConfiguration)
    init() {
        let model = SCDynamicStoreCopyComputerName(nil, nil)! as String
        self.init(model: model)
    }
    #elseif os(Android)
    init() {
        let model = "Android"
        self.init(model: model)
    }
    #else
    init() {
        let model = ProcessInfo.processInfo.hostName
        self.init(model: model)
    }
    #endif
}

internal extension Device.ID {

    static let dateFormatter = DateFormatter(dateFormat: "yyyMMdd", timeZone: .autoupdatingCurrent)

    init(
        model: String,
        randomNumber: UInt = UInt.random(in: 0...999_999_999),
        date: Date = Date()
    ) {
        self.rawValue = model + Self.dateFormatter.string(from: date) + randomNumber.description
    }
}
