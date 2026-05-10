import Foundation
import Combine
import UserNotifications

enum AuthMethod: String, Codable { case apple, email }

// Publiek artiest-profiel (voor discovery via public DB)
struct ArtiestProfiel: Identifiable, Codable {
    var id:           String   // email als stabiele ID
    var kunstnaam:    String
    var specialisatie: String
    var woonplaats:   String
    var email:        String
    var shopEmail:    String = ""    // primaire shop (backward compat)
    var shopEmails:   [String] = [] // alle shops
    var bio:          String
    var stijlen:      [String]
    var instagram:    String
    var website:      String

    init(id: String, kunstnaam: String, specialisatie: String, woonplaats: String,
         email: String, shopEmail: String = "", shopEmails: [String] = [],
         bio: String, stijlen: [String], instagram: String, website: String) {
        self.id           = id
        self.kunstnaam    = kunstnaam
        self.specialisatie = specialisatie
        self.woonplaats   = woonplaats
        self.email        = email
        self.shopEmail    = shopEmail
        self.shopEmails   = shopEmails.isEmpty && !shopEmail.isEmpty ? [shopEmail] : shopEmails
        self.bio          = bio
        self.stijlen      = stijlen
        self.instagram    = instagram
        self.website      = website
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(String.self,    forKey: .id)
        kunstnaam    = try c.decode(String.self,    forKey: .kunstnaam)
        specialisatie = try c.decode(String.self,   forKey: .specialisatie)
        woonplaats   = try c.decode(String.self,    forKey: .woonplaats)
        email        = try c.decode(String.self,    forKey: .email)
        shopEmail    = (try? c.decodeIfPresent(String.self,   forKey: .shopEmail))  ?? ""
        shopEmails   = (try? c.decodeIfPresent([String].self, forKey: .shopEmails)) ?? []
        if shopEmails.isEmpty && !shopEmail.isEmpty { shopEmails = [shopEmail] }
        bio          = (try? c.decodeIfPresent(String.self,   forKey: .bio))        ?? ""
        stijlen      = (try? c.decodeIfPresent([String].self, forKey: .stijlen))    ?? []
        instagram    = (try? c.decodeIfPresent(String.self,   forKey: .instagram))  ?? ""
        website      = (try? c.decodeIfPresent(String.self,   forKey: .website))    ?? ""
    }
}

// Publiek shop-profiel (voor discovery via public DB)
struct ShopProfiel: Identifiable, Codable {
    var id:           String   // email als stabiele ID
    var bedrijfsnaam: String
    var woonplaats:   String
    var email:        String
}

struct Afspraak: Identifiable, Codable {
    var id:          String = UUID().uuidString
    var artiesEmail: String
    var shopEmail:   String = ""  // extra goed-te-keuren partij
    var klantEmail:  String
    var klantNaam:   String
    var datum:       Date
    var notitie:     String
    // statussen: aangevraagd → arties_akkoord/shop_akkoord → wacht_klant → bevestigd/geweigerd
    var status:      String
}

struct Bericht: Identifiable, Codable {
    var id:             String = UUID().uuidString
    var ontvangerEmail: String
    var ontvangerRol:   String   // "klant" | "arties" | "shop"
    var type:           String   // "aangevraagd" | "wacht_klant" | "bevestigd" | "geweigerd" | "arties_akkoord" | "shop_akkoord"
    var tekst:          String
    var afspraakId:     String
    var datum:          Date
}

struct Klant: Codable {
    var authMethod:  AuthMethod
    var appleUserID: String
    var voornaam:    String
    var achternaam:  String
    var email:       String
    var wachtwoord:  String
    var telefoon:    String
    var straat:      String
    var huisnummer:  String
    var postcode:    String
    var woonplaats:  String
}

