//
//  ProfessionalDriverTests.swift
//  CoreModel-SQLite
import Foundation
import Testing
import CoreModel
@testable import CoreModelSQLite

@Suite("ProfessionalDriver Model", .serialized)
struct ProfessionalDriverTests {

    /// Open a file-backed database (never in-memory) with the ProfessionalDriver model.
    private func makeProfessionalDriverDatabase() throws -> SQLiteDatabase {
        try SQLiteDatabase(
            path: temporaryDatabasePath(named: "ProfessionalDriver"),
            model: .professionalDriver
        )
    }

    /// Decode the 360-site catalog fixture (11,421 objects).
    private func loadCatalog() throws -> [ModelData] {
        let url = try #require(
            Bundle.module.url(forResource: "ProfessionalDriverCatalog", withExtension: "json", subdirectory: "TestFiles")
        )
        return try JSONDecoder().decode([ModelData].self, from: Data(contentsOf: url))
    }

    /// Open a database with the full site catalog inserted.
    private func makeCatalogDatabase() async throws -> SQLiteDatabase {
        let database = try makeProfessionalDriverDatabase()
        try await database.insert(loadCatalog())
        return database
    }

    // MARK: - Catalog insert (Store.insertCatalog path)

    @Test func insertCatalog() async throws {
        let database = try await makeCatalogDatabase()
        let siteCount = try await database.count(FetchRequest(entity: Site.entityName))
        #expect(siteCount == 360)
        // decoding a fetched site through the Entity protocol exercises JSON-style parsing
        let sites = try await database.fetch(FetchRequest(entity: Site.entityName, fetchLimit: 10))
        #expect(sites.count == 10)
        for data in sites {
            let site = try Site(from: data)
            #expect(site.name.isEmpty == false)
        }
    }

    // MARK: - Site search (SiteSearchViewModel)

    @Test func siteSearch() async throws {
        let database = try await makeCatalogDatabase()
        // compound OR of case-insensitive contains over name/city/directions/address/zipCode
        let query = Site.Query.search("Ashland")
        let request = FetchRequest(
            entity: Site.entityName,
            predicate: query.predicate,
            fetchLimit: 100
        )
        let results = try await database.fetch(request).map { try Site(from: $0) }
        #expect(results.isEmpty == false)
        #expect(results.allSatisfy {
            $0.name.localizedCaseInsensitiveContains("Ashland")
                || $0.city.localizedCaseInsensitiveContains("Ashland")
                || ($0.directions?.localizedCaseInsensitiveContains("Ashland") ?? false)
                || $0.address.localizedCaseInsensitiveContains("Ashland")
                || $0.zipCode.rawValue.contains("Ashland")
        })
        // case-insensitivity: the same search lowercased returns the same rows
        let lowercased = Site.Query.search("ashland")
        let lowercasedIDs = try await database.fetchID(
            FetchRequest(entity: Site.entityName, predicate: lowercased.predicate, fetchLimit: 100)
        )
        #expect(Set(lowercasedIDs) == Set(results.map { ObjectID(rawValue: $0.id.description) }))
    }

    @Test func siteSearchByState() async throws {
        let database = try await makeCatalogDatabase()
        let query = try #require(Site.Query.search(nil, states: [.unitedStates(.ohio)]))
        let request = FetchRequest(entity: Site.entityName, predicate: query.predicate)
        let results = try await database.fetch(request).map { try Site(from: $0) }
        #expect(results.isEmpty == false)
        #expect(results.allSatisfy { $0.state == .unitedStates(.ohio) })
        // count agrees with fetch
        let count = try await database.count(request)
        #expect(count == UInt(results.count))
    }

    // MARK: - Sites filter (SitesViewModel)

    @Test func sitesFilterByService() async throws {
        let database = try await makeCatalogDatabase()
        let query = Site.Query.and([.parking(true), .showers(true)])
        let results = try await database.fetch(
            FetchRequest(entity: Site.entityName, predicate: query.predicate)
        ).map { try Site(from: $0) }
        #expect(results.isEmpty == false)
        #expect(results.allSatisfy { $0.parking && $0.showers })
    }

    @Test func sitesFilterByAmenity() async throws {
        let database = try await makeCatalogDatabase()
        // pick an amenity that exists in the catalog
        let amenityData = try #require(
            try await database.fetch(FetchRequest(entity: Amenity.entityName, fetchLimit: 1)).first
        )
        let amenity = try Amenity(from: amenityData)
        // `ANY amenities IN {id}` — many-to-many membership through the join table
        let query = Site.Query.amenities([amenity.id])
        let matching = try await database.fetch(
            FetchRequest(entity: Site.entityName, predicate: query.predicate)
        ).map { try Site(from: $0) }
        #expect(matching.isEmpty == false)
        #expect(matching.allSatisfy { $0.amenities.contains(amenity.id) })
        // parity: every site linked from the amenity's side matches the query
        #expect(Set(matching.map(\.id)) == Set(amenity.sites))
    }

    @Test func sitesFilterByFuelOption() async throws {
        let database = try await makeCatalogDatabase()
        let fuelOptionData = try #require(
            try await database.fetch(FetchRequest(entity: FuelOption.entityName, fetchLimit: 1)).first
        )
        let fuelOption = try FuelOption(from: fuelOptionData)
        let query = Site.Query.fuelOptions([fuelOption.id])
        let matching = try await database.fetch(
            FetchRequest(entity: Site.entityName, predicate: query.predicate)
        ).map { try Site(from: $0) }
        #expect(matching.isEmpty == false)
        #expect(matching.allSatisfy { $0.fuelOptions.contains(fuelOption.id) })
    }

    // MARK: - Amenity list (SiteFilterViewModel)

    @Test func amenitiesByType() async throws {
        let database = try await makeCatalogDatabase()
        let query = Amenity.Query.type(.restaurant)
        let results = try await database.fetch(
            FetchRequest(entity: Amenity.entityName, predicate: query.predicate, fetchLimit: 100)
        ).map { try Amenity(from: $0) }
        #expect(results.isEmpty == false)
        #expect(results.allSatisfy { $0.type == .restaurant })
    }

    // MARK: - Amenity schedule (SiteDetailViewModel)

    @Test func amenityScheduleForSite() async throws {
        let database = try await makeCatalogDatabase()
        // find a schedule so we know a (site, amenity) pair that has one
        let scheduleData = try #require(
            try await database.fetch(FetchRequest(entity: AmenitySchedule.entityName, fetchLimit: 1)).first
        )
        let schedule = try AmenitySchedule(from: scheduleData)
        // to-one relationship equality predicates, ANDed — fetchLimit 7 (one per weekday)
        let query = AmenitySchedule.Query.and([
            .site(schedule.site),
            .amenity(schedule.amenity)
        ])
        let results = try await database.fetch(
            FetchRequest(entity: AmenitySchedule.entityName, predicate: query.predicate, fetchLimit: 7)
        ).map { try AmenitySchedule(from: $0) }
        #expect(results.isEmpty == false)
        #expect(results.count <= 7)
        #expect(results.allSatisfy { $0.site == schedule.site && $0.amenity == schedule.amenity })
    }

    // MARK: - Recently viewed (RecentSitesViewModel)

    @Test func recentlyViewedSites() async throws {
        let database = try await makeCatalogDatabase()
        // mark three sites as viewed (the app sets `lastViewed` when a site is opened)
        let allSites = try await database.fetch(FetchRequest(entity: Site.entityName, fetchLimit: 3))
        var viewed = [ObjectID]()
        for (index, siteData) in allSites.enumerated() {
            var data = siteData
            data.attributes[PropertyKey(Site.CodingKeys.lastViewed)] =
                .date(Date(timeIntervalSinceReferenceDate: Double(index) * 100))
            try await database.insert(data)
            viewed.append(data.id)
        }
        // lastViewed != nil, sorted most recent first, limited
        let request = FetchRequest(
            entity: Site.entityName,
            sortDescriptors: [
                .init(property: PropertyKey(Site.CodingKeys.lastViewed), ascending: false)
            ],
            predicate: Site.Query.lastViewed.predicate,
            fetchLimit: 10
        )
        let results = try await database.fetchID(request)
        #expect(results == viewed.reversed())
    }

    // MARK: - Reservations (Shower/ParkingReservationsViewModel, ShowerAPI)

    @Test func reservationsLoadCache() async throws {
        let database = try makeProfessionalDriverDatabase()
        // loadCache on an empty store returns no IDs (and must not throw)
        let showerIDs = try await database.fetchID(FetchRequest(entity: ShowerReservation.entityName))
        #expect(showerIDs.isEmpty)
        let parkingIDs = try await database.fetchID(FetchRequest(entity: ParkingReservation.entityName))
        #expect(parkingIDs.isEmpty)
    }

    @Test func staleShowerReservations() async throws {
        let database = try makeProfessionalDriverDatabase()
        // two reservations: one stale (61s old), one fresh
        let now = Date()
        for (id, created) in [("stale", now.addingTimeInterval(-61)), ("fresh", now)] {
            let reservation = ModelData(
                entity: ShowerReservation.entityName,
                id: ObjectID(rawValue: id),
                attributes: [
                    PropertyKey(ShowerReservation.CodingKeys.created): .date(created)
                ]
            )
            try await database.insert(reservation)
        }
        // the ShowerAPI cleanup: created < cutoff → fetch IDs → delete
        let cutoff = now.addingTimeInterval(-30)
        let predicate = ShowerReservation.CodingKeys.created
            .compare(.lessThan, .attribute(.date(cutoff)))
        let request = FetchRequest(entity: ShowerReservation.entityName, predicate: predicate)
        let expired = try await database.fetchID(request)
        #expect(expired == ["stale"])
        try await database.delete(ShowerReservation.entityName, for: expired)
        let remaining = try await database.fetchID(FetchRequest(entity: ShowerReservation.entityName))
        #expect(remaining == ["fresh"])
    }

    // MARK: - Cache refresh (MobileAPI, WalletAPI)

    @Test func staleCacheReplacement() async throws {
        let database = try await makeCatalogDatabase()
        // the app fetches all cached IDs, then deletes the ones the API no longer returns
        let allIDs = try await database.fetchID(FetchRequest(entity: Site.entityName))
        #expect(allIDs.count == 360)
        let keep = Set(allIDs.prefix(10))
        let stale = allIDs.filter { keep.contains($0) == false }
        try await database.delete(Site.entityName, for: stale)
        let remaining = try await database.fetchID(FetchRequest(entity: Site.entityName))
        #expect(Set(remaining) == keep)
    }
}
