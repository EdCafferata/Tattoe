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
        record["shopEmail"]     = arties.shopEmails.first ?? ""   // primaire shop (voor compat)
        record["shopEmails"]    = arties.shopEmails as NSArray
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
        // Backward compat: old records have shopEmail (String), new have shopEmails ([String])
        let shopEmails: [String] = {
            if let arr = r["shopEmails"] as? [String], !arr.isEmpty { return arr }
            let old = r["shopEmail"] as? String ?? ""
            return old.isEmpty ? [] : [old]
        }()
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
            shopEmails:    shopEmails,
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
    // MARK: - Arties foto's (private DB, CKAsset)
    // ─────────────────────────────────────────────

    func saveArtiestFotos(arties: Arties, profiel: Data?, portfolio: [Data?], voorbeelden: [Data?]) async {
        let id = CKRecord.ID(recordName: recordName("arties", arties.appleUserID, arties.email))
        guard let record = try? await db.record(for: id) else { return }

        let tmp = FileManager.default.temporaryDirectory

        if let data = profiel {
            let url = tmp.appendingPathComponent("profiel_\(arties.email).jpg")
            if (try? data.write(to: url)) != nil { record["profielFoto"] = CKAsset(fileURL: url) }
        }

        for i in 0..<9 {
            if let data = portfolio[i] {
                let url = tmp.appendingPathComponent("portf_\(arties.email)_\(i).jpg")
                if (try? data.write(to: url)) != nil { record["portf\(i)"] = CKAsset(fileURL: url) }
            } else {
                record["portf\(i)"] = nil as CKRecordValueProtocol?
            }
            if let data = voorbeelden[i] {
                let url = tmp.appendingPathComponent("voorb_\(arties.email)_\(i).jpg")
                if (try? data.write(to: url)) != nil { record["voorb\(i)"] = CKAsset(fileURL: url) }
            } else {
                record["voorb\(i)"] = nil as CKRecordValueProtocol?
            }
        }

        try? await db.save(record)
    }

    func fetchArtiestFotos(arties: Arties) async -> (profiel: Data?, portfolio: [Data?], voorbeelden: [Data?]) {
        let id = CKRecord.ID(recordName: recordName("arties", arties.appleUserID, arties.email))
        guard let record = try? await db.record(for: id) else {
            return (nil, Array(repeating: nil, count: 9), Array(repeating: nil, count: 9))
        }

        let profiel: Data? = (record["profielFoto"] as? CKAsset).flatMap {
            guard let url = $0.fileURL else { return nil }
            return try? Data(contentsOf: url)
        }

        let portfolio: [Data?] = (0..<9).map { i in
            guard let asset = record["portf\(i)"] as? CKAsset, let url = asset.fileURL else { return nil }
            return try? Data(contentsOf: url)
        }

        let voorbeelden: [Data?] = (0..<9).map { i in
            guard let asset = record["voorb\(i)"] as? CKAsset, let url = asset.fileURL else { return nil }
            return try? Data(contentsOf: url)
        }

        return (profiel, portfolio, voorbeelden)
    }

    // ─────────────────────────────────────────────
    // MARK: - Shop (private DB)
    // ─────────────────────────────────────────────

    func saveShop(_ shop: Shop) async throws {
        let id     = CKRecord.ID(recordName: recordName("shop", shop.appleUserID, shop.email))
        let record = (try? await db.record(for: id)) ?? CKRecord(recordType: "Shop", recordID: id)

        record["userType"]        = "shop"
        record["authMethod"]      = shop.authMethod.rawValue
        record["appleUserID"]     = shop.appleUserID
        record["bedrijfsnaam"]    = shop.bedrijfsnaam
        record["kvk"]             = shop.kvk
        record["btw"]             = shop.btw
        record["voornaam"]        = shop.voornaam
        record["achternaam"]      = shop.achternaam
        record["email"]           = shop.email
        record["wachtwoord"]      = shop.wachtwoord
        record["telefoon"]        = shop.telefoon
        record["straat"]          = shop.straat
        record["huisnummer"]      = shop.huisnummer
        record["postcode"]        = shop.postcode
        record["woonplaats"]      = shop.woonplaats
        record["registratieDatum"] = shop.registratieDatum as NSDate
        record["abonnementType"]   = shop.abonnementType
        record["abonnementActief"] = shop.abonnementActief ? 1 : 0

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
            authMethod:       am,
            appleUserID:      r["appleUserID"]       as? String ?? "",
            bedrijfsnaam:     r["bedrijfsnaam"]      as? String ?? "",
            kvk:              r["kvk"]               as? String ?? "",
            btw:              r["btw"]               as? String ?? "",
            voornaam:         r["voornaam"]          as? String ?? "",
            achternaam:       r["achternaam"]        as? String ?? "",
            email:            r["email"]             as? String ?? "",
            wachtwoord:       r["wachtwoord"]        as? String ?? "",
            telefoon:         r["telefoon"]          as? String ?? "",
            straat:           r["straat"]            as? String ?? "",
            huisnummer:       r["huisnummer"]        as? String ?? "",
            postcode:         r["postcode"]          as? String ?? "",
            woonplaats:       r["woonplaats"]        as? String ?? "",
            registratieDatum: r["registratieDatum"]  as? Date   ?? Date(),
            abonnementType:   r["abonnementType"]    as? String ?? "",
            abonnementActief: (r["abonnementActief"] as? Int64 ?? 0) == 1
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
        record["shopEmail"]     = arties.shopEmails.first ?? ""   // primaire shop (voor compat)
        record["shopEmails"]    = arties.shopEmails as NSArray
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
        // Haal alle artiesten op en filter client-side op shopEmails array
        // (CloudKit ondersteunt geen CONTAINS-query op list fields voor public DB)
        let alle = await fetchPubliekeArtiesten()
        return alle.filter { $0.shopEmails.contains(shopEmail.lowercased()) || $0.shopEmail == shopEmail.lowercased() }
    }

    func fetchPubliekArties(email: String) async -> ArtiestProfiel? {
        guard !email.isEmpty else { return nil }
        let id = CKRecord.ID(recordName: "artiestprofiel_\(email.lowercased())")
        guard let record = try? await publicDb.record(for: id) else { return nil }
        return artiestProfielFromRecord(record)
    }

    private func artiestProfielFromRecord(_ r: CKRecord) -> ArtiestProfiel? {
        guard let email = r["email"] as? String else { return nil }
        let shopEmails: [String] = {
            if let arr = r["shopEmails"] as? [String], !arr.isEmpty { return arr }
            let old = r["shopEmail"] as? String ?? ""
            return old.isEmpty ? [] : [old]
        }()
        return ArtiestProfiel(
            id:            email,
            kunstnaam:     r["kunstnaam"]     as? String ?? "",
            specialisatie: r["specialisatie"] as? String ?? "",
            woonplaats:    r["woonplaats"]    as? String ?? "",
            email:         email,
            shopEmail:     shopEmails.first ?? "",
            shopEmails:    shopEmails,
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
    // MARK: - Afspraken (public DB)
    // ─────────────────────────────────────────────

    func saveAfspraak(_ afspraak: Afspraak) async {
        let id     = CKRecord.ID(recordName: "afspraak_\(afspraak.id)")
        let record = (try? await publicDb.record(for: id)) ?? CKRecord(recordType: "Afspraak", recordID: id)
        record["artiesEmail"] = afspraak.artiesEmail.lowercased()
        record["shopEmail"]   = afspraak.shopEmail.lowercased()
        record["klantEmail"]  = afspraak.klantEmail.lowercased()
        record["klantNaam"]   = afspraak.klantNaam
        record["datum"]       = afspraak.datum as NSDate
        record["notitie"]     = afspraak.notitie
        record["status"]      = afspraak.status
        try? await publicDb.save(record)
    }

    func updateAfspraakStatus(id: String, nieuwStatus: String) async {
        let ckId   = CKRecord.ID(recordName: "afspraak_\(id)")
        guard let record = try? await publicDb.record(for: ckId) else { return }
        record["status"] = nieuwStatus
        try? await publicDb.save(record)
    }

    func fetchAfspraak(id: String) async -> Afspraak? {
        let ckId = CKRecord.ID(recordName: "afspraak_\(id)")
        guard let record = try? await publicDb.record(for: ckId) else { return nil }
        return afspraakFromRecord(record)
    }

    func fetchAfspraken(artiesEmail: String) async -> [Afspraak] {
        guard !artiesEmail.isEmpty else { return [] }
        let pred  = NSPredicate(format: "artiesEmail == %@", artiesEmail.lowercased())
        let query = CKQuery(recordType: "Afspraak", predicate: pred)
        query.sortDescriptors = [NSSortDescriptor(key: "datum", ascending: true)]
        guard let results = try? await publicDb.records(matching: query) else { return [] }
        return results.matchResults.compactMap { try? $0.1.get() }.compactMap { afspraakFromRecord($0) }
    }

    func fetchAfspraken(shopEmail: String) async -> [Afspraak] {
        guard !shopEmail.isEmpty else { return [] }
        let pred  = NSPredicate(format: "shopEmail == %@", shopEmail.lowercased())
        let query = CKQuery(recordType: "Afspraak", predicate: pred)
        query.sortDescriptors = [NSSortDescriptor(key: "datum", ascending: true)]
        guard let results = try? await publicDb.records(matching: query) else { return [] }
        return results.matchResults.compactMap { try? $0.1.get() }.compactMap { afspraakFromRecord($0) }
    }

    func fetchAfspraken(klantEmail: String) async -> [Afspraak] {
        guard !klantEmail.isEmpty else { return [] }
        let pred  = NSPredicate(format: "klantEmail == %@", klantEmail.lowercased())
        let query = CKQuery(recordType: "Afspraak", predicate: pred)
        query.sortDescriptors = [NSSortDescriptor(key: "datum", ascending: false)]
        guard let results = try? await publicDb.records(matching: query) else { return [] }
        return results.matchResults.compactMap { try? $0.1.get() }.compactMap { afspraakFromRecord($0) }
    }

    private func afspraakFromRecord(_ r: CKRecord) -> Afspraak? {
        guard let artiesEmail = r["artiesEmail"] as? String,
              let datum       = r["datum"]       as? Date else { return nil }
        let id = r.recordID.recordName.replacingOccurrences(of: "afspraak_", with: "")
        return Afspraak(
            id:          id,
            artiesEmail: artiesEmail,
            shopEmail:   r["shopEmail"]   as? String ?? "",
            klantEmail:  r["klantEmail"]  as? String ?? "",
            klantNaam:   r["klantNaam"]   as? String ?? "",
            datum:       datum,
            notitie:     r["notitie"]     as? String ?? "",
            status:      r["status"]      as? String ?? "aangevraagd"
        )
    }

    // ─────────────────────────────────────────────
    // MARK: - Berichten (public DB)
    // ─────────────────────────────────────────────

    func saveBericht(_ bericht: Bericht) async {
        let ckId   = CKRecord.ID(recordName: "bericht_\(bericht.id)")
        let record = CKRecord(recordType: "Bericht", recordID: ckId)
        record["ontvangerEmail"] = bericht.ontvangerEmail.lowercased()
        record["ontvangerRol"]   = bericht.ontvangerRol
        record["type"]           = bericht.type
        record["tekst"]          = bericht.tekst
        record["afspraakId"]     = bericht.afspraakId
        record["datum"]          = bericht.datum as NSDate
        try? await publicDb.save(record)
    }

    func fetchBerichten(email: String) async -> [Bericht] {
        guard !email.isEmpty else { return [] }
        let pred  = NSPredicate(format: "ontvangerEmail == %@", email.lowercased())
        let query = CKQuery(recordType: "Bericht", predicate: pred)
        query.sortDescriptors = [NSSortDescriptor(key: "datum", ascending: false)]
        guard let results = try? await publicDb.records(matching: query) else { return [] }
        return results.matchResults.compactMap { try? $0.1.get() }.compactMap { berichtFromRecord($0) }
    }

    private func berichtFromRecord(_ r: CKRecord) -> Bericht? {
        guard let email = r["ontvangerEmail"] as? String,
              let type  = r["type"]           as? String,
              let tekst = r["tekst"]          as? String,
              let datum = r["datum"]          as? Date else { return nil }
        let id = r.recordID.recordName.replacingOccurrences(of: "bericht_", with: "")
        return Bericht(
            id:             id,
            ontvangerEmail: email,
            ontvangerRol:   r["ontvangerRol"] as? String ?? "",
            type:           type,
            tekst:          tekst,
            afspraakId:     r["afspraakId"]   as? String ?? "",
            datum:          datum
        )
    }

    // Stuur berichten naar alle betrokken partijen bij een statuswijziging
    func stuurAfspraakBerichten(afspraak: Afspraak, type: String, tekst: String,
                                 naar: [String], rol: String) async {
        for email in naar where !email.isEmpty {
            let b = Bericht(
                ontvangerEmail: email,
                ontvangerRol:   rol,
                type:           type,
                tekst:          tekst,
                afspraakId:     afspraak.id,
                datum:          Date()
            )
            await saveBericht(b)
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Wachtwoord reset
    // ─────────────────────────────────────────────

    enum ResetRolType { case klant, arties, shop }

    // Sla een 6-cijferige code + vervaltijd op het account record op
    func slaResetCodeOp(rol: ResetRolType, email: String, code: String) async -> Bool {
        let recordType: String
        switch rol {
        case .klant:  recordType = "Klant"
        case .arties: recordType = "Arties"
        case .shop:   recordType = "Shop"
        }
        let pred  = NSPredicate(format: "email == %@", email.lowercased())
        let query = CKQuery(recordType: recordType, predicate: pred)
        guard let results = try? await db.records(matching: query, resultsLimit: 1),
              let record  = try? results.matchResults.first?.1.get() else { return false }
        record["resetCode"]   = code
        record["resetExpiry"] = Date().addingTimeInterval(15 * 60) as NSDate
        return (try? await db.save(record)) != nil
    }

    // Valideer code en update wachtwoord; geeft foutmelding terug of nil bij succes
    func resetWachtwoord(rol: ResetRolType, email: String, code: String, nieuwWachtwoord: String) async -> String? {
        let recordType: String
        switch rol {
        case .klant:  recordType = "Klant"
        case .arties: recordType = "Arties"
        case .shop:   recordType = "Shop"
        }
        let pred  = NSPredicate(format: "email == %@", email.lowercased())
        let query = CKQuery(recordType: recordType, predicate: pred)
        guard let results = try? await db.records(matching: query, resultsLimit: 1),
              let record  = try? results.matchResults.first?.1.get() else {
            return "Geen account gevonden."
        }
        guard let opgeslagen = record["resetCode"] as? String, opgeslagen == code else {
            return "De code klopt niet."
        }
        guard let expiry = record["resetExpiry"] as? Date, expiry > Date() else {
            return "De code is verlopen. Vraag een nieuwe aan."
        }
        record["wachtwoord"]  = nieuwWachtwoord
        record["resetCode"]   = nil as CKRecordValueProtocol?
        record["resetExpiry"] = nil as CKRecordValueProtocol?
        guard (try? await db.save(record)) != nil else {
            return "Opslaan mislukt. Probeer opnieuw."
        }
        return nil
    }

    // ─────────────────────────────────────────────
    // MARK: - Account verwijderen (AVG/GDPR)
    // ─────────────────────────────────────────────

    func verwijderKlant(_ klant: Klant) async {
        let id = CKRecord.ID(recordName: recordName("klant", klant.appleUserID, klant.email))
        try? await db.deleteRecord(withID: id)
    }

    func verwijderArties(_ arties: Arties) async {
        let privID = CKRecord.ID(recordName: recordName("arties", arties.appleUserID, arties.email))
        let pubID  = CKRecord.ID(recordName: "artiestprofiel_\(arties.email.lowercased())")
        try? await db.deleteRecord(withID: privID)
        try? await publicDb.deleteRecord(withID: pubID)
    }

    func verwijderShop(_ shop: Shop) async {
        let privID = CKRecord.ID(recordName: recordName("shop", shop.appleUserID, shop.email))
        let pubID  = CKRecord.ID(recordName: "shopprofiel_\(shop.email.lowercased())")
        try? await db.deleteRecord(withID: privID)
        try? await publicDb.deleteRecord(withID: pubID)
    }

    // ─────────────────────────────────────────────
    // MARK: - Hulp
    // ─────────────────────────────────────────────

    private func recordName(_ prefix: String, _ appleID: String, _ email: String) -> String {
        if !appleID.isEmpty { return "\(prefix)_\(appleID)" }
        return "\(prefix)_email_\(email.lowercased())"
    }
}