@MainActor
class KlantStore: ObservableObject {
    @Published var klant:            Klant?
    @Published var isLoggedIn:       Bool = false
    @Published var consentGegeven:   Bool = false
    @Published var isCheckingCloud:  Bool = false
    @Published var favorietArties:   ArtiestProfiel? = nil
    @Published var favorietShop:     ShopProfiel?    = nil
    @Published var berichten:        [Bericht]       = []

    var ongelezen: Int { berichten.filter { !gelezenIds.contains($0.id) }.count }
    @Published var afsprakenaandacht: Int = 0
    var aandacht: Int { ongelezen + afsprakenaandacht }

    private let loginKey          = "klant_logged_in"
    private let dataKey           = "klant_data"
    private let consentKey        = "klant_consent"
    private let favArtiesKey      = "klant_fav_arties"
    private let favShopKey        = "klant_fav_shop"
    private let gelezenKey        = "klant_gelezen_berichten"
    private var syncTask:          Task<Void, Never>?
    private var gelezenIds:        Set<String> = []

    init() {
        isLoggedIn     = UserDefaults.standard.bool(forKey: loginKey)
        consentGegeven = UserDefaults.standard.bool(forKey: consentKey)
        if let data = UserDefaults.standard.data(forKey: dataKey) {
            klant = try? JSONDecoder().decode(Klant.self, from: data)
        }
        if let data = UserDefaults.standard.data(forKey: favArtiesKey) {
            favorietArties = try? JSONDecoder().decode(ArtiestProfiel.self, from: data)
        }
        if let data = UserDefaults.standard.data(forKey: favShopKey) {
            favorietShop = try? JSONDecoder().decode(ShopProfiel.self, from: data)
        }
        if let arr = UserDefaults.standard.array(forKey: gelezenKey) as? [String] {
            gelezenIds = Set(arr)
        }
        if isLoggedIn { startSync() }
        Task { await requestNotificationPermission() }
    }

    func markeerGelezen(_ id: String) {
        gelezenIds.insert(id)
        UserDefaults.standard.set(Array(gelezenIds), forKey: gelezenKey)
        updateBadge()
    }

    func bevestigAfspraak(_ afspraakId: String) async -> Afspraak? {
        guard let a = await CloudKitManager.shared.fetchAfspraak(id: afspraakId) else { return nil }
        await CloudKitManager.shared.updateAfspraakStatus(id: a.id, nieuwStatus: "bevestigd")
        let df = DateFormatter(); df.locale = Locale(identifier: "nl_NL"); df.dateFormat = "d MMM · HH:mm"
        let datumStr = df.string(from: a.datum)
        let tekst = "Klant heeft de afspraak op \(datumStr) bevestigd! De afspraak is definitief."
        if !a.artiesEmail.isEmpty {
            let b = Bericht(ontvangerEmail: a.artiesEmail, ontvangerRol: "arties",
                            type: "bevestigd", tekst: tekst, afspraakId: a.id, datum: Date())
            await CloudKitManager.shared.saveBericht(b)
        }
        if !a.shopEmail.isEmpty {
            let b = Bericht(ontvangerEmail: a.shopEmail, ontvangerRol: "shop",
                            type: "bevestigd", tekst: tekst, afspraakId: a.id, datum: Date())
            await CloudKitManager.shared.saveBericht(b)
        }
        await laadBerichten()
        return a
    }

