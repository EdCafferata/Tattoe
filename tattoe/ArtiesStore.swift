import Foundation
import Combine
import UIKit

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
    var shopEmails:    [String] = []   // meerdere shops mogelijk
    var bio:           String = ""
    var stijlen:       [String] = []
    var jarenervaring: Int = 0
    var instagram:     String = ""
    var facebook:      String = ""
    var pinterest:     String = ""
    var tiktok:        String = ""
    var website:       String = ""

    init(authMethod: AuthMethod, appleUserID: String, voornaam: String, achternaam: String,
         email: String, wachtwoord: String, kunstnaam: String, specialisatie: String,
         telefoon: String, straat: String, huisnummer: String, postcode: String,
         woonplaats: String, shopEmails: [String] = [], bio: String = "",
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
        self.shopEmails    = shopEmails
        self.bio           = bio
        self.stijlen       = stijlen
        self.jarenervaring = jarenervaring
        self.instagram     = instagram
        self.facebook      = facebook
        self.pinterest     = pinterest
        self.tiktok        = tiktok
        self.website       = website
    }

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
        // Backward compat: old records had shopEmail (String), new have shopEmails ([String])
        if let arr = try? c.decodeIfPresent([String].self, forKey: .shopEmails) {
            shopEmails = arr
        } else {
            shopEmails = []
        }
        bio           = (try? c.decodeIfPresent(String.self,   forKey: .bio))           ?? ""
        stijlen       = (try? c.decodeIfPresent([String].self, forKey: .stijlen))       ?? []
        jarenervaring = (try? c.decodeIfPresent(Int.self,      forKey: .jarenervaring)) ?? 0
        instagram     = (try? c.decodeIfPresent(String.self,   forKey: .instagram))     ?? ""
        facebook      = (try? c.decodeIfPresent(String.self,   forKey: .facebook))      ?? ""
        pinterest     = (try? c.decodeIfPresent(String.self,   forKey: .pinterest))     ?? ""
        tiktok        = (try? c.decodeIfPresent(String.self,   forKey: .tiktok))        ?? ""
        website       = (try? c.decodeIfPresent(String.self,   forKey: .website))       ?? ""
    }
}

@MainActor
class ArtiesStore: ObservableObject {
    @Published var arties:          Arties?
    @Published var isLoggedIn:      Bool    = false
    @Published var isCheckingCloud: Bool    = false
    @Published var profielFotoData: Data?   = nil
    @Published var portfolioFotos:  [Data?] = Array(repeating: nil, count: 9)
    @Published var voorbeeldFotos:  [Data?] = Array(repeating: nil, count: 9)

    private let loginKey  = "arties_logged_in"
    private let dataKey   = "arties_data"
    private var syncTask:  Task<Void, Never>?

