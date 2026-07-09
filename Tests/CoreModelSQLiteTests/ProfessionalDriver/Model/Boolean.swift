//
//  Boolean.swift
//
//
//  Created by Alsey Coleman Miller  on 8/23/23.
//

import Foundation

public enum ProfessionalDriverBool: String, Codable, Sendable {

    case no = "N"
    case yes = "Y"
}

public extension ProfessionalDriverBool {

    init?(rawValue: String) {
        switch rawValue {
        case "N":
            self = .no
        case "Y":
            self = .yes
        case "":
            self = .no
        default:
            return nil
        }
    }

    init(_ value: Bool) {
        self = value ? .yes : .no
    }
}

public extension Bool {

    init(_ value: ProfessionalDriverBool) {
        switch value {
        case .yes:
            self = true
        case .no:
            self = false
        }
    }
}

// MARK: - ExpressibleByBooleanLiteral

extension ProfessionalDriverBool: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}
