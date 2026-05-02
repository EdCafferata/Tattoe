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

class ShopStore: ObservableObject {
    @Published var shop:      Shop?
    @Published var isLoggedIn: Bool = false

    private let loginKey = "shop_logged_in"
    private let dataKey  = "shop_data"

    init() {
        isLoggedIn = UserDefaults.standard.bool(forKey: loginKey)
        if let data = UserDefaults.standard.data(forKey: dataKey) {
            shop = try? JSONDecoder().decode(Shop.self, from: data)
        }
    }

    func save(_ shop: Shop) {
        self.shop      = shop
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(shop) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
    }

    func logout() {
        self.shop       = nil
        self.isLoggedIn = false
        UserDefaults.standard.removeObject(forKey: loginKey)
        UserDefaults.standard.removeObject(forKey: dataKey)
    }
}
