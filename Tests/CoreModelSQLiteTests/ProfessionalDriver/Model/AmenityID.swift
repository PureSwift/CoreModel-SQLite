//
//  AmenityName.swift
//  ProfessionalDriver
//
//  Created by Alsey Coleman Miller on 10/8/25.
//

import Foundation
import CoreModel

public extension Amenity {

    /// ProfessionalDriver Amenity ID
    struct ID: RawRepresentable, Codable, Equatable, Hashable, Sendable {

        public let rawValue: String

        public init?(rawValue: String) {
            guard rawValue.isEmpty == false else {
                return nil
            }
            self.init(rawValue)
        }

        private init(_ raw: String) {
            assert(raw.isEmpty == false)
            self.rawValue = raw
        }
    }
}

public extension Amenity.ID {

    init?(name: String) {
        let id =
            name
            .lowercased()
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: " ", with: "-")
        self.init(rawValue: id)
    }
}

// MARK: - CoreModel

extension Amenity.ID: ObjectIDConvertible {}

// MARK: - ExpressibleByStringLiteral

extension Amenity.ID: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        guard let value = Amenity.ID(rawValue: value) else {
            fatalError("Invalid raw value for \(Amenity.ID.self): \(value)")
        }
        self = value
    }
}

// MARK: - CustomStringConvertible

extension Amenity.ID: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        rawValue
    }

    public var debugDescription: String {
        rawValue
    }
}

// MARK: - Constants

public extension Amenity.ID {

    // MARK: Services

    static var permitServices: Amenity.ID { .init(name: "Permit Services")! }
    static var urgentCare: Amenity.ID { .init(name: "Urgent Care")! }
    static var checkCashingServices: Amenity.ID { .init(name: "Check Cashing Services")! }
    static var westernUnion: Amenity.ID { .init(name: "Western Union")! }
    static var ministryServices: Amenity.ID { .init(name: "Ministry Services")! }
    static var medicalServices: Amenity.ID { .init(name: "Medical Services")! }
    static var drugTestingServices: Amenity.ID { .init(name: "Drug Testing Services")! }
    static var dotPhysicals: Amenity.ID { .init(name: "DOT Physicals")! }
    static var dentalServices: Amenity.ID { .init(name: "Dental Services")! }
    static var chiropractorServices: Amenity.ID { .init(name: "Chiropractor Services")! }
    static var dpfService: Amenity.ID { .init(name: "DPF Service (Diesel Particulate Filter)")! }
    static var transfloExpressScanning: Amenity.ID { .init(name: "Transflo Express Scanning")! }
    static var transfloFaxingServices: Amenity.ID { .init(name: "TransFlo/Faxing Services")! }
    static var barberShop: Amenity.ID { .init(name: "Barber Shop")! }

    // MARK: Technology & Communication

    static var courtesyWiFiRestaurant: Amenity.ID { .init(name: "Courtesy WiFi in Restaurant/Fast Food Area")! }
    static var interstateSpeedZoneWiFi: Amenity.ID { .init(name: "Interstate Speedzone WiFi")! }
    static var verizonWireless: Amenity.ID { .init(name: "Verizon Wireless")! }
    static var rfidPumpStart: Amenity.ID { .init(name: "RFID Pump Start")! }
    static var directvNFLSundayTicket: Amenity.ID { .init(name: "DirecTV/NFL Sunday Ticket")! }

    // MARK: Fuel & Vehicle Services

    static var truckScaleCertified: Amenity.ID { .init(name: "Truck Scale-Certified/Unbranded")! }
    static var catScale: Amenity.ID { .init(name: "CAT Scale")! }
    static var reeferServices: Amenity.ID { .init(name: "Reefer Services")! }
    static var propaneFillUpServices: Amenity.ID { .init(name: "Propane Fill Up Services")! }
    static var electricCarChargingStation: Amenity.ID { .init(name: "Electric Car Charging Station")! }

    // MARK: Facilities & Amenities

