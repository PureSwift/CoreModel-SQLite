//
//  State.swift
//
//
//  Created by Alsey Coleman Miller on 8/29/23.
//

import CoreModel

/// Enum representing U.S. states and the Canadian province of Ontario.
public enum TerritorialState: Equatable, Hashable, Codable, Sendable {

    case unitedStates(UnitedStates)
    case canada(Canada)
}

// MARK: - CaseIterable

extension TerritorialState: CaseIterable {

    public static var allCases: [TerritorialState] {
        UnitedStates.allCases.map { .unitedStates($0) }
            + Canada.allCases.map { .canada($0) }
    }
}

// MARK: - RawRepresentable

extension TerritorialState: RawRepresentable {

    public init?(rawValue: String) {
        if let us = UnitedStates(rawValue: rawValue) {
            self = .unitedStates(us)
        } else if let ca = Canada(rawValue: rawValue) {
            self = .canada(ca)
        } else {
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .unitedStates(let value):
            return value.rawValue
        case .canada(let value):
            return value.rawValue
        }
    }
}

// MARK: - AttributeCodable

extension TerritorialState: AttributeCodable {}

// MARK: - CustomStringConvertible

extension TerritorialState: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

// MARK: - Supporting Types

public extension TerritorialState {

    enum Canada: String, Codable, CaseIterable, Sendable {

        /// Canadian province of Alberta
        case alberta = "AB"

        /// Canadian province of British Columbia
        case britishColumbia = "BC"

        /// Canadian province of Manitoba
        case manitoba = "MB"

        /// Canadian province of New Brunswick
        case newBrunswick = "NB"

        /// Canadian province of Newfoundland and Labrador
        case newfoundlandAndLabrador = "NL"

        /// Canadian territory of Northwest Territories
        case northwestTerritories = "NT"

        /// Canadian province of Nova Scotia
        case novaScotia = "NS"

        /// Canadian territory of Nunavut
        case nunavut = "NU"

        /// Canadian province of Ontario
        case ontario = "ON"

        /// Canadian province of Prince Edward Island
        case princeEdwardIsland = "PE"

        /// Canadian province of Quebec
        case quebec = "QC"

        /// Canadian province of Saskatchewan
        case saskatchewan = "SK"

        /// Canadian territory of Yukon
        case yukon = "YT"
    }

    enum UnitedStates: String, Codable, CaseIterable, Sendable {

        /// U.S. state of Alabama
        case alabama = "AL"

        /// U.S. state of Alaska
        case alaska = "AK"

        /// U.S. state of Arizona
        case arizona = "AZ"

        /// U.S. state of Arkansas
        case arkansas = "AR"

        /// U.S. state of California
        case california = "CA"

        /// U.S. state of Colorado
        case colorado = "CO"

        /// U.S. state of Connecticut
        case connecticut = "CT"

        /// U.S. state of Delaware
        case delaware = "DE"

        /// U.S. state of Florida
        case florida = "FL"

        /// U.S. state of Georgia
        case georgia = "GA"

        /// U.S. state of Hawaii
        case hawaii = "HI"

        /// U.S. state of Idaho
        case idaho = "ID"

        /// U.S. state of Illinois
        case illinois = "IL"

        /// U.S. state of Indiana
        case indiana = "IN"

        /// U.S. state of Iowa
        case iowa = "IA"

        /// U.S. state of Kansas
        case kansas = "KS"

        /// U.S. state of Kentucky
        case kentucky = "KY"

        /// U.S. state of Louisiana
        case louisiana = "LA"

        /// U.S. state of Maine
        case maine = "ME"

        /// U.S. state of Maryland
        case maryland = "MD"

        /// U.S. state of Massachusetts
        case massachusetts = "MA"

        /// U.S. state of Michigan
        case michigan = "MI"

        /// U.S. state of Minnesota
        case minnesota = "MN"

        /// U.S. state of Mississippi
        case mississippi = "MS"

        /// U.S. state of Missouri
        case missouri = "MO"