    func annuleerAfspraak(afspraakId: String) async {
        guard let a = await CloudKitManager.shared.fetchAfspraak(id: afspraakId) else { return }
        await CloudKitManager.shared.updateAfspraakStatus(id: a.id, nieuwStatus: "geannuleerd")
        let df = DateFormatter(); df.locale = Locale(identifier: "nl_NL"); df.dateFormat = "d MMM · HH:mm"
        let naam = klant.map { "\($0.voornaam) \($0.achternaam)".trimmingCharacters(in: .whitespaces) } ?? ""
        let tekst = "\(naam.isEmpty ? klant?.email ?? "" : naam) heeft de afspraak op \(df.string(from: a.datum)) afgezegd."
        if !a.artiesEmail.isEmpty {
            let b = Bericht(ontvangerEmail: a.artiesEmail, ontvangerRol: "arties",
                            type: "geannuleerd", tekst: tekst, afspraakId: a.id, datum: Date())
            await CloudKitManager.shared.saveBericht(b)
        }
        if !a.shopEmail.isEmpty {
            let b = Bericht(ontvangerEmail: a.shopEmail, ontvangerRol: "shop",
                            type: "geannuleerd", tekst: tekst, afspraakId: a.id, datum: Date())
            await CloudKitManager.shared.saveBericht(b)
        }
        EventKitManager.shared.verwijder(afspraakId: afspraakId)
        await laadBerichten()
    }

    // Lokaal opslaan + CloudKit sync op achtergrond
    func save(_ klant: Klant) {
        self.klant      = klant
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(klant) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        Task { try? await CloudKitManager.shared.saveKlant(klant, consentGegeven: consentGegeven) }
    }

    #if DEBUG
    func saveLocal(_ klant: Klant) {
        self.klant      = klant
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(klant) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        startSync()
    }
    #endif

    func saveConsent() {
        consentGegeven = true
        UserDefaults.standard.set(true, forKey: consentKey)
        if let klant { Task { try? await CloudKitManager.shared.saveKlant(klant, consentGegeven: true) } }
    }

    func slaFavorietArties(_ profiel: ArtiestProfiel) {
        favorietArties = profiel
        if let data = try? JSONEncoder().encode(profiel) {
            UserDefaults.standard.set(data, forKey: favArtiesKey)
        }
        if let klant {
            Task { await CloudKitManager.shared.saveFavorietArties(klant: klant, artiesEmail: profiel.email) }
        }
    }

    func slaFavorietShop(_ profiel: ShopProfiel) {
        favorietShop = profiel
        if let data = try? JSONEncoder().encode(profiel) {
            UserDefaults.standard.set(data, forKey: favShopKey)
        }
        if let klant {
            Task { await CloudKitManager.shared.saveFavorietShop(klant: klant, shopEmail: profiel.email) }
        }
    }

    // Controleert CloudKit op bestaand account bij Apple login
    func checkCloud(appleUserID: String) async {
        isCheckingCloud = true
        defer { isCheckingCloud = false }
        guard let result = await CloudKitManager.shared.fetchKlant(appleUserID: appleUserID) else { return }
        klant          = result.klant
        consentGegeven = result.consent
        isLoggedIn     = true
        UserDefaults.standard.set(true, forKey: loginKey)
        UserDefaults.standard.set(result.consent, forKey: consentKey)
        if let data = try? JSONEncoder().encode(result.klant) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        // Herstel favorieten uit CloudKit
        if let artiesEmail = result.favorietArtiesEmail, !artiesEmail.isEmpty {
            if let profiel = await CloudKitManager.shared.fetchPubliekArties(email: artiesEmail) {
                favorietArties = profiel
                if let data = try? JSONEncoder().encode(profiel) {
                    UserDefaults.standard.set(data, forKey: favArtiesKey)
                }
            }
        }
        if let shopEmail = result.favorietShopEmail, !shopEmail.isEmpty {
            if let profiel = await CloudKitManager.shared.fetchPubliekShop(email: shopEmail) {
                favorietShop = profiel
                if let data = try? JSONEncoder().encode(profiel) {
                    UserDefaults.standard.set(data, forKey: favShopKey)
                }
            }
        }
        startSync()
    }