    static var laundryRoom: Amenity.ID { .init(name: "Laundry Room")! }
    static var motel: Amenity.ID { .init(name: "Motel")! }
    static var lodging: Amenity.ID { .init(name: "Lodging")! }
    static var americasBestValueInn: Amenity.ID { .init(name: "America's Best Value Inn")! }
    static var driverLounge: Amenity.ID { .init(name: "Driver Lounge")! }
    static var dogWash: Amenity.ID { .init(name: "Dog Wash")! }
    static var petArea: Amenity.ID { .init(name: "Pet Area")! }
    static var rvDump: Amenity.ID { .init(name: "RV Dump")! }
    static var atmAvailable: Amenity.ID { .init(name: "ATM Available")! }
    static var paidCarParking: Amenity.ID { .init(name: "Paid Car Parking")! }
    static var travelStore: Amenity.ID { .init(name: "Travel Store")! }
    static var fitnessRoom: Amenity.ID { .init(name: "Fitness Room")! }

    // MARK: Entertainment & Gaming

    static var videoGamingTerminal: Amenity.ID { .init(name: "Video Gaming Terminal")! }
    static var videoLotteryTerminal: Amenity.ID { .init(name: "Video Lottery Terminal")! }
    static var bowlingAlleyGameCenter: Amenity.ID { .init(name: "Bowling Alley/Game Center")! }
    static var gameRoom: Amenity.ID { .init(name: "Game Room")! }
    static var casino: Amenity.ID { .init(name: "Casino")! }
    static var dollarBillsSlots: Amenity.ID { .init(name: "Dollar Bill's Slots")! }
    static var theaterRoom: Amenity.ID { .init(name: "Theater Room")! }

    // MARK: Shopping & Retail

    static var speedzone: Amenity.ID { .init(name: "Speedzone")! }
    static var liquorStore: Amenity.ID { .init(name: "Liquor Store")! }
    static var amazonLockers: Amenity.ID { .init(name: "Amazon Lockers")! }
    static var cbShop: Amenity.ID { .init(name: "CB Shop")! }
    static var cafeExpress: Amenity.ID { .init(name: "Café Express")! }
    static var embroideryShop: Amenity.ID { .init(name: "Embroidery Shop")! }
    static var chromeShop: Amenity.ID { .init(name: "Chrome Shop")! }
    static var bookStore: Amenity.ID { .init(name: "Book Store")! }
    static var radioshack: Amenity.ID { .init(name: "Radioshack")! }

    // MARK: StayFit Program

    static var stayfitHorseshoePit: Amenity.ID { .init(name: "STAYFIT Horseshoe Pit")! }
    static var stayfitBasketballHoop: Amenity.ID { .init(name: "STAYFIT Basketball Hoop")! }
    static var stayfitOutdoorFitnessRoom: Amenity.ID { .init(name: "STAYFIT Outdoor Fitness Room")! }
    static var stayfitBeanBagToss: Amenity.ID { .init(name: "STAYFIT Bean Bag Toss")! }
    static var stayfitFitnessRoom: Amenity.ID { .init(name: "STAYFIT Fitness Room")! }
    static var stayfitWalkingTrail: Amenity.ID { .init(name: "STAYFIT Walking Trail")! }

    // MARK: Restaurants & Full Service Dining