        /// U.S. state of Montana
        case montana = "MT"

        /// U.S. state of Nebraska
        case nebraska = "NE"

        /// U.S. state of Nevada
        case nevada = "NV"

        /// U.S. state of New Hampshire
        case newHampshire = "NH"

        /// U.S. state of New Jersey
        case newJersey = "NJ"

        /// U.S. state of New Mexico
        case newMexico = "NM"

        /// U.S. state of New York
        case newYork = "NY"

        /// U.S. state of North Carolina
        case northCarolina = "NC"

        /// U.S. state of North Dakota
        case northDakota = "ND"

        /// U.S. state of Ohio
        case ohio = "OH"

        /// U.S. state of Oklahoma
        case oklahoma = "OK"

        /// U.S. state of Oregon
        case oregon = "OR"

        /// U.S. state of Pennsylvania
        case pennsylvania = "PA"

        /// U.S. state of Rhode Island
        case rhodeIsland = "RI"

        /// U.S. state of South Carolina
        case southCarolina = "SC"

        /// U.S. state of South Dakota
        case southDakota = "SD"

        /// U.S. state of Tennessee
        case tennessee = "TN"

        /// U.S. state of Texas
        case texas = "TX"

        /// U.S. state of Utah
        case utah = "UT"

        /// U.S. state of Vermont
        case vermont = "VT"

        /// U.S. state of Virginia
        case virginia = "VA"

        /// U.S. state of Washington
        case washington = "WA"

        /// U.S. state of West Virginia
        case westVirginia = "WV"

        /// U.S. state of Wisconsin
        case wisconsin = "WI"

        /// U.S. state of Wyoming
        case wyoming = "WY"
    }
}

// MARK: - Name

public extension TerritorialState {

    enum Name: Equatable, Hashable, Codable, Sendable {

        case unitedStates(TerritorialState.Name.UnitedStates)
        case canada(TerritorialState.Name.Canada)
    }
}

// MARK: - Name Property

public extension TerritorialState {

    init(name: TerritorialState.Name) {
        switch name {
        case .unitedStates(let stateName):
            self = .unitedStates(UnitedStates(name: stateName))
        case .canada(let provinceName):
            self = .canada(Canada(name: provinceName))
        }
    }

    var name: TerritorialState.Name {
        switch self {
        case .unitedStates(let state):
            return .unitedStates(state.name)
        case .canada(let province):
            return .canada(province.name)
        }
    }
}

// MARK: - CaseIterable

extension TerritorialState.Name: CaseIterable {

    public static var allCases: [TerritorialState.Name] {
        TerritorialState.Name.UnitedStates.allCases.map { .unitedStates($0) }
            + TerritorialState.Name.Canada.allCases.map { .canada($0) }
    }
}

// MARK: - RawRepresentable

extension TerritorialState.Name: RawRepresentable {

    public init?(rawValue: String) {
        if let us = TerritorialState.Name.UnitedStates(rawValue: rawValue) {
            self = .unitedStates(us)
        } else if let ca = TerritorialState.Name.Canada(rawValue: rawValue) {
            self = .canada(ca)
        } else {
            return nil
        }
    }

    public var rawValue: String {
        switch self {
        case .unitedStates(let value):
            return value.rawValue
        case .canada(let value):
            return value.rawValue
        }
    }
}

// MARK: - CustomStringConvertible

extension TerritorialState.Name: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

// MARK: - US State Names

public extension TerritorialState.Name {

    /// Full name of US State
    enum UnitedStates: String, Codable, CaseIterable, Sendable {

