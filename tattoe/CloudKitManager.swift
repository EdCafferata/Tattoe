import CloudKit
import Foundation

// MARK: - CloudKit Manager
// Private database: persoonlijke Klant/Arties/Shop records (alleen zichtbaar voor eigenaar).
// Public database:  publieke profielen voor discovery (ArtiestProfiel, ShopProfiel).
// Schema's worden automatisch aangemaakt in Development bij de eerste save.

final class CloudKitManager {
    static let shared = CloudKitManager()

    private let db:       CKDatabase  // private
    private let publicDb: CKDatabase  // public

    private init() {
        let container = CKContainer(identifier: "iCloud.info.cafferata.tattoe")
        db       = container.privateCloudDatabase
        publicDb = container.publicCloudDatabase
    }

    // ─────────────────────────────────────────────
    // MARK: - Klant (private DB)
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

    // Zoekt op appleUserID (directe record ID lookup)
    func fetchKlant(appleUserID: String) async -> (klant: Klant, consent: Bool, favorietArtiesEmail: String?, favorietShopEmail: String?)? {
        guard !appleUserID.isEmpty else { return nil }
        let id = CKRecord.ID(recordName: "klant_\(appleUserID)")
        guard let record = try? await db.record(for: id) else { return nil }
        return klantFromRecord(record)
    }

    // Zoekt op e-mailadres
    func fetchKlant(email: String) async -> (klant: Klant, consent: Bool, favorietArtiesEmail: String?, favorietShopEmail: String?)? {
        guard !email.isEmpty else { return nil }
        let pred  = NSPredicate(format: "email == %@", email.lowercased())
        let query = CKQuery(recordType: "Klant", predicate: pred)
        guard let results = try? await db.records(matching: query, resultsLimit: 1),
              let record  = try? results.matchResults.first?.1.get() else { return nil }
        return klantFromRecord(record)
    }

    func saveFavorietArties(klant: Klant, artiesEmail: String) async {
        let id = CKRecord.ID(recordName: recordName("klant", klant.appleUserID, klant.email))
        guard let record = try? await db.record(for: id) else { return }
        record["favorietArtiesEmail"] = artiesEmail
        try? await db.save(record)
    }

    func saveFavorietShop(klant: Klant, shopEmail: String) async {
        let id = CKRecord.ID(recordName: recordName("klant", klant.appleUserID, klant.email))
        guard let record = try? await db.record(for: id) else { return }
        record["favorietShopEmail"] = shopEmail
        try? await db.save(record)
    }

    private func klantFromRecord(_ r: CKRecord) -> (Klant, Bool, String?, String?)? {
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
        let consent           = (r["consentGegeven"] as? Int64 ?? 0) == 1
        let favorietArties    = r["favorietArtiesEmail"] as? String
        let favorietShop      = r["favorietShopEmail"]   as? String
        return (k, consent, favorietArties, favorietShop)
    }

