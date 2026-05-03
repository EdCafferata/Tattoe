import Foundation
import Combine

enum AuthMethod: String, Codable { case apple, email }

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
    @Published var klant:          Klant?
    @Published var isLoggedIn:     Bool = false
    @Published var consentGegeven: Bool = false
    @Published var isCheckingCloud: Bool = false

    private let loginKey   = "klant_logged_in"
    private let dataKey    = "klant_data"
    private let consentKey = "klant_consent"

    init() {
        isLoggedIn     = UserDefaults.standard.bool(forKey: loginKey)
        consentGegeven = UserDefaults.standard.bool(forKey: consentKey)
        if let data = UserDefaults.standard.data(forKey: dataKey) {
            klant = try? JSONDecoder().decode(Klant.self, from: data)
        }
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

    func saveConsent() {
        consentGegeven = true
        UserDefaults.standard.set(true, forKey: consentKey)
        if let klant { Task { try? await CloudKitManager.shared.saveKlant(klant, consentGegeven: true) } }
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
    }

    func logout() {
        klant          = nil
        isLoggedIn     = false
        consentGegeven = false
        UserDefaults.standard.removeObject(forKey: loginKey)
        UserDefaults.standard.removeObject(forKey: dataKey)
        UserDefaults.standard.removeObject(forKey: consentKey)
    }
}