        case alabama = "Alabama"
        case alaska = "Alaska"
        case arizona = "Arizona"
        case arkansas = "Arkansas"
        case california = "California"
        case colorado = "Colorado"
        case connecticut = "Connecticut"
        case delaware = "Delaware"
        case florida = "Florida"
        case georgia = "Georgia"
        case hawaii = "Hawaii"
        case idaho = "Idaho"
        case illinois = "Illinois"
        case indiana = "Indiana"
        case iowa = "Iowa"
        case kansas = "Kansas"
        case kentucky = "Kentucky"
        case louisiana = "Louisiana"
        case maine = "Maine"
        case maryland = "Maryland"
        case massachusetts = "Massachusetts"
        case michigan = "Michigan"
        case minnesota = "Minnesota"
        case mississippi = "Mississippi"
        case missouri = "Missouri"
        case montana = "Montana"
        case nebraska = "Nebraska"
        case nevada = "Nevada"
        case newHampshire = "New Hampshire"
        case newJersey = "New Jersey"
        case newMexico = "New Mexico"
        case newYork = "New York"
        case northCarolina = "North Carolina"
        case northDakota = "North Dakota"
        case ohio = "Ohio"
        case oklahoma = "Oklahoma"
        case oregon = "Oregon"
        case pennsylvania = "Pennsylvania"
        case rhodeIsland = "Rhode Island"
        case southCarolina = "South Carolina"
        case southDakota = "South Dakota"
        case tennessee = "Tennessee"
        case texas = "Texas"
        case utah = "Utah"
        case vermont = "Vermont"
        case virginia = "Virginia"
        case washington = "Washington"
        case westVirginia = "West Virginia"
        case wisconsin = "Wisconsin"
        case wyoming = "Wyoming"
    }
}

extension TerritorialState.Name.UnitedStates: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

public extension TerritorialState.UnitedStates {

    init(name: TerritorialState.Name.UnitedStates) {
        switch name {
        case .alabama:
            self = .alabama
        case .alaska:
            self = .alaska
        case .arizona:
            self = .arizona
        case .arkansas:
            self = .arkansas
        case .california:
            self = .california
        case .colorado:
            self = .colorado
        case .connecticut:
            self = .connecticut
        case .delaware:
            self = .delaware
        case .florida:
            self = .florida
        case .georgia:
            self = .georgia
        case .hawaii:
            self = .hawaii
        case .idaho:
            self = .idaho
        case .illinois:
            self = .illinois
        case .indiana:
            self = .indiana
        case .iowa:
            self = .iowa
        case .kansas:
            self = .kansas
        case .kentucky:
            self = .kentucky
        case .louisiana:
            self = .louisiana
        case .maine:
            self = .maine
        case .maryland:
            self = .maryland
        case .massachusetts:
            self = .massachusetts
        case .michigan:
            self = .michigan
        case .minnesota:
            self = .minnesota
        case .mississippi:
            self = .mississippi
        case .missouri:
            self = .missouri
        case .montana:
            self = .montana
        case .nebraska:
            self = .nebraska
        case .nevada:
            self = .nevada
        case .newHampshire:
            self = .newHampshire
        case .newJersey:
            self = .newJersey
        case .newMexico:
            self = .newMexico
        case .newYork:
            self = .newYork
        case .northCarolina:
            self = .northCarolina
        case .northDakota:
            self = .northDakota
        case .ohio:
            self = .ohio
        case .oklahoma:
            self = .oklahoma
        case .oregon:
            self = .oregon
        case .pennsylvania:
            self = .pennsylvania
        case .rhodeIsland:
            self = .rhodeIsland
        case .southCarolina:
            self = .southCarolina
        case .southDakota:
            self = .southDakota
        case .tennessee:
            self = .tennessee
        case .texas:
            self = .texas
        case .utah:
            self = .utah
        case .vermont:
            self = .vermont
        case .virginia:
            self = .virginia
        case .washington:
            self = .washington
        case .westVirginia:
            self = .westVirginia
        case .wisconsin:
            self = .wisconsin
        case .wyoming:
            self = .wyoming
        }
    }