    // ─────────────────────────────────────────────
    // MARK: - Arties (private DB)
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
        record["shopEmail"]     = arties.shopEmail
        record["bio"]           = arties.bio
        record["stijlen"]       = arties.stijlen as NSArray
        record["jarenervaring"] = arties.jarenervaring
        record["instagram"]     = arties.instagram
        record["facebook"]      = arties.facebook
        record["pinterest"]     = arties.pinterest
        record["tiktok"]        = arties.tiktok
        record["website"]       = arties.website

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
            woonplaats:    r["woonplaats"]     as? String ?? "",
            shopEmail:     r["shopEmail"]      as? String ?? "",
            bio:           r["bio"]            as? String ?? "",
            stijlen:       r["stijlen"]        as? [String] ?? [],
            jarenervaring: r["jarenervaring"]  as? Int ?? 0,
            instagram:     r["instagram"]      as? String ?? "",
            facebook:      r["facebook"]       as? String ?? "",
            pinterest:     r["pinterest"]      as? String ?? "",
            tiktok:        r["tiktok"]         as? String ?? "",
            website:       r["website"]        as? String ?? ""
        )
    }

    // ─────────────────────────────────────────────
    // MARK: - Shop (private DB)
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
    // MARK: - ArtiestProfiel (public DB)
    // ─────────────────────────────────────────────

    func savePubliekArties(_ arties: Arties) async {
        guard !arties.email.isEmpty else { return }
        let id     = CKRecord.ID(recordName: "artiestprofiel_\(arties.email.lowercased())")
        let record = (try? await publicDb.record(for: id)) ?? CKRecord(recordType: "ArtiestProfiel", recordID: id)

        record["kunstnaam"]     = arties.kunstnaam
        record["specialisatie"] = arties.specialisatie
        record["woonplaats"]    = arties.woonplaats
        record["email"]         = arties.email.lowercased()
        record["shopEmail"]     = arties.shopEmail
        record["bio"]           = arties.bio
        record["stijlen"]       = arties.stijlen as NSArray
        record["instagram"]     = arties.instagram
        record["website"]       = arties.website

        try? await publicDb.save(record)
    }

    func fetchPubliekeArtiesten() async -> [ArtiestProfiel] {
        let pred  = NSPredicate(value: true)
        let query = CKQuery(recordType: "ArtiestProfiel", predicate: pred)
        guard let results = try? await publicDb.records(matching: query) else { return [] }
        return results.matchResults.compactMap { try? $0.1.get() }.compactMap { artiestProfielFromRecord($0) }
    }

    func fetchArtiesten(voorShop shopEmail: String) async -> [ArtiestProfiel] {
        guard !shopEmail.isEmpty else { return [] }
        let pred  = NSPredicate(format: "shopEmail == %@", shopEmail.lowercased())
        let query = CKQuery(recordType: "ArtiestProfiel", predicate: pred)
        guard let results = try? await publicDb.records(matching: query) else { return [] }
        return results.matchResults.compactMap { try? $0.1.get() }.compactMap { artiestProfielFromRecord($0) }
    }

    func fetchPubliekArties(email: String) async -> ArtiestProfiel? {
        guard !email.isEmpty else { return nil }
        let id = CKRecord.ID(recordName: "artiestprofiel_\(email.lowercased())")
        guard let record = try? await publicDb.record(for: id) else { return nil }
        return artiestProfielFromRecord(record)
    }

    private func artiestProfielFromRecord(_ r: CKRecord) -> ArtiestProfiel? {
        guard let email = r["email"] as? String else { return nil }
        return ArtiestProfiel(
            id:            email,
            kunstnaam:     r["kunstnaam"]     as? String ?? "",
            specialisatie: r["specialisatie"] as? String ?? "",
            woonplaats:    r["woonplaats"]    as? String ?? "",
            email:         email,
            shopEmail:     r["shopEmail"]     as? String ?? "",
            bio:           r["bio"]           as? String ?? "",
            stijlen:       r["stijlen"]       as? [String] ?? [],
            instagram:     r["instagram"]     as? String ?? "",
            website:       r["website"]       as? String ?? ""
        )
    }

    // ─────────────────────────────────────────────
    // MARK: - ShopProfiel (public DB)
    // ─────────────────────────────────────────────

    func savePubliekShop(_ shop: Shop) async {
        guard !shop.email.isEmpty else { return }
        let id     = CKRecord.ID(recordName: "shopprofiel_\(shop.email.lowercased())")
        let record = (try? await publicDb.record(for: id)) ?? CKRecord(recordType: "ShopProfiel", recordID: id)

        record["bedrijfsnaam"] = shop.bedrijfsnaam
        record["woonplaats"]   = shop.woonplaats
        record["email"]        = shop.email.lowercased()

        try? await publicDb.save(record)
    }

    func fetchPubliekeShops() async -> [ShopProfiel] {
        let pred  = NSPredicate(value: true)
        let query = CKQuery(recordType: "ShopProfiel", predicate: pred)
        guard let results = try? await publicDb.records(matching: query) else { return [] }
        return results.matchResults.compactMap { try? $0.1.get() }.compactMap { shopProfielFromRecord($0) }
    }

    func fetchPubliekShop(email: String) async -> ShopProfiel? {
        guard !email.isEmpty else { return nil }
        let id = CKRecord.ID(recordName: "shopprofiel_\(email.lowercased())")
        guard let record = try? await publicDb.record(for: id) else { return nil }
        return shopProfielFromRecord(record)
    }

    private func shopProfielFromRecord(_ r: CKRecord) -> ShopProfiel? {
        guard let email = r["email"] as? String else { return nil }
        return ShopProfiel(
            id:           email,
            bedrijfsnaam: r["bedrijfsnaam"] as? String ?? "",
            woonplaats:   r["woonplaats"]   as? String ?? "",
            email:        email
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
