import CloudKit
import Foundation

// MARK: - CloudKit Manager
// Private database: elk record is alleen zichtbaar voor de eigenaar (per iCloud account).
// Schema's worden automatisch aangemaakt in Development bij de eerste save.
// Record types: Klant · Arties · Shop — elk met een "userType" veld voor identificatie.

final class CloudKitManager {
    static let shared = CloudKitManager()

    private let db: CKDatabase

    private init() {
        db = CKContainer(identifier: "iCloud.info.cafferata.tattoe").privateCloudDatabase
    }

    // ─────────────────────────────────────────────
    // MARK: - Klant
    // ─────────────────────────────────────────────

    func saveKlant(_ klant: Klant, consentGegeven: Bool) async throws {
        let id     = CKRecord.ID(recordName: recordName("klant", klant.appleUserID, klant.email))
        let record = (try? await db.record(for: id)) ?? CKRecord(recordType: "Klant", recordID: id)

        record["userType"]       = "klant"
        record["authMethod"]     = klant.authMethod.rawValue
        record["appleUserID"]    = klant.appleUserID
        record["voornaam"]       = klant.voornaam
        record["achternaam"]     = klant.achternaam
        record["email"]          = klant.email
        record["wachtwoord"]     = klant.wachtwoord
        record["telefoon"]       = klant.telefoon
        record["straat"]         = klant.straat
        record["huisnummer"]     = klant.huisnummer
        record["postcode"]       = klant.postcode
        record["woonplaats"]     = klant.woonplaats
        record["consentGegeven"] = consentGegeven ? 1 : 0

        try await db.save(record)
    }

    // Zoekt op appleUserID (directe record ID lookup — geen query nodig)
    func fetchKlant(appleUserID: String) async -> (klant: Klant, consent: Bool)? {
        guard !appleUserID.isEmpty else { return nil }
        let id = CKRecord.ID(recordName: "klant_\(appleUserID)")
        guard let record = try? await db.record(for: id) else { return nil }
        return klantFromRecord(record)
    }

    // Zoekt op e-mailadres (vereist queryable index in CloudKit Dashboard voor productie)
    func fetchKlant(email: String) async -> (klant: Klant, consent: Bool)? {
        guard !email.isEmpty else { return nil }
        let pred  = NSPredicate(format: "email == %@", email.lowercased())
        let query = CKQuery(recordType: "Klant", predicate: pred)
        guard let results = try? await db.records(matching: query, resultsLimit: 1),
              let record  = try? results.matchResults.first?.1.get() else { return nil }
        return klantFromRecord(record)
    }

    private func klantFromRecord(_ r: CKRecord) -> (Klant, Bool)? {
        guard let am = AuthMethod(rawValue: r["authMethod"] as? String ?? "") else { return nil }
        let k = Klant(
            authMethod:  am,
            appleUserID: r["appleUserID"] as? String ?? "",
            voornaam:    r["voornaam"]    as? String ?? "",
            achternaam:  r["achternaam"]  as? String ?? "",
            email:       r["email"]       as? String ?? "",
            wachtwoord:  r["wachtwoord"]  as? String ?? "",
            telefoon:    r["telefoon"]    as? String ?? "",
            straat:      r["straat"]      as? String ?? "",
            huisnummer:  r["huisnummer"]  as? String ?? "",
            postcode:    r["postcode"]    as? String ?? "",
            woonplaats:  r["woonplaats"]  as? String ?? ""
        )
        let consent = (r["consentGegeven"] as? Int64 ?? 0) == 1
        return (k, consent)
    }

    // ─────────────────────────────────────────────
    // MARK: - Arties
    // ─────────────────────────────────────────────

    func saveArties(_ arties: Arties) async throws {
        let id     = CKRecord.ID(recordName: recordName("arties", arties.appleUserID, arties.email))
        let record = (try? await db.record(for: id)) ?? CKRecord(recordType: "Arties", recordID: id)

        record["userType"]      = "arties"
        record["authMethod"]    = arties.authMethod.rawValue
        record["appleUserID"]   = arties.appleUserID
        record["voornaam"]      = arties.voornaam
        record["achternaam"]    = arties.achternaam
        record["email"]         = arties.email
        record["wachtwoord"]    = arties.wachtwoord
        record["kunstnaam"]     = arties.kunstnaam
        record["specialisatie"] = arties.specialisatie
        record["telefoon"]      = arties.telefoon
        record["straat"]        = arties.straat
        record["huisnummer"]    = arties.huisnummer
        record["postcode"]      = arties.postcode
        record["woonplaats"]    = arties.woonplaats

        try await db.save(record)
    }

    func fetchArties(appleUserID: String) async -> Arties? {
        guard !appleUserID.isEmpty else { return nil }
        let id = CKRecord.ID(recordName: "arties_\(appleUserID)")
        guard let record = try? await db.record(for: id) else { return nil }
        return artiesFromRecord(record)
    }