    var name: TerritorialState.Name.UnitedStates {
        switch self {
        case .alabama: return .alabama
        case .alaska: return .alaska
        case .arizona: return .arizona
        case .arkansas: return .arkansas
        case .california: return .california
        case .colorado: return .colorado
        case .connecticut: return .connecticut
        case .delaware: return .delaware
        case .florida: return .florida
        case .georgia: return .georgia
        case .hawaii: return .hawaii
        case .idaho: return .idaho
        case .illinois: return .illinois
        case .indiana: return .indiana
        case .iowa: return .iowa
        case .kansas: return .kansas
        case .kentucky: return .kentucky
        case .louisiana: return .louisiana
        case .massachusetts: return .massachusetts
        case .maryland: return .maryland
        case .maine: return .maine
        case .michigan: return .michigan
        case .minnesota: return .minnesota
        case .mississippi: return .mississippi
        case .missouri: return .missouri
        case .montana: return .montana
        case .nebraska: return .nebraska
        case .nevada: return .nevada
        case .newHampshire: return .newHampshire
        case .newJersey: return .newJersey
        case .newMexico: return .newMexico
        case .newYork: return .newYork
        case .northCarolina: return .northCarolina
        case .northDakota: return .northDakota
        case .ohio: return .ohio
        case .oklahoma: return .oklahoma
        case .oregon: return .oregon
        case .pennsylvania: return .pennsylvania
        case .rhodeIsland: return .rhodeIsland
        case .southCarolina: return .southCarolina
        case .southDakota: return .southDakota
        case .tennessee: return .tennessee
        case .texas: return .texas
        case .utah: return .utah
        case .vermont: return .vermont
        case .virginia: return .virginia
        case .washington: return .washington
        case .westVirginia: return .westVirginia
        case .wisconsin: return .wisconsin
        case .wyoming: return .wyoming
        }
    }
}

// MARK: - Canadian State Name

public extension TerritorialState.Name {

    /// Full name of Canadian State
    enum Canada: String, Codable, CaseIterable, Sendable {

        case alberta = "Alberta"
        case britishColumbia = "British Columbia"
        case manitoba = "Manitoba"
        case newBrunswick = "New Brunswick"
        case newfoundlandAndLabrador = "Newfoundland and Labrador"
        case northwestTerritories = "Northwest Territories"
        case novaScotia = "Nova Scotia"
        case nunavut = "Nunavut"
        case ontario = "Ontario"
        case princeEdwardIsland = "Prince Edward Island"
        case quebec = "Quebec"
        case saskatchewan = "Saskatchewan"
        case yukon = "Yukon"
    }
}

extension TerritorialState.Name.Canada: CustomStringConvertible {

    public var description: String {
        rawValue
    }
}

public extension TerritorialState.Canada {

    init(name: TerritorialState.Name.Canada) {
        switch name {
        case .alberta:
            self = .alberta
        case .britishColumbia:
            self = .britishColumbia
        case .manitoba:
            self = .manitoba
        case .newBrunswick:
            self = .newBrunswick
        case .newfoundlandAndLabrador:
            self = .newfoundlandAndLabrador
        case .northwestTerritories:
            self = .northwestTerritories
        case .novaScotia:
            self = .novaScotia
        case .nunavut:
            self = .nunavut
        case .ontario:
            self = .ontario
        case .princeEdwardIsland:
            self = .princeEdwardIsland
        case .quebec:
            self = .quebec
        case .saskatchewan:
            self = .saskatchewan
        case .yukon:
            self = .yukon
        }
    }

    var name: TerritorialState.Name.Canada {
        switch self {
        case .alberta: return .alberta
        case .britishColumbia: return .britishColumbia
        case .manitoba: return .manitoba
        case .newBrunswick: return .newBrunswick
        case .newfoundlandAndLabrador: return .newfoundlandAndLabrador
        case .northwestTerritories: return .northwestTerritories
        case .novaScotia: return .novaScotia
        case .nunavut: return .nunavut
        case .ontario: return .ontario
        case .princeEdwardIsland: return .princeEdwardIsland
        case .quebec: return .quebec
        case .saskatchewan: return .saskatchewan
        case .yukon: return .yukon
        }
    }
}