    func inloggen(email: String, wachtwoord: String) async -> String? {
        isCheckingCloud = true
        defer { isCheckingCloud = false }
        guard let result = await CloudKitManager.shared.fetchKlant(email: email) else {
            return "Geen account gevonden met dit e-mailadres."
        }
        guard result.klant.wachtwoord == wachtwoord else {
            return "Wachtwoord klopt niet."
        }
        klant          = result.klant
        consentGegeven = result.consent
        isLoggedIn     = true
        UserDefaults.standard.set(true, forKey: loginKey)
        UserDefaults.standard.set(result.consent, forKey: consentKey)
        if let data = try? JSONEncoder().encode(result.klant) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        // Herstel favorieten
        if let artiesEmail = result.favorietArtiesEmail, !artiesEmail.isEmpty {
            if let profiel = await CloudKitManager.shared.fetchPubliekArties(email: artiesEmail) {
                favorietArties = profiel
                if let data = try? JSONEncoder().encode(profiel) {
                    UserDefaults.standard.set(data, forKey: favArtiesKey)
                }
            }
        }
        if let shopEmail = result.favorietShopEmail, !shopEmail.isEmpty {
            if let profiel = await CloudKitManager.shared.fetchPubliekShop(email: shopEmail) {
                favorietShop = profiel
                if let data = try? JSONEncoder().encode(profiel) {
                    UserDefaults.standard.set(data, forKey: favShopKey)
                }
            }
        }
        startSync()
        return nil
    }

    func verwijderAccount() async {
        if let k = klant { await CloudKitManager.shared.verwijderKlant(k) }
        logout()
    }

    func logout() {
        stopSync()
        klant          = nil
        isLoggedIn     = false
        consentGegeven = false
        favorietArties = nil
        favorietShop   = nil
        berichten      = []
        UserDefaults.standard.removeObject(forKey: loginKey)
        UserDefaults.standard.removeObject(forKey: dataKey)
        UserDefaults.standard.removeObject(forKey: consentKey)
        UserDefaults.standard.removeObject(forKey: favArtiesKey)
        UserDefaults.standard.removeObject(forKey: favShopKey)
        updateBadge()
    }

    // MARK: - Achtergrond sync elke 10 minuten

    private func startSync() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            await self?.syncVanCloud()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 600_000_000_000) // 10 min
                guard !Task.isCancelled else { break }
                await self?.syncVanCloud()
            }
        }
    }

    private func stopSync() {
        syncTask?.cancel()
        syncTask = nil
    }

    private func syncVanCloud() async {
        guard isLoggedIn else { return }
        if let email = favorietShop?.email,
           let profiel = await CloudKitManager.shared.fetchPubliekShop(email: email) {
            favorietShop = profiel
            if let data = try? JSONEncoder().encode(profiel) {
                UserDefaults.standard.set(data, forKey: favShopKey)
            }
        }
        if let email = favorietArties?.email,
           let profiel = await CloudKitManager.shared.fetchPubliekArties(email: email) {
            favorietArties = profiel
            if let data = try? JSONEncoder().encode(profiel) {
                UserDefaults.standard.set(data, forKey: favArtiesKey)
            }
        }
        await laadBerichten()
    }

    private func laadBerichten() async {
        guard let email = klant?.email, !email.isEmpty else { return }
        berichten = await CloudKitManager.shared.fetchBerichten(email: email)
        #if DEBUG
        let bestaandeIds = Set(berichten.map { $0.id })
        let extra = TestData.berichtenKlant.filter { !bestaandeIds.contains($0.id) }
        berichten = (extra + berichten).sorted { $0.datum > $1.datum }
        #endif
        await laadAfsprakenaandacht()
        updateBadge()
    }

    private func laadAfsprakenaandacht() async {
        guard let email = klant?.email, !email.isEmpty else { return }
        let alle = await CloudKitManager.shared.fetchAfspraken(klantEmail: email)
        afsprakenaandacht = alle.filter { $0.status == "wacht_klant" }.count
    }

    private func updateBadge() {
        let n = aandacht
        Task { try? await UNUserNotificationCenter.current().setBadgeCount(n) }
    }

    private func requestNotificationPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.badge])
    }
}