    func fetchArties(email: String) async -> Arties? {
        guard !email.isEmpty else { return nil }
        let pred  = NSPredicate(format: "email == %@", email.lowercased())
        let query = CKQuery(recordType: "Arties", predicate: pred)
        guard let results = try? await db.records(matching: query, resultsLimit: 1),
              let record  = try? results.matchResults.first?.1.get() else { return nil }
        return artiesFromRecord(record)
    }

    private func artiesFromRecord(_ r: CKRecord) -> Arties? {
        guard let am = AuthMethod(rawValue: r["authMethod"] as? String ?? "") else { return nil }
        return Arties(
            authMethod:    am,
            appleUserID:   r["appleUserID"]   as? String ?? "",
            voornaam:      r["voornaam"]       as? String ?? "",
            achternaam:    r["achternaam"]     as? String ?? "",
            email:         r["email"]          as? String ?? "",
            wachtwoord:    r["wachtwoord"]     as? String ?? "",
            kunstnaam:     r["kunstnaam"]      as? String ?? "",
            specialisatie: r["specialisatie"]  as? String ?? "",
            telefoon:      r["telefoon"]       as? String ?? "",
            straat:        r["straat"]         as? String ?? "",
            huisnummer:    r["huisnummer"]     as? String ?? "",
            postcode:      r["postcode"]       as? String ?? "",
            woonplaats:    r["woonplaats"]     as? String ?? ""
        )
    }

    // ─────────────────────────────────────────────
    // MARK: - Shop
    // ─────────────────────────────────────────────

    func saveShop(_ shop: Shop) async throws {
        let id     = CKRecord.ID(recordName: recordName("shop", shop.appleUserID, shop.email))
        let record = (try? await db.record(for: id)) ?? CKRecord(recordType: "Shop", recordID: id)

        record["userType"]     = "shop"
        record["authMethod"]   = shop.authMethod.rawValue
        record["appleUserID"]  = shop.appleUserID
        record["bedrijfsnaam"] = shop.bedrijfsnaam
        record["kvk"]          = shop.kvk
        record["btw"]          = shop.btw
        record["voornaam"]     = shop.voornaam
        record["achternaam"]   = shop.achternaam
        record["email"]        = shop.email
        record["wachtwoord"]   = shop.wachtwoord
        record["telefoon"]     = shop.telefoon
        record["straat"]       = shop.straat
        record["huisnummer"]   = shop.huisnummer
        record["postcode"]     = shop.postcode
        record["woonplaats"]   = shop.woonplaats

        try await db.save(record)
    }

    func fetchShop(appleUserID: String) async -> Shop? {
        guard !appleUserID.isEmpty else { return nil }
        let id = CKRecord.ID(recordName: "shop_\(appleUserID)")
        guard let record = try? await db.record(for: id) else { return nil }
        return shopFromRecord(record)
    }

    func fetchShop(email: String) async -> Shop? {
        guard !email.isEmpty else { return nil }
        let pred  = NSPredicate(format: "email == %@", email.lowercased())
        let query = CKQuery(recordType: "Shop", predicate: pred)
        guard let results = try? await db.records(matching: query, resultsLimit: 1),
              let record  = try? results.matchResults.first?.1.get() else { return nil }
        return shopFromRecord(record)
    }

    private func shopFromRecord(_ r: CKRecord) -> Shop? {
        guard let am = AuthMethod(rawValue: r["authMethod"] as? String ?? "") else { return nil }
        return Shop(
            authMethod:   am,
            appleUserID:  r["appleUserID"]  as? String ?? "",
            bedrijfsnaam: r["bedrijfsnaam"] as? String ?? "",
            kvk:          r["kvk"]          as? String ?? "",
            btw:          r["btw"]          as? String ?? "",
            voornaam:     r["voornaam"]     as? String ?? "",
            achternaam:   r["achternaam"]   as? String ?? "",
            email:        r["email"]        as? String ?? "",
            wachtwoord:   r["wachtwoord"]   as? String ?? "",
            telefoon:     r["telefoon"]     as? String ?? "",
            straat:       r["straat"]       as? String ?? "",
            huisnummer:   r["huisnummer"]   as? String ?? "",
            postcode:     r["postcode"]     as? String ?? "",
            woonplaats:   r["woonplaats"]   as? String ?? ""
        )
    }

    // ─────────────────────────────────────────────
    // MARK: - Hulp
    // ─────────────────────────────────────────────

    private func recordName(_ prefix: String, _ appleID: String, _ email: String) -> String {
        if !appleID.isEmpty { return "\(prefix)_\(appleID)" }
        return "\(prefix)_email_\(email.lowercased())"
    }
}
