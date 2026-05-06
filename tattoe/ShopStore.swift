import Foundation
import Combine

struct Shop: Codable {
    var authMethod:   AuthMethod
    var appleUserID:  String
    var bedrijfsnaam: String
    var kvk:          String
    var btw:          String
    var voornaam:     String
    var achternaam:   String
    var email:        String
    var wachtwoord:   String
    var telefoon:     String
    var straat:       String
    var huisnummer:   String
    var postcode:     String
    var woonplaats:   String
}

@MainActor
class ShopStore: ObservableObject {
    @Published var shop:            Shop?
    @Published var isLoggedIn:      Bool = false
    @Published var isCheckingCloud: Bool = false

    private let loginKey = "shop_logged_in"
    private let dataKey  = "shop_data"

    init() {
        isLoggedIn = UserDefaults.standard.bool(forKey: loginKey)
        if let data = UserDefaults.standard.data(forKey: dataKey) {
            shop = try? JSONDecoder().decode(Shop.self, from: data)
        }
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
        return nil
    }

    func logout() {
        shop       = nil
        isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: loginKey)
        UserDefaults.standard.removeObject(forKey: dataKey)
    }
}
