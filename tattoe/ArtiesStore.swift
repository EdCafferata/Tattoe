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
        Task { try? await CloudKitManager.shared.saveArties(arties) }
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

    func logout() {
        arties     = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: loginKey)
        UserDefaults.standard.removeObject(forKey: dataKey)
    }
}