    init() {
        isLoggedIn = UserDefaults.standard.bool(forKey: loginKey)
        if let data = UserDefaults.standard.data(forKey: dataKey) {
            arties = try? JSONDecoder().decode(Arties.self, from: data)
        }
        profielFotoData = try? Data(contentsOf: profielFotoURL())
        portfolioFotos  = (0..<9).map { try? Data(contentsOf: portfolioFotoURL($0)) }
        voorbeeldFotos  = (0..<9).map { try? Data(contentsOf: voorbeeldFotoURL($0)) }
        if isLoggedIn { startSync() }
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

    #if DEBUG
    func saveLocal(_ arties: Arties) {
        self.arties     = arties
        self.isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(arties) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
        startSync()
    }
    #endif

    func saveProfielFoto(_ data: Data) {
        let compressed = compress(data)
        profielFotoData = compressed
        try? compressed.write(to: profielFotoURL())
        if let a = arties {
            Task { await CloudKitManager.shared.saveArtiestFotos(arties: a, profiel: compressed, portfolio: portfolioFotos, voorbeelden: voorbeeldFotos) }
        }
    }

    func savePortfolioFoto(_ data: Data, at index: Int) {
        let compressed = compress(data)
        portfolioFotos[index] = compressed
        try? compressed.write(to: portfolioFotoURL(index))
        if let a = arties {
            Task { await CloudKitManager.shared.saveArtiestFotos(arties: a, profiel: profielFotoData, portfolio: portfolioFotos, voorbeelden: voorbeeldFotos) }
        }
    }

    func saveVoorbeeldFoto(_ data: Data, at index: Int) {
        let compressed = compress(data)
        voorbeeldFotos[index] = compressed
        try? compressed.write(to: voorbeeldFotoURL(index))
        if let a = arties {
            Task { await CloudKitManager.shared.saveArtiestFotos(arties: a, profiel: profielFotoData, portfolio: portfolioFotos, voorbeelden: voorbeeldFotos) }
        }
    }

    func removeVoorbeeldFoto(at index: Int) {
        voorbeeldFotos[index] = nil
        try? FileManager.default.removeItem(at: voorbeeldFotoURL(index))
        if let a = arties {
            Task { await CloudKitManager.shared.saveArtiestFotos(arties: a, profiel: profielFotoData, portfolio: portfolioFotos, voorbeelden: voorbeeldFotos) }
        }
    }

    func removePortfolioFoto(at index: Int) {
        portfolioFotos[index] = nil
        try? FileManager.default.removeItem(at: portfolioFotoURL(index))
        if let a = arties {
            Task { await CloudKitManager.shared.saveArtiestFotos(arties: a, profiel: profielFotoData, portfolio: portfolioFotos, voorbeelden: voorbeeldFotos) }
        }
    }

    func checkCloud(appleUserID: String) async {
        isCheckingCloud = true
        defer { isCheckingCloud = false }
        guard let found = await CloudKitManager.shared.fetchArties(appleUserID: appleUserID) else { return }
        persistArties(found)
        let fotos = await CloudKitManager.shared.fetchArtiestFotos(arties: found)
        applyFotos(fotos)
        startSync()
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
        persistArties(found)
        let fotos = await CloudKitManager.shared.fetchArtiestFotos(arties: found)
        applyFotos(fotos)
        startSync()
        return nil
    }

    func logout() {
        stopSync()
        arties          = nil
        isLoggedIn      = false
        profielFotoData = nil
        portfolioFotos  = Array(repeating: nil, count: 9)
        voorbeeldFotos  = Array(repeating: nil, count: 9)
        UserDefaults.standard.removeObject(forKey: loginKey)
        UserDefaults.standard.removeObject(forKey: dataKey)
        try? FileManager.default.removeItem(at: profielFotoURL())
        for i in 0..<9 {
            try? FileManager.default.removeItem(at: portfolioFotoURL(i))
            try? FileManager.default.removeItem(at: voorbeeldFotoURL(i))
        }
    }

    // MARK: - Achtergrond sync elke 10 minuten

    private func startSync() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
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
        guard let a = arties, isLoggedIn else { return }
        guard let found = await CloudKitManager.shared.fetchArties(email: a.email) else { return }
        persistArties(found)
        let fotos = await CloudKitManager.shared.fetchArtiestFotos(arties: found)
        applyFotos(fotos)
    }

    // MARK: Private

    private func persistArties(_ found: Arties) {
        arties     = found
        isLoggedIn = true
        UserDefaults.standard.set(true, forKey: loginKey)
        if let data = try? JSONEncoder().encode(found) {
            UserDefaults.standard.set(data, forKey: dataKey)
        }
    }

    private func applyFotos(_ fotos: (profiel: Data?, portfolio: [Data?], voorbeelden: [Data?])) {
        if let p = fotos.profiel {
            profielFotoData = p
            try? p.write(to: profielFotoURL())
        }
        for (i, f) in fotos.portfolio.enumerated() {
            if let f { portfolioFotos[i] = f; try? f.write(to: portfolioFotoURL(i)) }
        }
        for (i, f) in fotos.voorbeelden.enumerated() {
            if let f { voorbeeldFotos[i] = f; try? f.write(to: voorbeeldFotoURL(i)) }
        }
    }

    private func docsDir() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func profielFotoURL() -> URL {
        docsDir().appendingPathComponent("arties_profiel.jpg")
    }

    private func portfolioFotoURL(_ i: Int) -> URL {
        docsDir().appendingPathComponent("arties_portfolio_\(i).jpg")
    }

    private func voorbeeldFotoURL(_ i: Int) -> URL {
        docsDir().appendingPathComponent("arties_voorbeeld_\(i).jpg")
    }

    private func compress(_ data: Data) -> Data {
        guard let img = UIImage(data: data) else { return data }
        let maxDim: CGFloat = 1080
        let size = img.size
        let scale = min(maxDim / max(size.width, size.height), 1)
        if scale == 1 { return img.jpegData(compressionQuality: 0.8) ?? data }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in img.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.8) ?? data
    }
}
