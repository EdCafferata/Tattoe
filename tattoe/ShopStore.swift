import Foundation
import Combine
import UserNotifications

struct Shop: Codable {
    var authMethod:       AuthMethod
    var appleUserID:      String
    var bedrijfsnaam:     String
    var kvk:              String
    var btw:              String
    var voornaam:         String
    var achternaam:       String
    var email:            String
    var wachtwoord:       String
    var telefoon:         String
    var straat:           String
    var huisnummer:       String
    var postcode:         String
    var woonplaats:       String
    var registratieDatum: Date   = Date()
    var abonnementType:   String = ""     // "starter" | "studio" | "pro" | "enterprise"
    var abonnementActief: Bool   = false  // true = betaald (na trial)

    init(authMethod: AuthMethod, appleUserID: String, bedrijfsnaam: String, kvk: String, btw: String,
         voornaam: String, achternaam: String, email: String, wachtwoord: String, telefoon: String,
         straat: String, huisnummer: String, postcode: String, woonplaats: String,
         registratieDatum: Date = Date(), abonnementType: String = "", abonnementActief: Bool = false) {
        self.authMethod       = authMethod
        self.appleUserID      = appleUserID
        self.bedrijfsnaam     = bedrijfsnaam
        self.kvk              = kvk
        self.btw              = btw
        self.voornaam         = voornaam
        self.achternaam       = achternaam
        self.email            = email
        self.wachtwoord       = wachtwoord
        self.telefoon         = telefoon
        self.straat           = straat
        self.huisnummer       = huisnummer
        self.postcode         = postcode
        self.woonplaats       = woonplaats
        self.registratieDatum = registratieDatum
        self.abonnementType   = abonnementType
        self.abonnementActief = abonnementActief
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        authMethod       = try c.decode(AuthMethod.self, forKey: .authMethod)
        appleUserID      = try c.decode(String.self,     forKey: .appleUserID)
        bedrijfsnaam     = try c.decode(String.self,     forKey: .bedrijfsnaam)
        kvk              = try c.decode(String.self,     forKey: .kvk)
        btw              = try c.decode(String.self,     forKey: .btw)
        voornaam         = try c.decode(String.self,     forKey: .voornaam)
        achternaam       = try c.decode(String.self,     forKey: .achternaam)
        email            = try c.decode(String.self,     forKey: .email)
        wachtwoord       = try c.decode(String.self,     forKey: .wachtwoord)
        telefoon         = try c.decode(String.self,     forKey: .telefoon)
        straat           = try c.decode(String.self,     forKey: .straat)
        huisnummer       = try c.decode(String.self,     forKey: .huisnummer)
        postcode         = try c.decode(String.self,     forKey: .postcode)
        woonplaats       = try c.decode(String.self,     forKey: .woonplaats)
        registratieDatum = (try? c.decodeIfPresent(Date.self,   forKey: .registratieDatum)) ?? Date()
        abonnementType   = (try? c.decodeIfPresent(String.self, forKey: .abonnementType))   ?? ""
        abonnementActief = (try? c.decodeIfPresent(Bool.self,   forKey: .abonnementActief)) ?? false
    }
}

@MainActor
class ShopStore: ObservableObject {
    @Published var shop:            Shop?
    @Published var isLoggedIn:      Bool      = false
    @Published var isCheckingCloud: Bool      = false
    @Published var berichten:       [Bericht] = []

    var ongelezen: Int { berichten.filter { !gelezenIds.contains($0.id) }.count }

    static let trialDagen = 30

    var trialActief: Bool {
        guard let s = shop else { return false }
        let verloopdatum = Calendar.current.date(byAdding: .day, value: Self.trialDagen, to: s.registratieDatum) ?? s.registratieDatum
        return Date() < verloopdatum
    }

    // Toegang vereist gekozen plan + (betaald OF nog in trial)
    var heeftToegang: Bool {
        guard let s = shop, !s.abonnementType.isEmpty else { return false }
        return s.abonnementActief || trialActief
    }

