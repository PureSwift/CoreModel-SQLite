//
//  OpenType.swift
//  CoreModel
//
//  Created by cmiller11 on 10/2/25.
//

/// The type of opening for a location
public enum OpenType: String, Codable, Sendable, CaseIterable {

    case acquisition = "Acquisition"
    case newBuild = "New Build"
    case conversion = "Conversion"
    case franchised = "Franchised"
    case partnership = "Partnership"
}
