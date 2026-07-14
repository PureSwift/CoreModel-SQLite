//
//  GasVendor.swift
//
//
//  Created by Alsey Coleman Miller on 8/29/23.
//

import CoreModel

/// Gas Vendor
public enum GasVendor: String, Codable, CaseIterable, Sendable {

    case _76 = "76"
    case amoco = "Amoco"
    case arco = "Arco"
    case alon = "Alon"
    case bp = "BP"
    case cenex = "Cenex"
    case chevron = "Chevron"
    case conoco = "Conoco"
    case citgo = "Citgo"
    case exxon = "Exxon"
    case gulf = "Gulf"
    case holiday = "Holiday"
    case marathon = "Marathon"
    case mobil = "Mobil"
    case petro = "Petro"
    case phillips = "Phillips"
    case shell = "Shell"
    case sinclair = "Sinclair"
    case sunoco = "Sunoco"
    case ta = "TA"
    case valero = "Valero"
    case ultraMar = "Ultra-Mar"
}

// MARK: - AttributeCodable

extension GasVendor: AttributeCodable {}

// MARK: - CustomStringConvertible

extension GasVendor: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}