    static var dollyDown: Amenity.ID { .init(name: "Dolly Down")! }
    static var indianCurryNaanStop: Amenity.ID { .init(name: "Indian Curry Naan Stop")! }
    static var blackBearDiner: Amenity.ID { .init(name: "Black Bear Diner")! }
    static var familyRestaurant: Amenity.ID { .init(name: "Family Restaurant")! }
    static var ozarkCafe: Amenity.ID { .init(name: "Ozark Café")! }
    static var diner230: Amenity.ID { .init(name: "230 Diner")! }
    static var perkinsFamilyRestaurant: Amenity.ID { .init(name: "Perkins Family Restaurant")! }
    static var blueBadgerBarAndGrill: Amenity.ID { .init(name: "Blue Badger Bar and Grill")! }
    static var boondocksDiner: Amenity.ID { .init(name: "Boondocks Diner")! }
    static var edenGardenRestaurant: Amenity.ID { .init(name: "Eden Garden Restaurant")! }
    static var nelsonBrothers: Amenity.ID { .init(name: "Nelson Brothers")! }
    static var theDish: Amenity.ID { .init(name: "The Dish")! }
    static var hubRoom: Amenity.ID { .init(name: "Hub Room")! }
    static var skolTavern: Amenity.ID { .init(name: "Skol Tavern")! }
    static var atlantaSouthFamilyRestaurant: Amenity.ID { .init(name: "Atlanta South Family Restaurant")! }
    static var russellsRoute66Cafe: Amenity.ID { .init(name: "Russell's Route 66 Café")! }
    static var hubCafe: Amenity.ID { .init(name: "Hub Café")! }
    static var cantina: Amenity.ID { .init(name: "Cantina")! }
    static var coburgCrossingCafe: Amenity.ID { .init(name: "Coburg Crossing Cafe")! }
    static var missJsDiner: Amenity.ID { .init(name: "Miss J's Diner")! }
    static var austinsSteakAndSeafood: Amenity.ID { .init(name: "Austin's Steak & Seafood")! }
    static var theAmericanRoadDiner: Amenity.ID { .init(name: "The American Road Diner")! }
    static var petroDiner: Amenity.ID { .init(name: "Petro Diner")! }
    static var bonniesKitchen: Amenity.ID { .init(name: "Bonnie's Kitchen(franchise)")! }
    static var primoTaqueria: Amenity.ID { .init(name: "Primo Taqueria")! }
    static var globalBarAndGrill: Amenity.ID { .init(name: "Global Bar & Grill")! }
    static var dottiesFamilyRestaurant: Amenity.ID { .init(name: "Dottie's Family Restaurant")! }
    static var ihop: Amenity.ID { .init(name: "IHOP")! }
    static var rPlace: Amenity.ID { .init(name: "R Place")! }
    static var applewoodRestaurant: Amenity.ID { .init(name: "Applewood Restaurant")! }
    static var quakerSteakAndLube: Amenity.ID { .init(name: "Quaker Steak & Lube")! }
    static var cherylsPotatoBoat: Amenity.ID { .init(name: "Cheryl's Potato Boat")! }
    static var iowa80Kitchen: Amenity.ID { .init(name: "Iowa 80 Kitchen")! }
    static var ironSkillet: Amenity.ID { .init(name: "Iron Skillet")! }
    static var countryPride: Amenity.ID { .init(name: "Country Pride")! }
    static var fuddruckers: Amenity.ID { .init(name: "Fuddruckers")! }
    static var townAndCountry: Amenity.ID { .init(name: "Town & Country")! }
    static var taCafe: Amenity.ID { .init(name: "TA Cafe")! }
    static var forkAndCompass: Amenity.ID { .init(name: "Fork and Compass")! }
    static var dennys: Amenity.ID { .init(name: "Denny's")! }
    static var bostonMarket: Amenity.ID { .init(name: "Boston Market")! }
    static var trails: Amenity.ID { .init(name: "Trail's")! }
    static var derailDiner: Amenity.ID { .init(name: "Derail Diner")! }
    static var fullServiceRestaurant: Amenity.ID { .init(name: "Full Service Restaurant")! }
    static var russellsRestaurant: Amenity.ID { .init(name: "Russell's Restaurant")! }
    static var johnsonsCorner: Amenity.ID { .init(name: "Johnson's Corner")! }
    static var bobEvans: Amenity.ID { .init(name: "Bob Evans")! }
    static var tacoCasa: Amenity.ID { .init(name: "Taco Casa")! }
    static var wilhites: Amenity.ID { .init(name: "Wilhite's")! }
    static var diner88: Amenity.ID { .init(name: "88 Diner")! }
    static var homestyleKitchen: Amenity.ID { .init(name: "Homestyle Kitchen")! }
    static var dukesBakery: Amenity.ID { .init(name: "Duke's Bakery")! }
    static var petroRacineFoodTruck: Amenity.ID { .init(name: "Petro Racine Food Truck")! }
    static var brickOvenPizza: Amenity.ID { .init(name: "Brick Oven Pizza")! }
    static var huddleHouse: Amenity.ID { .init(name: "Huddle House")! }

