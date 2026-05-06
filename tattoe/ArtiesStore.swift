import Foundation
import Combine

struct Arties: Codable {
    var authMethod:    AuthMethod
    var appleUserID:   String
    var voornaam:      String
    var achternaam:    String
    var email:         String
    var wachtwoord:    String
    var kunstnaam:     String
    var specialisatie: String
    var telefoon:      String
    var straat:        String
    var huisnummer:    String
    var postcode:      String
    var woonplaats:    String
    // Profiel-uitbreiding
    var shopEmail:     String = ""
    var bio:           String = ""
    var stijlen:       [String] = []
    var jarenervaring: Int = 0
    var instagram:     String = ""
    var facebook:      String = ""
    var pinterest:     String = ""
    var tiktok:        String = ""
    var website:       String = ""

    // Volledige memberwise init
    init(authMethod: AuthMethod, appleUserID: String, voornaam: String, achternaam: String,
         email: String, wachtwoord: String, kunstnaam: String, specialisatie: String,
         telefoon: String, straat: String, huisnummer: String, postcode: String,
         woonplaats: String, shopEmail: String = "", bio: String = "",
         stijlen: [String] = [], jarenervaring: Int = 0, instagram: String = "",
         facebook: String = "", pinterest: String = "", tiktok: String = "",
         website: String = "") {
        self.authMethod    = authMethod
        self.appleUserID   = appleUserID
        self.voornaam      = voornaam
        self.achternaam    = achternaam
        self.email         = email
        self.wachtwoord    = wachtwoord
        self.kunstnaam     = kunstnaam
        self.specialisatie = specialisatie
        self.telefoon      = telefoon
        self.straat        = straat
        self.huisnummer    = huisnummer
        self.postcode      = postcode
        self.woonplaats    = woonplaats
        self.shopEmail     = shopEmail
        self.bio           = bio
        self.stijlen       = stijlen
        self.jarenervaring = jarenervaring
        self.instagram     = instagram
        self.facebook      = facebook
        self.pinterest     = pinterest
        self.tiktok        = tiktok
        self.website       = website
    }

    // Backward-compatible decode: nieuwe velden zijn optioneel
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        authMethod    = try c.decode(AuthMethod.self, forKey: .authMethod)
        appleUserID   = try c.decode(String.self,     forKey: .appleUserID)
        voornaam      = try c.decode(String.self,     forKey: .voornaam)
        achternaam    = try c.decode(String.self,     forKey: .achternaam)
        email         = try c.decode(String.self,     forKey: .email)
        wachtwoord    = try c.decode(String.self,     forKey: .wachtwoord)
        kunstnaam     = try c.decode(String.self,     forKey: .kunstnaam)
        specialisatie = try c.decode(String.self,     forKey: .specialisatie)
        telefoon      = try c.decode(String.self,     forKey: .telefoon)
        straat        = try c.decode(String.self,     forKey: .straat)
        huisnummer    = try c.decode(String.self,     forKey: .huisnummer)
        postcode      = try c.decode(String.self,     forKey: .postcode)
        woonplaats    = try c.decode(String.self,     forKey: .woonplaats)
        shopEmail     = (try? c.decodeIfPresent(String.self,  forKey: .shopEmail))     ?? ""
        bio           = (try? c.decodeIfPresent(String.self,  forKey: .bio))           ?? ""
        stijlen       = (try? c.decodeIfPresent([String].self, forKey: .stijlen))      ?? []
        jarenervaring = (try? c.decodeIfPresent(Int.self,     forKey: .jarenervaring)) ?? 0
        instagram     = (try? c.decodeIfPresent(String.self,  forKey: .instagram))     ?? ""
        facebook      = (try? c.decodeIfPresent(String.self,  forKey: .facebook))      ?? ""
        pinterest     = (try? c.decodeIfPresent(String.self,  forKey: .pinterest))     ?? ""
        tiktok        = (try? c.decodeIfPresent(String.self,  forKey: .tiktok))        ?? ""
        website       = (try? c.decodeIfPresent(String.self,  forKey: .website))       ?? ""
    }
}

@MainActor
class ArtiesStore: ObservableObject {
    @Published var arties:          Arties?
    @Published var isLoggedIn:      Bool = false
    @Published var isCheckingCloud: Bool = false

    private let loginKey = "arties_logged_in"
    private let dataKey  = "arties_data"

    init() {
        isLoggedIn = UserDefaults.standard.bool(forKey: loginKey)
        if let data = UserDefaults.standard.data(forKey: dataKey) {
            arties = try? JSONDecoder().decode(Arties.self, from: data)
        }
    }

    func save(_ arties: Arties) {
        self.arties     = arties
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(arties) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        Task {
            try? await CloudKitManager.shared.saveArties(arties)
            await CloudKitManager.shared.savePubliekArties(arties)
        }
    }

    func checkCloud(appleUserID: String) async {
        isCheckingCloud = true
        defer { isCheckingCloud = false }
        guard let found = await CloudKitManager.shared.fetchArties(appleUserID: appleUserID) else { return }
        arties     = found
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(found) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
    }

    func inloggen(email: String, wachtwoord: String) async -> String? {
        isCheckingCloud = true
        defer { isCheckingCloud = false }
        guard let found = await CloudKitManager.shared.fetchArties(email: email) else {
            return "Geen account gevonden met dit e-mailadres."
        }
        guard found.wachtwoord == wachtwoord else {
            return "Wachtwoord klopt niet."
        }
        arties = found
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(found) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        return nil
    }

    func logout() {
        arties     = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: loginKey)
        UserDefaults.standard.removeObject(forKey: dataKey)
    }
}