    var dagenResterend: Int {
        guard let s = shop else { return 0 }
        let verloopdatum = Calendar.current.date(byAdding: .day, value: Self.trialDagen, to: s.registratieDatum) ?? s.registratieDatum
        return max(0, Calendar.current.dateComponents([.day], from: Date(), to: verloopdatum).day ?? 0)
    }

    private let loginKey   = "shop_logged_in"
    private let dataKey    = "shop_data"
    private let gelezenKey = "shop_gelezen_berichten"
    private var syncTask:   Task<Void, Never>?
    private var gelezenIds: Set<String> = []

    init() {
        // UITest injection via launch environment
        if let json = ProcessInfo.processInfo.environment["SHOP_TEST_DATA"],
           let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(Shop.self, from: data) {
            shop = decoded
            isLoggedIn = true
            return
        }
        isLoggedIn = UserDefaults.standard.bool(forKey: loginKey)
        if let data = UserDefaults.standard.data(forKey: dataKey) {
            shop = try? JSONDecoder().decode(Shop.self, from: data)
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

    func keurAfspraakGoed(_ a: Afspraak) async {
        let df = DateFormatter(); df.locale = Locale(identifier: "nl_NL"); df.dateFormat = "d MMM · HH:mm"
        let datumStr = df.string(from: a.datum)
        let naam = shop.map { $0.bedrijfsnaam.isEmpty ? "\($0.voornaam) \($0.achternaam)".trimmingCharacters(in: .whitespaces) : $0.bedrijfsnaam } ?? ""
        if a.artiesEmail.isEmpty || a.status == "arties_akkoord" {
            await CloudKitManager.shared.updateAfspraakStatus(id: a.id, nieuwStatus: "wacht_klant")
            let b = Bericht(ontvangerEmail: a.klantEmail, ontvangerRol: "klant",
                            type: "wacht_klant",
                            tekst: "Goed nieuws! Je afspraakverzoek op \(datumStr) is goedgekeurd. Open de app om te bevestigen.",
                            afspraakId: a.id, datum: Date())
            await CloudKitManager.shared.saveBericht(b)
        } else {
            await CloudKitManager.shared.updateAfspraakStatus(id: a.id, nieuwStatus: "shop_akkoord")
            let b = Bericht(ontvangerEmail: a.artiesEmail, ontvangerRol: "arties",
                            type: "shop_akkoord",
                            tekst: "\(naam) heeft akkoord gegeven voor een afspraak op \(datumStr). Geef jij ook akkoord?",
                            afspraakId: a.id, datum: Date())
            await CloudKitManager.shared.saveBericht(b)
        }
        await laadBerichten()
    }

    func weigerAfspraak(_ a: Afspraak) async {
        await CloudKitManager.shared.updateAfspraakStatus(id: a.id, nieuwStatus: "geweigerd")
        let naam = shop.map { $0.bedrijfsnaam.isEmpty ? "\($0.voornaam) \($0.achternaam)".trimmingCharacters(in: .whitespaces) : $0.bedrijfsnaam } ?? ""
        let df = DateFormatter(); df.locale = Locale(identifier: "nl_NL"); df.dateFormat = "d MMM · HH:mm"
        let b = Bericht(ontvangerEmail: a.klantEmail, ontvangerRol: "klant",
                        type: "geweigerd",
                        tekst: "Helaas, \(naam) heeft je afspraakverzoek op \(df.string(from: a.datum)) niet kunnen bevestigen.",
                        afspraakId: a.id, datum: Date())
        await CloudKitManager.shared.saveBericht(b)
        await laadBerichten()
    }

    func annuleerAfspraak(_ a: Afspraak) async {
        await CloudKitManager.shared.updateAfspraakStatus(id: a.id, nieuwStatus: "geannuleerd")
        let df = DateFormatter(); df.locale = Locale(identifier: "nl_NL"); df.dateFormat = "d MMM · HH:mm"
        let naam = shop.map { $0.bedrijfsnaam.isEmpty ? "\($0.voornaam) \($0.achternaam)".trimmingCharacters(in: .whitespaces) : $0.bedrijfsnaam } ?? ""
        let tekst = "\(naam) heeft de afspraak op \(df.string(from: a.datum)) afgezegd."
        let bKlant = Bericht(ontvangerEmail: a.klantEmail, ontvangerRol: "klant",
                             type: "geannuleerd", tekst: tekst, afspraakId: a.id, datum: Date())
        await CloudKitManager.shared.saveBericht(bKlant)
        if !a.artiesEmail.isEmpty {
            let bArties = Bericht(ontvangerEmail: a.artiesEmail, ontvangerRol: "arties",
                                  type: "geannuleerd", tekst: tekst, afspraakId: a.id, datum: Date())
            await CloudKitManager.shared.saveBericht(bArties)
        }
        EventKitManager.shared.verwijder(afspraakId: a.id)
        await laadBerichten()
    }

    func save(_ shop: Shop) {
        self.shop       = shop
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(shop) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        Task {
            try? await CloudKitManager.shared.saveShop(shop)
            await CloudKitManager.shared.savePubliekShop(shop)
        }
    }

    #if DEBUG
    func saveLocal(_ shop: Shop) {
        self.shop       = shop
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(shop) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        startSync()
    }
    #endif

    // Eerste keuze direct na registratie (trial loopt al)
    func kiesAbonnement(_ type: String) {
        guard var s = shop else { return }
        s.abonnementType = type
        save(s)
    }

    // Activeer betaald abonnement na trial (optioneel nieuw type meegeven)
    func activeerAbonnement(type: String? = nil) {
        guard var s = shop else { return }
        s.abonnementActief = true
        if let type { s.abonnementType = type }
        save(s)
    }

    func checkCloud(appleUserID: String) async {
        isCheckingCloud = true
        defer { isCheckingCloud = false }
        guard let found = await CloudKitManager.shared.fetchShop(appleUserID: appleUserID) else { return }
        shop       = found
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(found) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        startSync()
    }

    func inloggen(email: String, wachtwoord: String) async -> String? {
        isCheckingCloud = true
        defer { isCheckingCloud = false }
        guard let found = await CloudKitManager.shared.fetchShop(email: email) else {
            return "Geen account gevonden met dit e-mailadres."
        }
        guard found.wachtwoord == wachtwoord else {
            return "Wachtwoord klopt niet."
        }
        shop = found
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(found) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        startSync()
        return nil
    }

    func verwijderAccount() async {
        if let s = shop { await CloudKitManager.shared.verwijderShop(s) }
        logout()
    }

    func logout() {
        shop       = nil
        isLoggedIn = false
        berichten  = []
        UserDefaults.standard.removeObject(forKey: loginKey)
        UserDefaults.standard.removeObject(forKey: dataKey)
        updateBadge()
        // sync blijft draaien — shop kan altijd aan staan als kiosk
    }

    func syncNu() {
        Task { await syncVanCloud() }
    }

    // MARK: - Achtergrond sync elke 5 minuten

    private func startSync() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            await self?.syncVanCloud()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 min
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
        guard let s = shop, isLoggedIn else { return }
        guard let found = await CloudKitManager.shared.fetchShop(email: s.email) else { return }
        shop = found
        if let data = try? JSONEncoder().encode(found) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        await laadBerichten()
    }

    func laadBerichten() async {
        guard let email = shop?.email, !email.isEmpty else { return }
        berichten = await CloudKitManager.shared.fetchBerichten(email: email)
        updateBadge()
    }

    private func updateBadge() {
        let n = ongelezen
        Task { try? await UNUserNotificationCenter.current().setBadgeCount(n) }
    }

    private func requestNotificationPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.badge])
    }
}