    // MARK: Fast Food & Quick Service

    static var dunkin: Amenity.ID { .init(name: "Dunkin'")! }
    static var carlsJr: Amenity.ID { .init(name: "Carl's Jr.")! }
    static var pizzaHutExpress: Amenity.ID { .init(name: "Pizza Hut Express")! }
    static var cinnabon: Amenity.ID { .init(name: "Cinnabon")! }
    static var chesterFriedChicken: Amenity.ID { .init(name: "Chester Fried Chicken")! }
    static var sonic: Amenity.ID { .init(name: "Sonic")! }
    static var fazolis: Amenity.ID { .init(name: "Fazoli's")! }
    static var arbys: Amenity.ID { .init(name: "Arby's")! }
    static var littleCaesars: Amenity.ID { .init(name: "Little Caesar's")! }
    static var missJs: Amenity.ID { .init(name: "Miss J's")! }
    static var prairieMarket: Amenity.ID { .init(name: "Prairie Market")! }
    static var californiaBurritoCompany: Amenity.ID { .init(name: "California Burrito Company")! }
    static var timHortons: Amenity.ID { .init(name: "Tim Horton's")! }
    static var awAllAmericanFood: Amenity.ID { .init(name: "A&W All American Food")! }
    static var papaJohnsPizza: Amenity.ID { .init(name: "Papa John's Pizza")! }
    static var gatewayHomestyleExpress: Amenity.ID { .init(name: "Gateway Homestyle Express")! }
    static var caribouCoffee: Amenity.ID { .init(name: "Caribou Coffee")! }
    static var orangeJulius: Amenity.ID { .init(name: "Orange Julius")! }
    static var tuleTreeLegendaryBurritos: Amenity.ID { .init(name: "Tule Tree Legendary Burritos")! }
    static var mcdonalds: Amenity.ID { .init(name: "Mcdonald's")! }
    static var wrDeli: Amenity.ID { .init(name: "WR Deli")! }
    static var pickadillyCircusPizza: Amenity.ID { .init(name: "Pickadilly Circus Pizza")! }
    static var hardees: Amenity.ID { .init(name: "Hardee's")! }
    static var tacoTime: Amenity.ID { .init(name: "Taco Time")! }
    static var cityWokFreshChinese: Amenity.ID { .init(name: "City Wok Fresh Chinese")! }
    static var hotStuffKitchen: Amenity.ID { .init(name: "Hot Stuff Kitchen")! }
    static var tacoBellAndPizzaHutExpress: Amenity.ID { .init(name: "Taco Bell & Pizza Hut Express")! }
    static var quiznos: Amenity.ID { .init(name: "Quizno's")! }
    static var bluTaco: Amenity.ID { .init(name: "Blu Taco")! }
    static var bigMadre: Amenity.ID { .init(name: "Big Madre")! }
    static var chappysChicken: Amenity.ID { .init(name: "Chappy's Chicken")! }
    static var goodcents: Amenity.ID { .init(name: "Goodcents")! }
    static var yogurtland: Amenity.ID { .init(name: "Yogurtland")! }
    static var blimpie: Amenity.ID { .init(name: "Blimpie")! }
    static var proKitchen: Amenity.ID { .init(name: "Pro Kitchen")! }
    static var pizzaBrosExpress: Amenity.ID { .init(name: "Pizza Bros. Express")! }
    static var theOriginalFriedPieShop: Amenity.ID { .init(name: "The Original Fried Pie Shop")! }
    static var tacoJohns: Amenity.ID { .init(name: "Taco John's")! }
    static var pizzaHut: Amenity.ID { .init(name: "Pizza Hut")! }
    static var bojangles: Amenity.ID { .init(name: "Bojangles")! }
    static var usSubs: Amenity.ID { .init(name: "Us Subs")! }
    static var cottonBeltBbq: Amenity.ID { .init(name: "Cotton Belt Bbq")! }
    static var godfatherPizza: Amenity.ID { .init(name: "Godfather Pizza")! }
    static var qdobaMexicanGrill: Amenity.ID { .init(name: "Qdoba Mexican Grill")! }
    static var papisPizzaWingsAndSubs: Amenity.ID { .init(name: "Papi's Pizza, Wings And Subs")! }
    static var delTaco: Amenity.ID { .init(name: "Del Taco")! }
    static var schlotzskys: Amenity.ID { .init(name: "Schlotzsky's")! }
    static var burgerKing: Amenity.ID { .init(name: "Burger King")! }
    static var subway: Amenity.ID { .init(name: "Subway")! }
    static var indianCurreyNaanStop: Amenity.ID { .init(name: "Indian Currey NAAN Stop")! }
    static var popeyes: Amenity.ID { .init(name: "Popeyes")! }
    static var charleysPhillySteaks: Amenity.ID { .init(name: "Charleys Philly Steaks")! }
    static var fosterFreeze: Amenity.ID { .init(name: "Foster Freeze")! }
    static var elTapatioFreshMex: Amenity.ID { .init(name: "El Tapatio Fresh Mex")! }
    static var sbarro: Amenity.ID { .init(name: "Sbarro")! }
    static var hangar54Pizza: Amenity.ID { .init(name: "Hangar 54 Pizza")! }
    static var naughtyChileTaqueria: Amenity.ID { .init(name: "Naughty Chile Taqueria")! }
    static var einsteinBagels: Amenity.ID { .init(name: "Einstein Bagels")! }
    static var dairyQueen: Amenity.ID { .init(name: "Dairy Queen")! }
    static var wendys: Amenity.ID { .init(name: "Wendy's")! }
    static var fatburger: Amenity.ID { .init(name: "Fatburger")! }
    static var baskinRobbins: Amenity.ID { .init(name: "Baskin Robbins")! }
    static var broasterChicken: Amenity.ID { .init(name: "Broaster Chicken")! }
    static var bajaFresh: Amenity.ID { .init(name: "Baja Fresh")! }
    static var huntBrothersPizza: Amenity.ID { .init(name: "Hunt Brothers Pizza")! }
    static var tacoBell: Amenity.ID { .init(name: "Taco Bell")! }
    static var metroDeli: Amenity.ID { .init(name: "Metro Deli")! }
    static var goldenChick: Amenity.ID { .init(name: "Golden Chick")! }
    static var kfc: Amenity.ID { .init(name: "KFC")! }
    static var starbucks: Amenity.ID { .init(name: "Starbucks")! }
    static var whataburger: Amenity.ID { .init(name: "Whataburger")! }
    static var quakerSteakAndLubeExpress: Amenity.ID { .init(name: "Quaker Steak & Lube Express")! }
    static var jambaJuice: Amenity.ID { .init(name: "Jamba Juice")! }
    static var champsChicken: Amenity.ID { .init(name: "Champs Chicken")! }
    static var coldStoneCreamery: Amenity.ID { .init(name: "Cold Stone Creamery")! }
    static var chebaro: Amenity.ID { .init(name: "Chebaro")! }
    static var capriottis: Amenity.ID { .init(name: "Capriotti's")! }
    static var tacoBellExpress: Amenity.ID { .init(name: "Taco Bell Express")! }
    static var ohDanishBakery: Amenity.ID { .init(name: "O&H Danish Bakery")! }
    static var hubCityExpress: Amenity.ID { .init(name: "Hub City Express")! }
    static var hotStuffPizza: Amenity.ID { .init(name: "Hot Stuff Pizza")! }
    static var nathansFamousExpress: Amenity.ID { .init(name: "Nathan's Famous Express")! }
    static var theKitchen: Amenity.ID { .init(name: "The Kitchen")! }
    static var gourmetTacoKitchen: Amenity.ID { .init(name: "Gourmet Taco Kitchen")! }
    static var krispyKrunchyChicken: Amenity.ID { .init(name: "Krispy Krunchy Chicken")! }
    static var krispyKreme: Amenity.ID { .init(name: "Krispy Kreme")! }
    static var redSeal: Amenity.ID { .init(name: "Red Seal")! }
    static var deli: Amenity.ID { .init(name: "Deli")! }
    static var dunkinExpress: Amenity.ID { .init(name: "Dunkin' Express")! }
}
