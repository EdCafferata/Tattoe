import SwiftUI
import AuthenticationServices
import PhotosUI

// MARK: - Abonnement data model

struct AbonnementPlan: Identifiable {
    let id:           String
    let naam:         String
    let prijs:        String    // "" = enterprise / op aanvraag
    let features:     [String]
    let isEnterprise: Bool
}

let shopPlannen: [AbonnementPlan] = [
    AbonnementPlan(id: "starter",
                   naam: "STARTER", prijs: "9,99",
                   features: ["1 artiest", "1 actief apparaat", "1 shop", "Geen website-integratie"],
                   isEnterprise: false),
    AbonnementPlan(id: "studio",
                   naam: "STUDIO", prijs: "49,99",
                   features: ["Tot 10 artiesten", "2 actieve apparaten", "1 shop", "Geen website-integratie"],
                   isEnterprise: false),
    AbonnementPlan(id: "pro",
                   naam: "PRO", prijs: "99,99",
                   features: ["Onbeperkte artiesten", "Onbeperkte actieve sessies", "1 shop · 1 locatie"],
                   isEnterprise: false),
    AbonnementPlan(id: "enterprise",
                   naam: "ENTERPRISE", prijs: "",
                   features: ["Meerdere shops", "Onbeperkte artiesten", "Alle locaties", "Maatwerkoplossing"],
                   isEnterprise: true),
]

// MARK: - Gedeelde plan-kaart

struct AbonnementPlanKaart: View {
    let plan:        AbonnementPlan
    let knopLabel:   String
    let gekozen:     Bool
    let bezig:       Bool
    let onKies:      () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header: naam + prijs
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.naam)
                        .font(.system(size: 11, weight: .bold))
                        .tracking(4)
                        .foregroundColor(plan.isEnterprise ? Color(white: 0.45) : .white)
                    if gekozen {
                        Text("GESELECTEERD")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Color(white: 0.4))
                    }
                }
                Spacer()
                if plan.isEnterprise {
                    Text("OP AANVRAAG")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.4))
                        .padding(.top, 2)
                } else {
                    VStack(alignment: .trailing, spacing: 1) {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("€")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                            Text(plan.prijs)
                                .font(.system(size: 26, weight: .black))
                                .foregroundColor(.white)
                        }
                        Text("per maand")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.35))
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 12)

            Rectangle().fill(Color(white: 0.12)).frame(height: 1)

            // Features
            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.features, id: \.self) { f in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(white: 0.4))
                        Text(f)
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.6))
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 12)

            Rectangle().fill(Color(white: 0.12)).frame(height: 1)

            // Knop
            Button(action: onKies) {
                Group {
                    if bezig {
                        ProgressView().tint(plan.isEnterprise ? Color(white: 0.5) : .black).scaleEffect(0.8)
                    } else {
                        Text(knopLabel)
                            .font(.system(size: 12, weight: .black))
                            .tracking(3)
                            .foregroundColor(plan.isEnterprise ? Color(white: 0.55) : .black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(plan.isEnterprise ? Color(white: 0.1) : Color.white)
            }
            .accessibilityIdentifier("plan_knop_\(plan.id)")
            .disabled(bezig)
        }
        .background(Color(white: 0.065))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(gekozen ? Color(white: 0.45) : Color(white: 0.13), lineWidth: gekozen ? 1.5 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Flow orchestrator

struct ShopFlowView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if store.isLoggedIn, let shop = store.shop {
                if shop.voornaam.isEmpty {
                    ShopNAWView(onLogout: onLogout)
                } else if shop.abonnementType.isEmpty {
                    ShopAbonnementKiezenView(onLogout: onLogout)
                } else if !store.heeftToegang {
                    ShopAbonnementVerlopenView(onLogout: onLogout)
                } else {
                    ShopModeKeuzeView(onLogout: onLogout)
                }
            } else {
                ShopLoginView(onLogout: onLogout)
            }
        }
    }
}

// MARK: - Login keuze scherm

struct ShopLoginView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void

    @State private var error: String?
    @State private var showEmailLogin    = false
    @State private var showEmailRegister = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("TattoeLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Spacer().frame(height: 32)

                Text("SHOP")
                    .font(.system(size: 32, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)

                Spacer().frame(height: 8)

                Text("Meld je aan als tattoo shop")
                    .font(.system(size: 12))
                    .tracking(1)
                    .foregroundColor(Color(white: 0.4))

                Spacer().frame(height: 52)

                VStack(spacing: 12) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleResult(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // INLOGGEN / REGISTREREN knoppen
                    HStack(spacing: 12) {
                        Button(action: { showEmailLogin = true }) {
                            Text("INLOGGEN")
                                .font(.system(size: 14, weight: .black))
                                .tracking(3)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color(white: 0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(white: 0.35), lineWidth: 1)
                                )
                        }

                        Button(action: { showEmailRegister = true }) {
                            Text("REGISTREREN")
                                .font(.system(size: 14, weight: .black))
                                .tracking(3)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(.horizontal, 40)

                if let error {
                    Spacer().frame(height: 14)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 1, green: 0.3, blue: 0.3))
                        .padding(.horizontal, 40)
                }

                Spacer()

                #if DEBUG
                Button(action: devInloggen) {
                    Text("DEV: DIRECT INLOGGEN")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color(red: 1, green: 0.6, blue: 0))
                }
                .padding(.bottom, 8)
                #endif

                Button(action: onLogout) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                        Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                    }
                    .foregroundColor(Color(white: 0.35))
                }
                .padding(.bottom, 40)
            }

            if store.isCheckingCloud {
                Color.black.opacity(0.7).ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView().tint(.white).scaleEffect(1.2)
                    Text("ACCOUNT OPHALEN…")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(3)
                        .foregroundColor(Color(white: 0.5))
                }
            }
        }
        .fullScreenCover(isPresented: $showEmailLogin) {
            ShopEmailLoginView(onLogout: onLogout)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showEmailRegister) {
            ShopEmailRegisterView(onLogout: onLogout)
                .environmentObject(store)
        }
    }

    #if DEBUG
    private func devInloggen() {
        let testShop = Shop(
            authMethod:   .email,
            appleUserID:  "",
            bedrijfsnaam: "Dragon Tattoo Shop",
            kvk:          "12345678",
            btw:          "NL123456789B01",
            voornaam:     "Marco",
            achternaam:   "van den Berg",
            email:        "marco@dragontattoo.nl",
            wachtwoord:   "test1234",
            telefoon:     "0201234567",
            straat:       "Leidseplein",
            huisnummer:   "5",
            postcode:     "1017PT",
            woonplaats:   "Amsterdam"
        )
        store.save(testShop)
    }
    #endif

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential else { return }

            let uid = cred.user
            if let e = cred.email,              !e.isEmpty { UserDefaults.standard.set(e, forKey: "apple_email_\(uid)") }
            if let n = cred.fullName?.givenName,  !n.isEmpty { UserDefaults.standard.set(n, forKey: "apple_fn_\(uid)") }
            if let n = cred.fullName?.familyName, !n.isEmpty { UserDefaults.standard.set(n, forKey: "apple_ln_\(uid)") }

            let email      = cred.email                     ?? UserDefaults.standard.string(forKey: "apple_email_\(uid)") ?? ""
            let voornaam   = cred.fullName?.givenName       ?? UserDefaults.standard.string(forKey: "apple_fn_\(uid)")    ?? ""
            let achternaam = cred.fullName?.familyName      ?? UserDefaults.standard.string(forKey: "apple_ln_\(uid)")    ?? ""

            #if DEBUG
            guard !store.isLoggedIn else { return }
            store.saveLocal(Shop(
                authMethod:   .apple,
                appleUserID:  uid,
                bedrijfsnaam: "",
                kvk:          "",
                btw:          "",
                voornaam:     voornaam,
                achternaam:   achternaam,
                email:        email,
                wachtwoord:   "",
                telefoon:     "",
                straat:       "",
                huisnummer:   "",
                postcode:     "",
                woonplaats:   ""
            ))
            #else
            Task {
                await store.checkCloud(appleUserID: uid)
                if !store.isLoggedIn {
                    store.save(Shop(
                        authMethod:   .apple,
                        appleUserID:  uid,
                        bedrijfsnaam: "",
                        kvk:          "",
                        btw:          "",
                        voornaam:     voornaam,
                        achternaam:   achternaam,
                        email:        email,
                        wachtwoord:   "",
                        telefoon:     "",
                        straat:       "",
                        huisnummer:   "",
                        postcode:     "",
                        woonplaats:   ""
                    ))
                } else if !email.isEmpty, store.shop?.email.isEmpty == true {
                    var s = store.shop!; s.email = email; store.save(s)
                }
            }
            #endif
        case .failure(let err):
            if (err as NSError).code != ASAuthorizationError.canceled.rawValue {
                error = "Aanmelden mislukt. Probeer opnieuw."
            }
        }
    }
}

// MARK: - Email inloggen

struct ShopEmailLoginView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var email               = ""
    @State private var wachtwoord          = ""
    @State private var fout: String?
    @State private var bezig               = false
    @State private var showWachtwoordReset = false
    @FocusState private var focus: Veld?

    enum Veld: Hashable { case email, wachtwoord }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("INLOGGEN")
                    .font(.system(size: 26, weight: .black))
                    .tracking(6)
                    .foregroundColor(.white)

                Spacer().frame(height: 6)

                Text("Log in met je shop account")
                    .font(.system(size: 12))
                    .tracking(2)
                    .foregroundColor(Color(white: 0.4))

                Spacer().frame(height: 40)

                VStack(spacing: 1) {
                    InkField("E-MAILADRES", text: $email, type: .emailAddress, keyboard: .emailAddress)
                        .focused($focus, equals: .email)
                    InkField("WACHTWOORD", text: $wachtwoord, secure: true)
                        .focused($focus, equals: .wachtwoord)
                }
                .padding(.horizontal, 24)

                if let fout {
                    Spacer().frame(height: 14)
                    Text(fout)
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 1, green: 0.3, blue: 0.3))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                #if DEBUG
                Spacer().frame(height: 20)
                Button(action: { email = "marco@dragontattoo.nl"; wachtwoord = "test1234" }) {
                    Text("DEV: INVULLEN & INLOGGEN")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Color(red: 1, green: 0.6, blue: 0))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 24)
                #endif

                Spacer()
            }

            // Vaste INLOGGEN knop onderaan
            VStack(spacing: 0) {
                Spacer()
                Button(action: inloggen) {
                    Group {
                        if bezig {
                            ProgressView().tint(.black)
                        } else {
                            Text("INLOGGEN")
                                .font(.system(size: 14, weight: .black))
                                .tracking(4)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(bezig)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                Button(action: { showWachtwoordReset = true }) {
                    Text("Wachtwoord vergeten?")
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.35))
                }
                .padding(.bottom, 40)
            }

            // TERUG knop bovenaan
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                    Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                }
                .foregroundColor(Color(white: 0.35))
            }
            .padding(.leading, 24)
            .padding(.top, 16)
        }
        .fullScreenCover(isPresented: $showWachtwoordReset) {
            WachtwoordResetView(rol: .shop)
        }
    }

    private func inloggen() {
        fout = nil; focus = nil
        guard email.contains("@") else { fout = "Voer een geldig e-mailadres in."; return }
        guard !wachtwoord.isEmpty  else { fout = "Wachtwoord is verplicht."; return }
        bezig = true
        Task {
            let err = await store.inloggen(email: email.lowercased(), wachtwoord: wachtwoord)
            bezig = false
            if let err { fout = err } else { dismiss() }
        }
    }
}

// MARK: - Email registratie formulier

struct ShopEmailRegisterView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var bedrijfsnaam = ""
    @State private var kvk          = ""
    @State private var btw          = ""
    @State private var voornaam     = ""
    @State private var achternaam   = ""
    @State private var email        = ""
    @State private var wachtwoord   = ""
    @State private var bevestig     = ""
    @State private var telefoon     = ""
    @State private var straat       = ""
    @State private var huisnummer   = ""
    @State private var postcode     = ""
    @State private var woonplaats   = ""
    @State private var fout: String?
    @FocusState private var focus: Veld?

    enum Veld: Hashable {
        case bedrijfsnaam, kvk, btw
        case voornaam, achternaam, email, wachtwoord, bevestig
        case telefoon, straat, huisnummer, postcode, woonplaats
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    Text("REGISTREREN")
                        .font(.system(size: 26, weight: .black))
                        .tracking(6)
                        .foregroundColor(.white)

                    Spacer().frame(height: 6)

                    Text("Vul je shop gegevens in")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.4))

                    Spacer().frame(height: 20)

                    #if DEBUG
                    Button(action: devVulIn) {
                        Text("DEV: VELDEN INVULLEN")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Color(red: 1, green: 0.6, blue: 0))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(Color(white: 0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 24)
                    Spacer().frame(height: 20)
                    #else
                    Spacer().frame(height: 36)
                    #endif

                    // ── Sectie: Bedrijf ──────────────────
                    sectionLabel("BEDRIJF")

                    VStack(spacing: 1) {
                        InkField("BEDRIJFSNAAM", text: $bedrijfsnaam)
                            .focused($focus, equals: .bedrijfsnaam)
                        HStack(spacing: 1) {
                            InkField("KVK-NUMMER", text: $kvk, keyboard: .numberPad)
                                .focused($focus, equals: .kvk)
                            InkField("BTW-NUMMER", text: $btw)
                                .focused($focus, equals: .btw)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // ── Sectie: Account ──────────────────
                    sectionLabel("ACCOUNT")

                    VStack(spacing: 1) {
                        HStack(spacing: 1) {
                            InkField("VOORNAAM", text: $voornaam, type: .givenName)
                                .focused($focus, equals: .voornaam)
                            InkField("ACHTERNAAM", text: $achternaam, type: .familyName)
                                .focused($focus, equals: .achternaam)
                        }
                        InkField("E-MAILADRES", text: $email, type: .emailAddress, keyboard: .emailAddress)
                            .focused($focus, equals: .email)
                        InkField("WACHTWOORD", text: $wachtwoord, type: .newPassword, secure: true)
                            .focused($focus, equals: .wachtwoord)
                        InkField("BEVESTIG WACHTWOORD", text: $bevestig, secure: true)
                            .focused($focus, equals: .bevestig)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // ── Sectie: Contact ──────────────────
                    sectionLabel("CONTACT")

                    VStack(spacing: 1) {
                        InkField("TELEFOONNUMMER", text: $telefoon, type: .telephoneNumber, keyboard: .phonePad)
                            .focused($focus, equals: .telefoon)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // ── Sectie: Adres ────────────────────
                    sectionLabel("ADRES")

                    VStack(spacing: 1) {
                        HStack(spacing: 1) {
                            InkField("STRAAT", text: $straat, type: .streetAddressLine1)
                                .focused($focus, equals: .straat)
                            InkField("NR", text: $huisnummer, width: 90)
                                .focused($focus, equals: .huisnummer)
                        }
                        HStack(spacing: 1) {
                            InkField("POSTCODE", text: $postcode, type: .postalCode, width: 140)
                                .focused($focus, equals: .postcode)
                            InkField("WOONPLAATS", text: $woonplaats, type: .addressCity)
                                .focused($focus, equals: .woonplaats)
                        }
                    }
                    .padding(.horizontal, 24)

                    if let fout {
                        Spacer().frame(height: 16)
                        Text(fout)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 1, green: 0.3, blue: 0.3))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 100)
                }
            }

            // Vaste ACCOUNT AANMAKEN knop onderaan
            VStack(spacing: 0) {
                Spacer()
                Button(action: registreer) {
                    Text("ACCOUNT AANMAKEN")
                        .font(.system(size: 14, weight: .black))
                        .tracking(4)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

            // TERUG knop bovenaan
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                    Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                }
                .foregroundColor(Color(white: 0.35))
            }
            .padding(.leading, 24)
            .padding(.top, 16)
        }
    }

    #if DEBUG
    private func devVulIn() {
        bedrijfsnaam = "Dragon Tattoo Shop"
        kvk          = "12345678"
        btw          = "NL123456789B01"
        voornaam     = "Marco"
        achternaam   = "van den Berg"
        email        = "marco@dragontattoo.nl"
        wachtwoord   = "test1234"
        bevestig     = "test1234"
        telefoon     = "0201234567"
        straat       = "Leidseplein"
        huisnummer   = "5"
        postcode     = "1017PT"
        woonplaats   = "Amsterdam"
    }
    #endif

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 9, weight: .bold))
                .tracking(4)
                .foregroundColor(Color(white: 0.35))
            Spacer()
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 8)
    }

    private func registreer() {
        fout = nil; focus = nil
        guard !bedrijfsnaam.trimmingCharacters(in: .whitespaces).isEmpty else {
            fout = "Bedrijfsnaam is verplicht."; return
        }
        guard !voornaam.trimmingCharacters(in: .whitespaces).isEmpty else {
            fout = "Voornaam is verplicht."; return
        }
        guard !achternaam.trimmingCharacters(in: .whitespaces).isEmpty else {
            fout = "Achternaam is verplicht."; return
        }
        guard email.contains("@"), email.contains(".") else {
            fout = "Voer een geldig e-mailadres in."; return
        }
        guard wachtwoord.count >= 8 else {
            fout = "Wachtwoord moet minimaal 8 tekens zijn."; return
        }
        guard wachtwoord == bevestig else {
            fout = "Wachtwoorden komen niet overeen."; return
        }
        let shop = Shop(
            authMethod:   .email,
            appleUserID:  "",
            bedrijfsnaam: bedrijfsnaam,
            kvk:          kvk,
            btw:          btw,
            voornaam:     voornaam,
            achternaam:   achternaam,
            email:        email,
            wachtwoord:   wachtwoord,
            telefoon:     telefoon,
            straat:       straat,
            huisnummer:   huisnummer,
            postcode:     postcode,
            woonplaats:   woonplaats
        )
        store.save(shop)
        dismiss()
    }
}

// MARK: - NAW aanvullen (na Apple login)

struct ShopNAWView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var bedrijfsnaam = ""
    @State private var kvk          = ""
    @State private var btw          = ""
    @State private var voornaam     = ""
    @State private var achternaam   = ""
    @State private var email        = ""
    @State private var telefoon     = ""
    @State private var straat       = ""
    @State private var huisnummer   = ""
    @State private var postcode     = ""
    @State private var woonplaats   = ""
    @State private var fout: String?
    @State private var toonVerwijderBevestiging = false
    @State private var bezig = false
    @State private var fotoItem: PhotosPickerItem?
    @FocusState private var focus: Veld?

    enum Veld: Hashable {
        case bedrijfsnaam, kvk, btw
        case voornaam, achternaam, email, telefoon
        case straat, huisnummer, postcode, woonplaats
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    Text("JE GEGEVENS")
                        .font(.system(size: 26, weight: .black))
                        .tracking(6)
                        .foregroundColor(.white)

                    Spacer().frame(height: 6)

                    Text("Vul je shop gegevens aan om door te gaan")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.4))

                    Spacer().frame(height: 28)

                    PhotosPicker(selection: $fotoItem, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            if let data = store.profielFotoData, let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 90, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.2), lineWidth: 1))
                            } else {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color(white: 0.1))
                                        .frame(width: 90, height: 90)
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(white: 0.2), lineWidth: 1))
                                    Image(systemName: "building.2.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(Color(white: 0.2))
                                }
                            }
                            ZStack {
                                Circle().fill(Color.white).frame(width: 26, height: 26)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.black)
                            }
                            .offset(x: 3, y: 3)
                        }
                    }
                    .onChange(of: fotoItem) { _, item in
                        Task {
                            if let data = try? await item?.loadTransferable(type: Data.self) {
                                store.saveProfielFoto(data)
                            }
                        }
                    }
                    Text("LOGO")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Color(white: 0.35))
                        .padding(.top, 8)

                    Spacer().frame(height: 28)

                    VStack(spacing: 1) {
                        InkField("BEDRIJFSNAAM", text: $bedrijfsnaam)
                            .focused($focus, equals: .bedrijfsnaam)
                        HStack(spacing: 1) {
                            InkField("KVK-NUMMER", text: $kvk, keyboard: .numberPad)
                                .focused($focus, equals: .kvk)
                            InkField("BTW-NUMMER", text: $btw)
                                .focused($focus, equals: .btw)
                        }
                        HStack(spacing: 1) {
                            InkField("VOORNAAM", text: $voornaam, type: .givenName)
                                .focused($focus, equals: .voornaam)
                            InkField("ACHTERNAAM", text: $achternaam, type: .familyName)
                                .focused($focus, equals: .achternaam)
                        }
                        InkField("E-MAILADRES", text: $email, type: .emailAddress, keyboard: .emailAddress)
                            .focused($focus, equals: .email)
                        InkField("TELEFOONNUMMER", text: $telefoon, type: .telephoneNumber, keyboard: .phonePad)
                            .focused($focus, equals: .telefoon)
                        HStack(spacing: 1) {
                            InkField("STRAAT", text: $straat, type: .streetAddressLine1)
                                .focused($focus, equals: .straat)
                            InkField("NR", text: $huisnummer, width: 90)
                                .focused($focus, equals: .huisnummer)
                        }
                        HStack(spacing: 1) {
                            InkField("POSTCODE", text: $postcode, type: .postalCode, width: 140)
                                .focused($focus, equals: .postcode)
                            InkField("WOONPLAATS", text: $woonplaats, type: .addressCity)
                                .focused($focus, equals: .woonplaats)
                        }
                    }
                    .padding(.horizontal, 24)

                    if let fout {
                        Spacer().frame(height: 16)
                        Text(fout)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 1, green: 0.3, blue: 0.3))
                            .padding(.horizontal, 24)
                    }

                    Spacer().frame(height: 100)
                }
            }

            // Vaste OPSLAAN + VERWIJDER knoppen onderaan
            VStack(spacing: 0) {
                Spacer()
                Button(action: opslaan) {
                    Group {
                        if bezig {
                            ProgressView().tint(.black)
                        } else {
                            Text("OPSLAAN")
                                .font(.system(size: 14, weight: .black))
                                .tracking(5)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(bezig)
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                Button(action: { toonVerwijderBevestiging = true }) {
                    Text("ACCOUNT VERWIJDEREN")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color(red: 0.9, green: 0.25, blue: 0.25))
                }
                .disabled(bezig)
                .padding(.bottom, 40)
            }

            // TERUG knop bovenaan
            Button(action: { store.logout(); onLogout(); dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                    Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                }
                .foregroundColor(Color(white: 0.35))
            }
            .padding(.leading, 24)
            .padding(.top, 16)
        }
        .onAppear { prefill() }
        .confirmationDialog("Account permanent verwijderen?", isPresented: $toonVerwijderBevestiging, titleVisibility: .visible) {
            Button("Verwijderen", role: .destructive) {
                bezig = true
                Task {
                    await store.verwijderAccount()
                    onLogout()
                    dismiss()
                }
            }
            Button("Annuleren", role: .cancel) {}
        } message: {
            Text("Je shop, alle abonnementsgegevens en afspraken worden definitief verwijderd.")
        }
    }

    private func prefill() {
        if let s = store.shop {
            bedrijfsnaam = s.bedrijfsnaam
            kvk          = s.kvk
            btw          = s.btw
            voornaam     = s.voornaam
            achternaam   = s.achternaam
            email        = s.email
            telefoon     = s.telefoon
            straat       = s.straat
            huisnummer   = s.huisnummer
            postcode     = s.postcode
            woonplaats   = s.woonplaats
        }
    }

    private func opslaan() {
        guard !bedrijfsnaam.trimmingCharacters(in: .whitespaces).isEmpty else {
            fout = "Bedrijfsnaam is verplicht."; return
        }
        guard !voornaam.trimmingCharacters(in: .whitespaces).isEmpty else {
            fout = "Voornaam is verplicht."; return
        }
        guard email.contains("@") else {
            fout = "E-mailadres is verplicht."; return
        }
        fout = nil; focus = nil
        var s = store.shop ?? Shop(authMethod: .apple, appleUserID: "", bedrijfsnaam: "", kvk: "",
                                   btw: "", voornaam: "", achternaam: "", email: "", wachtwoord: "",
                                   telefoon: "", straat: "", huisnummer: "", postcode: "", woonplaats: "")
        s.bedrijfsnaam = bedrijfsnaam
        s.kvk          = kvk
        s.btw          = btw
        s.voornaam     = voornaam
        s.achternaam   = achternaam
        s.email        = email
        s.telefoon     = telefoon
        s.straat       = straat
        s.huisnummer   = huisnummer
        s.postcode     = postcode
        s.woonplaats   = woonplaats
        store.save(s)
        dismiss()
    }
}

// MARK: - Dashboard

private enum ShopSheet: String, Identifiable {
    case bewerken, afspraken, berichten, beheer, voorraad, openingstijden, agenda
    var id: String { rawValue }
}

struct ShopDashboardView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void

    @State private var actieveSheet: ShopSheet?
    @State private var showWebsiteProAlert = false
    @State private var artiesten:         [ArtiestProfiel] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    shopHeader

                    AandachtBanner(
                        berichten:  store.ongelezen,
                        afspraken:  store.afsprakenaandacht,
                        onBerichten:  { actieveSheet = .berichten },
                        onAfspraken:  { actieveSheet = .afspraken }
                    )

                    dashSection("BERICHTEN") {
                        Button(action: { actieveSheet = .berichten }) {
                            HStack {
                                Image(systemName: "message")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.5))
                                Text("Berichten")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.7))
                                Spacer()
                                if store.ongelezen > 0 {
                                    Text("\(store.ongelezen)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.black)
                                        .frame(minWidth: 20, minHeight: 20)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(white: 0.3))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    dashSection("AFSPRAKEN") {
                        Button(action: { actieveSheet = .afspraken }) {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.5))
                                Text("Bekijk afspraakaanvragen")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.7))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(white: 0.3))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    dashSection("OPENINGSTIJDEN & AGENDA") {
                        VStack(spacing: 0) {
                            Button(action: { actieveSheet = .openingstijden }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(white: 0.5))
                                    Text("Beheer openingstijden")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(white: 0.7))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(white: 0.3))
                                }
                            }
                            .buttonStyle(.plain)

                            Rectangle().fill(Color(white: 0.1)).frame(height: 1).padding(.vertical, 8)

                            Button(action: { actieveSheet = .agenda }) {
                                HStack {
                                    Image(systemName: "calendar.day.timeline.left")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(white: 0.5))
                                    Text("Weekagenda")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(white: 0.7))
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(white: 0.3))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    dashSection("VOORRAAD") {
                        Button(action: { actieveSheet = .voorraad }) {
                            HStack {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.5))
                                Text("Beheer voorraad")
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.7))
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(white: 0.3))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    dashSection("WEBSITE") {
                        let isPro = store.shop?.abonnementType == "pro" && store.heeftToegang
                        Button(action: { if isPro { } else { showWebsiteProAlert = true } }) {
                            HStack {
                                Image(systemName: isPro ? "globe" : "lock.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(isPro ? Color(white: 0.5) : Color(white: 0.3))
                                Text("Beheer website")
                                    .font(.system(size: 13))
                                    .foregroundColor(isPro ? Color(white: 0.7) : Color(white: 0.35))
                                Spacer()
                                if !isPro {
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .bold))
                                        .tracking(1)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 6).padding(.vertical, 3)
                                        .background(Color.white)
                                        .cornerRadius(4)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(white: 0.3))
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    if !artiesten.isEmpty {
                        dashSection("ARTIESTEN") {
                            VStack(spacing: 10) {
                                ForEach(artiesten) { a in
                                    HStack(spacing: 12) {
                                        Image(systemName: "paintbrush.pointed")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(white: 0.4))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(a.kunstnaam.isEmpty ? a.email : a.kunstnaam)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                            if !a.specialisatie.isEmpty {
                                                Text(a.specialisatie)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color(white: 0.4))
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                    if let s = store.shop {
                        dashSection("INFO") {
                            VStack(spacing: 10) {
                                infoRij(icon: "phone", tekst: s.telefoon)
                                infoRij(icon: "house", tekst: "\(s.straat) \(s.huisnummer), \(s.postcode) \(s.woonplaats)")
                                if !s.kvk.isEmpty { infoRij(icon: "doc.text", tekst: "KVK: \(s.kvk)") }
                                if !s.btw.isEmpty { infoRij(icon: "percent",  tekst: "BTW: \(s.btw)") }
                            }
                        }
                    }
                    Spacer().frame(height: 40)
                }
            }
        }
        .fullScreenCover(item: $actieveSheet) { sheet in
            switch sheet {
            case .bewerken:  ShopNAWView(onLogout: onLogout).environmentObject(store)
            case .afspraken: ShopAfsprakenView().environmentObject(store)
            case .berichten: ShopBerichtenView().environmentObject(store)
            case .beheer:    ShopBeheerView().environmentObject(store)
            case .voorraad:        VoorraadView().environmentObject(store)
            case .openingstijden:  ShopOpeningstijdenView().environmentObject(store)
            case .agenda:          ShopAgendaView().environmentObject(store)
            }
        }
        .alert("Pro-functie", isPresented: $showWebsiteProAlert) {
            Button("Sluiten", role: .cancel) {}
        } message: {
            Text("Beheer website is exclusief voor Pro-abonnees. Upgrade je abonnement om een automatische shopwebsite te genereren en beheren.")
        }
        .task {
            if let email = store.shop?.email {
                artiesten = await CloudKitManager.shared.fetchArtiesten(voorShop: email)
            }
        }
    }

    @ViewBuilder
    private var shopHeader: some View {
        VStack(spacing: 12) {
            if let data = store.profielFotoData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(white: 0.2), lineWidth: 1))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(white: 0.1))
                        .frame(width: 100, height: 100)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(white: 0.2), lineWidth: 1))
                    Image(systemName: "storefront")
                        .font(.system(size: 40))
                        .foregroundColor(Color(white: 0.25))
                }
            }
            if let s = store.shop {
                Text(s.bedrijfsnaam.isEmpty ? "\(s.voornaam) \(s.achternaam)" : s.bedrijfsnaam)
                    .font(.system(size: 22, weight: .black))
                    .tracking(3)
                    .foregroundColor(.white)
                if !s.woonplaats.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.3))
                        Text(s.woonplaats)
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.35))
                    }
                }
                Spacer().frame(height: 4)
                HStack(spacing: 14) {
                    Button(action: { actieveSheet = .bewerken }) {
                        Text("AANPASSEN")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(Color(white: 0.28))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button(action: { actieveSheet = .beheer }) {
                        Text("BEHEER")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(Color(white: 0.28))
                    }
                    Text("·").foregroundColor(Color(white: 0.15))
                    Button(action: { store.logout(); onLogout() }) {
                        Text("UITLOGGEN")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(Color(white: 0.28))
                    }
                }
            }
        }
        .padding(.top, 52)
        .padding(.bottom, 32)
    }

    @ViewBuilder
    private func dashSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(4)
                .foregroundColor(Color(white: 0.3))
            content()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        Rectangle().fill(Color(white: 0.1)).frame(height: 1)
    }

    @ViewBuilder
    private func infoRij(icon: String, tekst: String) -> some View {
        if !tekst.trimmingCharacters(in: .whitespaces).isEmpty {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.4))
                    .frame(width: 18)
                Text(tekst)
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.7))
                Spacer()
            }
        }
    }
}

// MARK: - Plan kiezen (eerste keer, direct na registratie / NAW)

struct ShopAbonnementKiezenView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void

    @State private var bezigPlanId: String? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 56)

                    Text("KIES JE PLAN")
                        .font(.system(size: 26, weight: .black))
                        .tracking(6)
                        .foregroundColor(.white)

                    Spacer().frame(height: 8)

                    Text("30 dagen gratis uitproberen")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(white: 0.55))

                    Spacer().frame(height: 4)

                    Text("Geen betaling nodig om te starten.\nNa je proefperiode maandelijks opzegbaar.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer().frame(height: 28)

                    VStack(spacing: 10) {
                        ForEach(shopPlannen) { plan in
                            AbonnementPlanKaart(
                                plan:      plan,
                                knopLabel: plan.isEnterprise ? "NEEM CONTACT OP" : "GRATIS STARTEN",
                                gekozen:   false,
                                bezig:     bezigPlanId == plan.id,
                                onKies:    { kies(plan) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 16)

                    Text("Via App Store · Maandelijks opzegbaar · Geen verborgen kosten")
                        .font(.system(size: 10))
                        .foregroundColor(Color(white: 0.22))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 60)
                }
            }

            // UITLOGGEN bovenaan
            Button(action: { store.logout(); onLogout() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                    Text("UITLOGGEN").font(.system(size: 11, weight: .semibold)).tracking(3)
                }
                .foregroundColor(Color(white: 0.3))
            }
            .padding(.leading, 24).padding(.top, 16)
        }
    }

    private func kies(_ plan: AbonnementPlan) {
        guard bezigPlanId == nil else { return }
        if plan.isEnterprise {
            let subj = "Enterprise abonnement aanvraag – \(store.shop?.bedrijfsnaam ?? "")".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let body = "Hallo,\n\nWij zijn geïnteresseerd in het Enterprise abonnement.\n\nShop: \(store.shop?.bedrijfsnaam ?? "")\nEmail: \(store.shop?.email ?? "")".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "mailto:info@tattoe.app?subject=\(subj)&body=\(body)") {
                UIApplication.shared.open(url)
            }
            store.kiesAbonnement("enterprise")
        } else {
            bezigPlanId = plan.id
            Task {
                let success = await store.koopAbonnement(planId: plan.id)
                if !success { store.kiesAbonnement(plan.id) }
                bezigPlanId = nil
            }
        }
    }
}

// MARK: - Abonnement verlopen scherm (na 30 dagen trial)

struct ShopAbonnementVerlopenView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void

    @State private var bezigPlanId: String? = nil

    var huidigPlanId: String { store.shop?.abonnementType ?? "" }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 56)

                    ZStack {
                        Circle()
                            .fill(Color(white: 0.08))
                            .frame(width: 70, height: 70)
                            .overlay(Circle().stroke(Color(white: 0.16), lineWidth: 1))
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 28))
                            .foregroundColor(Color(white: 0.3))
                    }

                    Spacer().frame(height: 20)

                    Text("PROEFPERIODE VERLOPEN")
                        .font(.system(size: 22, weight: .black))
                        .tracking(4)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 8)

                    Text("Kies een abonnement om verder te gaan.\nJe gegevens blijven bewaard.")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.35))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer().frame(height: 28)

                    VStack(spacing: 10) {
                        ForEach(shopPlannen) { plan in
                            AbonnementPlanKaart(
                                plan:      plan,
                                knopLabel: plan.isEnterprise ? "NEEM CONTACT OP" : "STARTEN",
                                gekozen:   plan.id == huidigPlanId,
                                bezig:     bezigPlanId == plan.id,
                                onKies:    { kies(plan) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 16)

                    Text("Via App Store · Maandelijks opzegbaar")
                        .font(.system(size: 10))
                        .foregroundColor(Color(white: 0.22))

                    Spacer().frame(height: 60)
                }
            }

            Button(action: { store.logout(); onLogout() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                    Text("UITLOGGEN").font(.system(size: 11, weight: .semibold)).tracking(3)
                }
                .foregroundColor(Color(white: 0.3))
            }
            .padding(.leading, 24).padding(.top, 16)
        }
    }

    private func kies(_ plan: AbonnementPlan) {
        guard bezigPlanId == nil else { return }
        if plan.isEnterprise {
            let subj = "Enterprise abonnement – \(store.shop?.bedrijfsnaam ?? "")".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "mailto:info@tattoe.app?subject=\(subj)") {
                UIApplication.shared.open(url)
            }
            store.activeerAbonnement(type: "enterprise")
        } else {
            bezigPlanId = plan.id
            Task {
                let _ = await store.koopAbonnement(planId: plan.id)
                bezigPlanId = nil
            }
        }
    }
}

// MARK: - Modus keuze (als klant / beheren)

struct ShopModeKeuzeView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void

    @State private var showBeheren  = false
    @State private var showAlsKlant = false
    @StateObject private var tijdelijkeKlantStore = KlantStore(tijdelijk: true)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color(white: 0.08))
                        .frame(width: 80, height: 80)
                        .overlay(Circle().stroke(Color(white: 0.18), lineWidth: 1))
                    Image(systemName: "storefront")
                        .font(.system(size: 32))
                        .foregroundColor(Color(white: 0.25))
                }

                Spacer().frame(height: 20)

                if let s = store.shop {
                    Text(s.bedrijfsnaam.isEmpty ? "\(s.voornaam) \(s.achternaam)" : s.bedrijfsnaam)
                        .font(.system(size: 22, weight: .black))
                        .tracking(3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    if !s.woonplaats.isEmpty {
                        Spacer().frame(height: 6)
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(Color(white: 0.3))
                            Text(s.woonplaats)
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.35))
                        }
                    }
                }

                Spacer().frame(height: 14)
                HStack(spacing: 8) {
                    if let planNaam = shopPlannen.first(where: { $0.id == store.shop?.abonnementType })?.naam {
                        Text(planNaam)
                            .font(.system(size: 9, weight: .bold))
                            .tracking(2.5)
                            .foregroundColor(Color(white: 0.4))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color(white: 0.08))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(white: 0.14), lineWidth: 1))
                    }
                    if store.trialActief {
                        Text("\(store.dagenResterend) dagen gratis")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(1.5)
                            .foregroundColor(Color(white: 0.32))
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color(white: 0.07))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(white: 0.12), lineWidth: 1))
                    }
                }

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    Button(action: {
                        tijdelijkeKlantStore.resetVoorTijdelijkGebruik()
                        tijdelijkeKlantStore.shopEmailVoorConsent = store.shop?.email ?? ""
                        tijdelijkeKlantStore.shopNaamVoorConsent  =
                            store.shop?.bedrijfsnaam.isEmpty == false
                            ? store.shop!.bedrijfsnaam
                            : "\(store.shop?.voornaam ?? "") \(store.shop?.achternaam ?? "")".trimmingCharacters(in: .whitespaces)
                        showAlsKlant = true
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle().fill(Color(white: 0.12)).frame(width: 44, height: 44)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(white: 0.5))
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("ALS KLANT")
                                    .font(.system(size: 14, weight: .black))
                                    .tracking(3)
                                    .foregroundColor(.white)
                                Text("Bekijk je shop zoals klanten dat zien")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(white: 0.4))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.25))
                        }
                        .padding(.horizontal, 20).padding(.vertical, 16)
                        .background(Color(white: 0.07))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.14), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityIdentifier("btn_als_klant")
                    .buttonStyle(.plain)

                    Button(action: { showBeheren = true }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle().fill(Color(white: 0.12)).frame(width: 44, height: 44)
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.black)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text("SHOP BEHEREN")
                                    .font(.system(size: 14, weight: .black))
                                    .tracking(3)
                                    .foregroundColor(.black)
                                Text("Afspraken, artiesten en instellingen")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(white: 0.5))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.4))
                        }
                        .padding(.horizontal, 20).padding(.vertical, 16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityIdentifier("btn_beheren")
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)

                Spacer()

                Button(action: { store.logout(); onLogout() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                        Text("UITLOGGEN").font(.system(size: 11, weight: .semibold)).tracking(3)
                    }
                    .foregroundColor(Color(white: 0.3))
                }
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showBeheren) {
            ShopDashboardView(onLogout: { showBeheren = false; onLogout() })
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showAlsKlant) {
            KlantFlowView(onLogout: { showAlsKlant = false })
                .environmentObject(tijdelijkeKlantStore)
        }
        .onChange(of: tijdelijkeKlantStore.tijdelijkSyncGedaan) { _, gedaan in
            if gedaan { showAlsKlant = false }
        }
        .onChange(of: showAlsKlant) { _, nieuw in
            if !nieuw { store.syncNu() }
        }
    }
}

// MARK: - Shop als klant weergave

struct ShopAlsKlantView: View {
    @EnvironmentObject var store: ShopStore
    @Environment(\.dismiss) private var dismiss

    @State private var artiesten: [ArtiestProfiel] = []
    @State private var laden = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    if let s = store.shop {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.1))
                                .frame(width: 90, height: 90)
                                .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 1))
                            Image(systemName: "storefront")
                                .font(.system(size: 36))
                                .foregroundColor(Color(white: 0.25))
                        }

                        Spacer().frame(height: 16)

                        Text(s.bedrijfsnaam.isEmpty ? "\(s.voornaam) \(s.achternaam)" : s.bedrijfsnaam)
                            .font(.system(size: 22, weight: .black))
                            .tracking(3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        if !s.woonplaats.isEmpty {
                            Spacer().frame(height: 6)
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(white: 0.3))
                                Text(s.woonplaats)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(white: 0.35))
                            }
                        }

                        Spacer().frame(height: 10)

                        Text("KLANTWEERGAVE")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(3)
                            .foregroundColor(Color(white: 0.25))
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(Color(white: 0.08))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(white: 0.14), lineWidth: 1))
                    }

                    Spacer().frame(height: 32)

                    if laden {
                        ProgressView().tint(.white).padding(.top, 20)
                    } else if !artiesten.isEmpty {
                        klantSectie("ARTIESTEN") {
                            VStack(spacing: 10) {
                                ForEach(artiesten) { a in
                                    HStack(spacing: 12) {
                                        Image(systemName: "paintbrush.pointed")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(white: 0.4))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(a.kunstnaam.isEmpty ? a.email : a.kunstnaam)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                            if !a.specialisatie.isEmpty {
                                                Text(a.specialisatie)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color(white: 0.4))
                                            }
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }

                    if let s = store.shop {
                        klantSectie("CONTACT") {
                            VStack(spacing: 10) {
                                if !s.telefoon.isEmpty {
                                    klantInfoRij(icon: "phone", tekst: s.telefoon)
                                }
                                let adres = "\(s.straat) \(s.huisnummer), \(s.postcode) \(s.woonplaats)"
                                    .trimmingCharacters(in: .whitespaces)
                                if adres.count > 4 {
                                    klantInfoRij(icon: "house", tekst: adres)
                                }
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }

            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                    Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                }
                .foregroundColor(Color(white: 0.35))
            }
            .padding(.leading, 24).padding(.top, 16)
        }
        .task {
            if let email = store.shop?.email {
                artiesten = await CloudKitManager.shared.fetchArtiesten(voorShop: email)
            }
            laden = false
        }
    }

    @ViewBuilder
    private func klantSectie<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(4)
                .foregroundColor(Color(white: 0.3))
            content()
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        Rectangle().fill(Color(white: 0.1)).frame(height: 1)
    }

    @ViewBuilder
    private func klantInfoRij(icon: String, tekst: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.4))
                .frame(width: 18)
            Text(tekst)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.7))
            Spacer()
        }
    }
}

// MARK: - Shop afspraken

struct ShopAfsprakenView: View {
    @EnvironmentObject var store: ShopStore
    @Environment(\.dismiss) private var dismiss

    @State private var afspraken: [Afspraak] = []
    @State private var laden = true
    @State private var bezig: Set<String> = []
    @State private var toonAgendaVoor: Afspraak? = nil
    @State private var agendaTekst: String? = nil
    @State private var toonAfzeggen: Afspraak? = nil

    private let datumFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "EEE d MMM yyyy · HH:mm"
        return f
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 56)
                Text("AFSPRAKEN")
                    .font(.system(size: 22, weight: .black))
                    .tracking(5)
                    .foregroundColor(.white)
                Spacer().frame(height: 6)
                Text("Inkomende aanvragen")
                    .font(.system(size: 11))
                    .tracking(1.5)
                    .foregroundColor(Color(white: 0.4))
                Spacer().frame(height: 24)

                if laden {
                    Spacer(); ProgressView().tint(.white); Spacer()
                } else if afspraken.isEmpty {
                    Spacer()
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundColor(Color(white: 0.2))
                    Spacer().frame(height: 16)
                    Text("Nog geen afspraakaanvragen")
                        .font(.system(size: 13)).tracking(1)
                        .foregroundColor(Color(white: 0.3))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(afspraken) { a in afspraakRij(a) }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                    Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                }
                .foregroundColor(Color(white: 0.35))
            }
            .padding(.leading, 24).padding(.top, 16)
        }
        .task { await herlaad() }
        .confirmationDialog("Agenda", isPresented: .init(
            get: { toonAgendaVoor != nil },
            set: { if !$0 { toonAgendaVoor = nil } }
        ), titleVisibility: .visible) {
            Button("Toevoegen aan agenda") {
                guard let a = toonAgendaVoor else { return }
                Task {
                    let naam = a.klantNaam.isEmpty ? a.klantEmail : a.klantNaam
                    let ok = await EventKitManager.shared.voegToe(
                        afspraakId: a.id, datum: a.datum,
                        titel: "Tattoo – \(naam)", notitie: a.notitie)
                    agendaTekst = ok ? "Toegevoegd met herinneringen." : "Toegang geweigerd."
                }
            }
            if let a = toonAgendaVoor, EventKitManager.shared.heeftAgendaItem(afspraakId: a.id) {
                Button("Verwijder uit agenda", role: .destructive) {
                    if let a = toonAgendaVoor { EventKitManager.shared.verwijder(afspraakId: a.id) }
                }
            }
            Button("Annuleer", role: .cancel) { toonAgendaVoor = nil }
        }
        .confirmationDialog("Afspraak afzeggen?", isPresented: .init(
            get: { toonAfzeggen != nil },
            set: { if !$0 { toonAfzeggen = nil } }
        ), titleVisibility: .visible) {
            Button("Ja, zeg af", role: .destructive) {
                guard let a = toonAfzeggen else { return }
                bezig.insert(a.id)
                Task { await store.annuleerAfspraak(a); bezig.remove(a.id); await herlaad() }
            }
            Button("Toch niet", role: .cancel) { toonAfzeggen = nil }
        }
        .alert(agendaTekst ?? "", isPresented: .init(
            get: { agendaTekst != nil },
            set: { if !$0 { agendaTekst = nil } }
        )) { Button("OK") { agendaTekst = nil } }
    }

    private func herlaad() async {
        laden = true
        if let email = store.shop?.email {
            let via_shop   = await CloudKitManager.shared.fetchAfspraken(shopEmail: email)
            let via_arties = await CloudKitManager.shared.fetchAfspraken(artiesEmail: email)
            let alle = (via_shop + via_arties).reduce(into: [String: Afspraak]()) { $0[$1.id] = $1 }
            afspraken = alle.values
                            .filter { !["geweigerd", "geannuleerd"].contains($0.status) }
                            .sorted { $0.datum < $1.datum }
        }
        if isTestomgeving {
            let testIds = Set(afspraken.map { $0.id })
            let extra = TestData.afsprakenShop.filter { !testIds.contains($0.id) }
            afspraken = (extra + afspraken).sorted { $0.datum < $1.datum }
        }
        laden = false
    }

    @ViewBuilder
    private func afspraakRij(_ a: Afspraak) -> some View {
        let isBevestigd = a.status == "bevestigd"
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(a.klantNaam.isEmpty ? a.klantEmail : a.klantNaam)
                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                    Text(datumFormatter.string(from: a.datum))
                        .font(.system(size: 11)).foregroundColor(Color(white: 0.5)).tracking(0.5)
                    if !a.notitie.isEmpty {
                        Text(a.notitie).font(.system(size: 12)).foregroundColor(Color(white: 0.6))
                            .lineLimit(2).padding(.top, 2)
                    }
                    statusLabel(a.status)
                }
                Spacer()
                if bezig.contains(a.id) {
                    ProgressView().tint(.white).frame(width: 52)
                } else if !isBevestigd && (a.status == "aangevraagd" || a.status == "arties_akkoord") {
                    VStack(spacing: 8) {
                        Button(action: { keur(a, goed: true) }) {
                            Text("OK")
                                .font(.system(size: 11, weight: .bold)).tracking(1).foregroundColor(.black)
                                .frame(width: 52, height: 32).background(Color.white).cornerRadius(5)
                        }
                        Button(action: { keur(a, goed: false) }) {
                            Text("NEE")
                                .font(.system(size: 11, weight: .bold)).tracking(1).foregroundColor(Color(white: 0.5))
                                .frame(width: 52, height: 32).background(Color(white: 0.1)).cornerRadius(5)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(white: 0.2), lineWidth: 1))
                        }
                    }
                }
            }
            if isBevestigd {
                HStack(spacing: 8) {
                    Button(action: { toonAgendaVoor = a }) {
                        Label(EventKitManager.shared.heeftAgendaItem(afspraakId: a.id) ? "In agenda" : "Agenda",
                              systemImage: "calendar.badge.plus")
                            .font(.system(size: 11, weight: .semibold)).tracking(1).foregroundColor(.black)
                            .frame(maxWidth: .infinity).frame(height: 32).background(Color.white).cornerRadius(5)
                    }
                    shopPrintKnop(a)
                    Button(action: { toonAfzeggen = a }) {
                        Text("Afzeggen")
                            .font(.system(size: 11, weight: .semibold)).tracking(1)
                            .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.3))
                            .frame(maxWidth: .infinity).frame(height: 32).background(Color(white: 0.1)).cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(red: 0.5, green: 0.15, blue: 0.15), lineWidth: 1))
                    }
                }
            } else {
                shopPrintKnop(a)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color(white: isBevestigd ? 0.09 : 0.07))
        .overlay(Rectangle().stroke(Color(white: isBevestigd ? 0.18 : 0.1), lineWidth: 1))
    }

    @ViewBuilder
    private func shopPrintKnop(_ a: Afspraak) -> some View {
        let naam = store.shop.map { $0.bedrijfsnaam.isEmpty ? "\($0.voornaam) \($0.achternaam)".trimmingCharacters(in: .whitespaces) : $0.bedrijfsnaam } ?? ""
        Button(action: { deelAfspraak(a, afdrukVoor: naam) }) {
            Label("Printen", systemImage: "printer")
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundColor(Color(white: 0.5))
                .frame(maxWidth: .infinity).frame(height: 32)
                .background(Color(white: 0.08)).cornerRadius(5)
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(white: 0.15), lineWidth: 1))
        }
    }

    @ViewBuilder
    private func statusLabel(_ status: String) -> some View {
        let (tekst, kleur): (String, Color) = switch status {
            case "shop_akkoord":   ("Wacht op artiest", Color.yellow)
            case "arties_akkoord": ("Artiest akkoord – jouw beurt", Color.orange)
            case "wacht_klant":    ("Wacht op klant", Color.blue)
            case "bevestigd":      ("Bevestigd door klant", Color(white: 0.6))
            default:               ("", .clear)
        }
        if !tekst.isEmpty {
            Text(tekst)
                .font(.system(size: 10, weight: .semibold)).tracking(1)
                .foregroundColor(kleur)
        }
    }

    private func keur(_ a: Afspraak, goed: Bool) {
        bezig.insert(a.id)
        Task {
            if goed { await store.keurAfspraakGoed(a) }
            else     { await store.weigerAfspraak(a)  }
            bezig.remove(a.id)
            await herlaad()
        }
    }
}

// MARK: - Shop Berichten

struct ShopBerichtenView: View {
    @EnvironmentObject var store: ShopStore
    @Environment(\.dismiss) private var dismiss

    private let df: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "d MMM · HH:mm"; return f
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 56)
                Text("BERICHTEN")
                    .font(.system(size: 22, weight: .black)).tracking(5).foregroundColor(.white)
                Spacer().frame(height: 24)
                if store.berichten.isEmpty {
                    Spacer()
                    Image(systemName: "message").font(.system(size: 40)).foregroundColor(Color(white: 0.2))
                    Spacer().frame(height: 16)
                    Text("Geen berichten").font(.system(size: 13)).tracking(1).foregroundColor(Color(white: 0.3))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(store.berichten) { b in
                                berichtRij(b).onAppear { store.markeerGelezen(b.id) }
                            }
                        }
                        .padding(.horizontal, 24).padding(.bottom, 40)
                    }
                }
            }
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                    Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                }
                .foregroundColor(Color(white: 0.35))
            }
            .padding(.leading, 24).padding(.top, 16)
        }
    }

    @ViewBuilder
    private func berichtRij(_ b: Bericht) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconNaam(b.type))
                    .font(.system(size: 13)).foregroundColor(kleurVoor(b.type))
                Text(titeltje(b.type))
                    .font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(kleurVoor(b.type))
                Spacer()
                Text(df.string(from: b.datum))
                    .font(.system(size: 10)).foregroundColor(Color(white: 0.35))
            }
            Text(b.tekst)
                .font(.system(size: 13)).foregroundColor(Color(white: 0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color(white: 0.07))
        .overlay(Rectangle().stroke(Color(white: 0.1), lineWidth: 1))
    }

    private func titeltje(_ type: String) -> String {
        switch type {
        case "aangevraagd":                   "NIEUWE AANVRAAG"
        case "arties_akkoord","shop_akkoord": "AKKOORD ONTVANGEN"
        case "bevestigd":                     "AFSPRAAK BEVESTIGD"
        case "geweigerd":                     "AFSPRAAK GEWEIGERD"
        default:                              type.uppercased()
        }
    }

    private func kleurVoor(_ type: String) -> Color {
        switch type {
        case "aangevraagd":                   .orange
        case "arties_akkoord","shop_akkoord": Color(white: 0.7)
        case "bevestigd":                     Color(white: 0.7)
        case "geweigerd":                     Color(red: 0.9, green: 0.3, blue: 0.3)
        default:                              Color(white: 0.5)
        }
    }

    private func iconNaam(_ type: String) -> String {
        switch type {
        case "aangevraagd":                   "calendar.badge.plus"
        case "arties_akkoord","shop_akkoord": "checkmark.circle"
        case "bevestigd":                     "checkmark.seal"
        case "geweigerd":                     "xmark.circle"
        default:                              "message"
        }
    }
}

// MARK: - Shop Beheer & Administratie

struct ShopBeheerView: View {
    @EnvironmentObject var store: ShopStore
    @Environment(\.dismiss) private var dismiss

    @State private var afspraken:    [Afspraak] = []
    @State private var laden         = true
    @State private var geselecteerdJaar = Calendar.current.component(.year, from: Date())

    private var jaren: [Int] {
        let huidig = Calendar.current.component(.year, from: Date())
        return Array((huidig - 4)...huidig).reversed()
    }

    private var afsprakenJaar: [Afspraak] {
        afspraken.filter {
            Calendar.current.component(.year, from: $0.datum) == geselecteerdJaar
        }
    }

    private var perMaand: [(maand: Int, items: [Afspraak])] {
        let cal = Calendar.current
        let groepen = Dictionary(grouping: afsprakenJaar) {
            cal.component(.month, from: $0.datum)
        }
        return (1...12).compactMap { m in
            guard let items = groepen[m], !items.isEmpty else { return nil }
            return (maand: m, items: items)
        }
    }

    private var bevestigdJaar: [Afspraak] { afsprakenJaar.filter { $0.status == "bevestigd" } }

    private var druksteMaand: String {
        guard let (m, items) = perMaand.max(by: { $0.items.count < $1.items.count }) else { return "–" }
        return "\(maandNaam(m)) (\(items.count))"
    }

    private var meestVoorkomendKlant: String {
        let counts = Dictionary(grouping: afsprakenJaar) { $0.klantEmail }
            .mapValues { $0.count }
        guard let (email, count) = counts.max(by: { $0.value < $1.value }) else { return "–" }
        let naam = afspraken.first { $0.klantEmail == email }?.klantNaam ?? ""
        return naam.isEmpty ? "\(email) (\(count)×)" : "\(naam) (\(count)×)"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer().frame(height: 56)
                Text("ADMINISTRATIE")
                    .font(.system(size: 20, weight: .black)).tracking(5).foregroundColor(.white)
                Spacer().frame(height: 6)
                Text("Overzichten & exports")
                    .font(.system(size: 11)).tracking(1.5).foregroundColor(Color(white: 0.4))
                Spacer().frame(height: 24)

                // Jaar-kiezer
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(jaren, id: \.self) { jaar in
                            Button(action: { geselecteerdJaar = jaar }) {
                                Text("\(jaar)")
                                    .font(.system(size: 12, weight: .semibold)).tracking(1)
                                    .foregroundColor(geselecteerdJaar == jaar ? .black : Color(white: 0.4))
                                    .frame(height: 32).padding(.horizontal, 16)
                                    .background(geselecteerdJaar == jaar ? Color.white : Color(white: 0.1))
                                    .cornerRadius(5)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
                Spacer().frame(height: 20)

                if laden {
                    Spacer(); ProgressView().tint(.white); Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
                            // Statistieken
                            beheerSectie("STATISTIEKEN \(geselecteerdJaar)") {
                                statRij("Totaal afspraken",    "\(afsprakenJaar.count)")
                                statRij("Bevestigd",           "\(bevestigdJaar.count)")
                                statRij("Drukste maand",       druksteMaand)
                                statRij("Meeste klant",        meestVoorkomendKlant)
                            }

                            // Maandoverzicht
                            if !perMaand.isEmpty {
                                beheerSectie("MAANDOVERZICHT") {
                                    ForEach(perMaand, id: \.maand) { item in
                                        maandRij(item.maand, items: item.items)
                                    }
                                }
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .font(.system(size: 30)).foregroundColor(Color(white: 0.2))
                                    Text("Geen afspraken in \(geselecteerdJaar)")
                                        .font(.system(size: 13)).foregroundColor(Color(white: 0.3))
                                }
                                .padding(40)
                            }

                            // Exports
                            beheerSectie("EXPORT") {
                                exportKnop(
                                    icon: "tablecells",
                                    titel: "CSV – Belastingdienst / boekhouding",
                                    subtitel: "Alle afspraken \(geselecteerdJaar) als spreadsheet",
                                    actie: exportCSV
                                )
                                Divider().background(Color(white: 0.1))
                                exportKnop(
                                    icon: "doc.text",
                                    titel: "PDF – Jaaroverzicht \(geselecteerdJaar)",
                                    subtitel: "\(bevestigdJaar.count) bevestigde afspraken",
                                    actie: exportJaaroverzichtPDF
                                )
                            }
                        }
                        .padding(.horizontal, 24).padding(.bottom, 40)
                    }
                }
            }

            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                    Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                }
                .foregroundColor(Color(white: 0.35))
            }
            .padding(.leading, 24).padding(.top, 16)
        }
        .task { await herlaad() }
    }

    // MARK: Subviews

    @ViewBuilder
    private func beheerSectie<Content: View>(_ titel: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titel)
                .font(.system(size: 9, weight: .bold)).tracking(3)
                .foregroundColor(Color(white: 0.3))
                .padding(.horizontal, 16).padding(.top, 20).padding(.bottom, 10)
            content()
        }
        .background(Color(white: 0.06))
        .overlay(Rectangle().stroke(Color(white: 0.1), lineWidth: 1))
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func statRij(_ label: String, _ waarde: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13)).foregroundColor(Color(white: 0.55))
            Spacer()
            Text(waarde)
                .font(.system(size: 13, weight: .semibold)).foregroundColor(.white)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        Divider().background(Color(white: 0.1)).padding(.horizontal, 16)
    }

    @ViewBuilder
    private func maandRij(_ maand: Int, items: [Afspraak]) -> some View {
        let bevestigd = items.filter { $0.status == "bevestigd" }.count
        HStack {
            Text(maandNaam(maand))
                .font(.system(size: 13)).foregroundColor(Color(white: 0.7))
                .frame(width: 100, alignment: .leading)
            Text("\(items.count) afspraken")
                .font(.system(size: 12)).foregroundColor(Color(white: 0.4))
            Spacer()
            Text("\(bevestigd) ✓")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(bevestigd > 0 ? Color(white: 0.7) : Color(white: 0.25))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        Divider().background(Color(white: 0.1)).padding(.horizontal, 16)
    }

    @ViewBuilder
    private func exportKnop(icon: String, titel: String, subtitel: String, actie: @escaping () -> Void) -> some View {
        Button(action: actie) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18)).foregroundColor(Color(white: 0.4))
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 3) {
                    Text(titel)
                        .font(.system(size: 13)).foregroundColor(Color(white: 0.8))
                    Text(subtitel)
                        .font(.system(size: 11)).foregroundColor(Color(white: 0.35))
                }
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14)).foregroundColor(Color(white: 0.3))
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: Acties

    private func herlaad() async {
        laden = true
        if let email = store.shop?.email {
            afspraken = await CloudKitManager.shared.fetchAfspraken(shopEmail: email)
        }
        laden = false
    }

    private func exportCSV() {
        let url = exportAfsprakenCSV(afsprakenJaar, jaar: geselecteerdJaar)
        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        presenteerVC(av)
    }

    private func exportJaaroverzichtPDF() {
        let A4 = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: A4)
        let naam = store.shop.map {
            $0.bedrijfsnaam.isEmpty
                ? "\($0.voornaam) \($0.achternaam)".trimmingCharacters(in: .whitespaces)
                : $0.bedrijfsnaam
        } ?? "Shop"
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("tattoe_jaaroverzicht_\(geselecteerdJaar).pdf")

        let dfDatum = DateFormatter()
        dfDatum.locale = Locale(identifier: "nl_NL")
        dfDatum.dateFormat = "dd MMM yyyy · HH:mm"

        let dfGen = DateFormatter()
        dfGen.locale = Locale(identifier: "nl_NL")
        dfGen.dateStyle = .long

        try? renderer.writePDF(to: url) { ctx in
            var paginaNr = 0
            func nieuwePagina() {
                ctx.beginPage()
                paginaNr += 1
            }

            func attrs(_ size: CGFloat, _ weight: UIFont.Weight, _ color: UIColor = .black,
                       kern: CGFloat = 0) -> [NSAttributedString.Key: Any] {
                var d: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: size, weight: weight),
                    .foregroundColor: color
                ]
                if kern != 0 { d[.kern] = kern }
                return d
            }

            let margin: CGFloat = 56
            nieuwePagina()
            var y: CGFloat = margin

            // Koptekst
            "TATTOE".draw(at: CGPoint(x: margin, y: y),
                          withAttributes: attrs(24, .black, kern: 5))
            y += 34
            UIColor.black.setFill()
            UIBezierPath(rect: CGRect(x: margin, y: y, width: A4.width - margin * 2, height: 1.5)).fill()
            y += 12
            "JAAROVERZICHT \(geselecteerdJaar) — \(naam.uppercased())".draw(
                at: CGPoint(x: margin, y: y),
                withAttributes: attrs(9, .semibold, .darkGray, kern: 2))
            y += 30

            // Samenvatting
            let samenvattingLines = [
                ("Totaal afspraken",   "\(afsprakenJaar.count)"),
                ("Bevestigd",          "\(bevestigdJaar.count)"),
                ("Afgezegd / geweigerd",
                 "\(afsprakenJaar.filter { ["geannuleerd","geweigerd"].contains($0.status) }.count)"),
                ("Gegenereerd op",     dfGen.string(from: Date()))
            ]
            for (label, waarde) in samenvattingLines {
                label.draw(at: CGPoint(x: margin, y: y),
                           withAttributes: attrs(9, .semibold, .gray, kern: 2))
                waarde.draw(at: CGPoint(x: margin + 160, y: y),
                            withAttributes: attrs(12, .regular))
                y += 20
            }
            y += 20

            // Per maand
            let gesorteerd = afsprakenJaar.sorted { $0.datum < $1.datum }
            let cal = Calendar.current
            let groepen = Dictionary(grouping: gesorteerd) { cal.component(.month, from: $0.datum) }

            for maand in 1...12 {
                guard let items = groepen[maand], !items.isEmpty else { continue }

                if y > A4.height - 160 { nieuwePagina(); y = margin }

                // Maandkop
                UIColor(white: 0.9, alpha: 1).setFill()
                UIBezierPath(rect: CGRect(x: margin, y: y, width: A4.width - margin * 2, height: 22)).fill()
                "\(maandNaam(maand).uppercased()) — \(items.count) AFSPRAKEN".draw(
                    at: CGPoint(x: margin + 8, y: y + 5),
                    withAttributes: attrs(9, .bold, .darkGray, kern: 2))
                y += 30

                for a in items {
                    if y > A4.height - 80 { nieuwePagina(); y = margin }
                    let datum = dfDatum.string(from: a.datum)
                    let klant = a.klantNaam.isEmpty ? a.klantEmail : "\(a.klantNaam) <\(a.klantEmail)>"
                    let status: String = {
                        switch a.status {
                        case "bevestigd": return "✓"
                        case "geannuleerd","geweigerd": return "✗"
                        default: return "·"
                        }
                    }()
                    "\(status)  \(datum)".draw(at: CGPoint(x: margin, y: y),
                                               withAttributes: attrs(10, .semibold))
                    klant.draw(at: CGPoint(x: margin + 20, y: y + 14),
                               withAttributes: attrs(9, .regular, .darkGray))
                    y += 32
                }
                y += 8
            }

            // Voettekst
            let fy = A4.height - 30
            UIColor(white: 0.8, alpha: 1).setFill()
            UIBezierPath(rect: CGRect(x: margin, y: fy - 6, width: A4.width - margin * 2, height: 0.5)).fill()
            "Tattoe App – \(naam) – Jaaroverzicht \(geselecteerdJaar)".draw(
                at: CGPoint(x: margin, y: fy),
                withAttributes: attrs(8, .regular, .lightGray))
        }

        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        presenteerVC(av)
    }

    // MARK: Helpers

    private func maandNaam(_ m: Int) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "nl_NL")
        return df.monthSymbols[m - 1].capitalized
    }
}

// MARK: - Openingstijden

private let dagNamen = ["Maandag", "Dinsdag", "Woensdag", "Donderdag", "Vrijdag", "Zaterdag", "Zondag"]

struct OpeningsDag: Identifiable, Codable {
    let id: Int       // 0 = ma … 6 = zo
    var geopend: Bool
    var van:     String // "09:00"
    var tot:     String // "17:00"
}

struct ShopOpeningstijdenView: View {
    @EnvironmentObject var store: ShopStore
    @Environment(\.dismiss) private var dismiss

    @State private var dagen:    [OpeningsDag] = ShopOpeningstijdenView.laadDagen()
    @State private var vakantie: Bool = false
    @State private var gesloten: Bool = false
    @State private var opgeslagen = false

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 72)

                    Text("OPENINGSTIJDEN")
                        .font(.system(size: 22, weight: .black))
                        .tracking(5)
                        .foregroundColor(.white)
                        .padding(.bottom, 6)

                    Text("Geef aan op welke dagen en tijden uw shop open is.")
                        .font(.system(size: 11))
                        .tracking(0.5)
                        .foregroundColor(Color(white: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 32)

                    VStack(spacing: 1) {
                        ForEach($dagen) { $dag in
                            DagRij(dag: $dag)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    VStack(spacing: 1) {
                        StatusToggleRij(label: "Vakantie",
                                        icoon: "sun.max",
                                        actief: $vakantie)
                        StatusToggleRij(label: "Gesloten",
                                        icoon: "lock.fill",
                                        actief: $gesloten)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 32)

                    if opgeslagen {
                        Text("Opgeslagen — agenda bijgewerkt ✓")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(white: 0.5))
                            .padding(.bottom, 8)
                    }

                    Button(action: slaOp) {
                        Text("OPSLAAN")
                            .font(.system(size: 14, weight: .black))
                            .tracking(4)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }

            // Header
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                        Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                    }
                    .foregroundColor(Color(white: 0.35))
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
        }
        .onAppear {
            let email = store.shop?.email ?? ""
            vakantie = UserDefaults.standard.bool(forKey: "vakantie_\(email)")
            gesloten = UserDefaults.standard.bool(forKey: "gesloten_\(email)")
        }
    }

    private func slaOp() {
        let email = store.shop?.email ?? ""
        if let data = try? JSONEncoder().encode(dagen) {
            UserDefaults.standard.set(data, forKey: ShopOpeningstijdenView.openingstijdenKey(email))
        }
        UserDefaults.standard.set(vakantie, forKey: "vakantie_\(email)")
        UserDefaults.standard.set(gesloten, forKey: "gesloten_\(email)")
        genereerTijdBlokken()
        Task { await syncOpeningstijden() }
        withAnimation { opgeslagen = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { opgeslagen = false }
    }

    private func genereerTijdBlokken() {
        guard let email = store.shop?.email, !email.isEmpty else { return }
        let cal = Calendar.current
        let vandaag = cal.startOfDay(for: Date())
        let wd = cal.component(.weekday, from: vandaag)
        let daysToMon = (wd == 1 ? -6 : 2 - wd)
        guard let thisMon = cal.date(byAdding: .day, value: daysToMon, to: vandaag) else { return }

        var blokken: [TijdBlok] = []
        for weekOff in 0..<12 {
            guard let weekMon = cal.date(byAdding: .weekOfYear, value: weekOff, to: thisMon) else { continue }
            for dagIdx in 0..<7 {
                let dag = dagen[dagIdx]
                guard dag.geopend else { continue }
                guard let datum = cal.date(byAdding: .day, value: dagIdx, to: weekMon) else { continue }
                blokken.append(TijdBlok(datum: datum, van: dag.van, tot: dag.tot))
            }
        }
        if let data = try? JSONEncoder().encode(blokken) {
            UserDefaults.standard.set(data, forKey: "tijdblokken_\(email)")
        }
    }

    private func syncOpeningstijden() async {
        guard let email = store.shop?.email, !email.isEmpty else { return }
        var regels = dagen.map { dag -> String in
            guard dag.geopend else { return "\(dagNamen[dag.id]): Gesloten" }
            return "\(dagNamen[dag.id]): \(dag.van) – \(dag.tot)"
        }
        if vakantie { regels.append("Status: Vakantie") }
        if gesloten { regels.append("Status: Gesloten") }
        await CloudKitManager.shared.slaOpeningstijdenOp(shopEmail: email, tekst: regels.joined(separator: "\n"))
    }

    static func laadDagen(voorShop email: String = "") -> [OpeningsDag] {
        let key = openingstijdenKey(email)
        if let data = UserDefaults.standard.data(forKey: key),
           let opgeslagen = try? JSONDecoder().decode([OpeningsDag].self, from: data) {
            return opgeslagen
        }
        return (0..<7).map { i in
            OpeningsDag(id: i, geopend: i < 5, van: "09:00", tot: "17:00")
        }
    }

    static func openingstijdenKey(_ email: String) -> String {
        "openingstijden_\(email)"
    }
}

private struct DagRij: View {
    @Binding var dag: OpeningsDag

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Text(dagNamen[dag.id])
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(dag.geopend ? .white : Color(white: 0.35))
                    .frame(width: 90, alignment: .leading)

                Spacer()

                if dag.geopend {
                    HStack(spacing: 6) {
                        TijdVeld(tijd: $dag.van)
                        Text("–")
                            .foregroundColor(Color(white: 0.4))
                            .font(.system(size: 13))
                        TijdVeld(tijd: $dag.tot)
                    }
                } else {
                    Text("Gesloten")
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.3))
                }

                Toggle("", isOn: $dag.geopend)
                    .labelsHidden()
                    .tint(Color(white: 0.7))
                    .frame(width: 44)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(white: dag.geopend ? 0.07 : 0.04))

            Rectangle()
                .fill(Color(white: 0.1))
                .frame(height: 1)
        }
    }
}

private struct StatusToggleRij: View {
    let label:  String
    let icoon:  String
    @Binding var actief: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: icoon)
                    .font(.system(size: 13))
                    .foregroundColor(actief ? .white : Color(white: 0.35))
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(actief ? .white : Color(white: 0.35))
                    .frame(width: 90, alignment: .leading)
                Spacer()
                if actief {
                    Text("AAN")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundColor(Color(white: 0.45))
                }
                Toggle("", isOn: $actief)
                    .labelsHidden()
                    .tint(Color(white: 0.7))
                    .frame(width: 44)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(white: actief ? 0.07 : 0.04))

            Rectangle()
                .fill(Color(white: 0.1))
                .frame(height: 1)
        }
    }
}

private struct TijdVeld: View {
    @Binding var tijd: String

    var body: some View {
        TextField("", text: $tijd)
            .font(.system(size: 13, weight: .medium).monospacedDigit())
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .keyboardType(.numbersAndPunctuation)
            .frame(width: 52, height: 32)
            .background(Color(white: 0.12))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(white: 0.2), lineWidth: 1))
    }
}

// MARK: - TijdBlok

struct TijdBlok: Identifiable, Codable {
    var id:    String = UUID().uuidString
    var datum: Date
    var van:   String   // "09:00"
    var tot:   String   // "17:00"
}

// MARK: - ShopAgendaView

private let agendaStartUur = 7
private let agendaEindUur  = 21

struct ShopAgendaView: View {
    @EnvironmentObject var store: ShopStore
    @Environment(\.dismiss) private var dismiss

    @State private var weekOffset: Int      = 0
    @State private var afspraken:  [Afspraak] = []

    private let uurHoogte:   CGFloat = 60
    private let dagBreedte:  CGFloat = 54
    private let tijdBreedte: CGFloat = 34

    // MARK: - Helpers

    private var weekDagen: [Date] {
        let cal = Calendar.current
        let vandaag = cal.startOfDay(for: Date())
        let wd = cal.component(.weekday, from: vandaag)
        let daysToMon = (wd == 1 ? -6 : 2 - wd)
        guard let monday = cal.date(byAdding: .day, value: daysToMon + weekOffset * 7, to: vandaag)
        else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: monday) }
    }

    private var weekLabel: String {
        guard let first = weekDagen.first, let last = weekDagen.last else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "nl_NL")
        f.dateFormat = "d MMM"
        return "\(f.string(from: first)) – \(f.string(from: last))"
    }

    private var totaalHoogte: CGFloat {
        CGFloat(agendaEindUur - agendaStartUur) * uurHoogte
    }

    private func blokken(voor datum: Date) -> [TijdBlok] {
        guard let email = store.shop?.email,
              let data = UserDefaults.standard.data(forKey: "tijdblokken_\(email)"),
              let alle = try? JSONDecoder().decode([TijdBlok].self, from: data)
        else { return [] }
        return alle.filter { Calendar.current.isDate($0.datum, inSameDayAs: datum) }
    }

    private func afsprakenOp(_ datum: Date) -> [Afspraak] {
        afspraken.filter { Calendar.current.isDate($0.datum, inSameDayAs: datum) }
    }

    private func yOff(_ tijdStr: String) -> CGFloat {
        let p = tijdStr.split(separator: ":").compactMap { Int($0) }
        guard p.count == 2 else { return 0 }
        return CGFloat((p[0] - agendaStartUur) * 60 + p[1]) / 60.0 * uurHoogte
    }

    private func blokHoogte(_ van: String, _ tot: String) -> CGFloat {
        max(yOff(tot) - yOff(van), uurHoogte * 0.5)
    }

    private func tijdLabel(_ datum: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: datum)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    // Time axis
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 90)
                        ForEach(agendaStartUur...agendaEindUur, id: \.self) { uur in
                            Text(String(format: "%02d", uur))
                                .font(.system(size: 9, weight: .medium).monospacedDigit())
                                .foregroundColor(Color(white: 0.28))
                                .frame(width: tijdBreedte, height: uurHoogte, alignment: .top)
                                .padding(.top, -3)
                        }
                    }

                    // Day columns
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 2) {
                            ForEach(weekDagen, id: \.self) { dag in
                                dagKolom(dag)
                            }
                        }
                    }
                }
                .padding(.bottom, 40)
            }

            // Fixed header
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                            Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                        }
                        .foregroundColor(Color(white: 0.35))
                    }
                    Spacer()
                    Text("AGENDA")
                        .font(.system(size: 14, weight: .black))
                        .tracking(5)
                        .foregroundColor(.white)
                    Spacer()
                    // Balance
                    HStack(spacing: 8) {
                        Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                        Text("TERUG").font(.system(size: 11, weight: .semibold)).tracking(3)
                    }
                    .foregroundColor(.clear)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Color.black)

                HStack(spacing: 20) {
                    Button(action: { weekOffset -= 1 }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(white: 0.45))
                    }
                    Text(weekLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(Color(white: 0.65))
                        .frame(minWidth: 130)
                    Button(action: { weekOffset += 1 }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(white: 0.45))
                    }
                }
                .padding(.vertical, 8)
                .background(Color.black)

                Rectangle().fill(Color(white: 0.1)).frame(height: 1)
            }
        }
        .task { await herlaad() }
    }

    // MARK: - Day column

    private func dagKolom(_ datum: Date) -> some View {
        let cal = Calendar.current
        let isVandaag = cal.isDateInToday(datum)
        let dagBlokken = blokken(voor: datum)
        let dagAfspraken = afsprakenOp(datum)

        return VStack(spacing: 0) {
            dagHeader(datum, isVandaag: isVandaag)

            ZStack(alignment: .topLeading) {
                // Background hour rows
                VStack(spacing: 0) {
                    ForEach(0..<(agendaEindUur - agendaStartUur), id: \.self) { _ in
                        VStack(spacing: 0) {
                            Color(white: 0.07).frame(height: uurHoogte / 2)
                            Color(white: 0.05).frame(height: uurHoogte / 2)
                        }
                    }
                }

                // Open hours blocks
                ForEach(dagBlokken) { blok in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(white: 0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color(white: 0.24), lineWidth: 0.5)
                        )
                        .frame(width: dagBreedte - 4, height: blokHoogte(blok.van, blok.tot))
                        .offset(x: 2, y: yOff(blok.van))
                }

                // Afspraken
                ForEach(dagAfspraken) { a in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: dagBreedte - 8, height: uurHoogte * 0.9)
                        .overlay(
                            Text(a.klantNaam)
                                .font(.system(size: 7, weight: .semibold))
                                .foregroundColor(.black)
                                .lineLimit(2)
                                .padding(3),
                            alignment: .topLeading
                        )
                        .offset(x: 4, y: yOff(tijdLabel(a.datum)))
                }
            }
            .frame(width: dagBreedte, height: totaalHoogte)
        }
    }

    private func dagHeader(_ datum: Date, isVandaag: Bool) -> some View {
        let cal = Calendar.current
        let dagNum = cal.component(.day, from: datum)
        let wd = cal.component(.weekday, from: datum)
        let dagIdx = wd == 1 ? 6 : wd - 2
        let korteNaam = String(dagNamen[dagIdx].prefix(2)).uppercased()

        return VStack(spacing: 3) {
            Text(korteNaam)
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundColor(isVandaag ? .white : Color(white: 0.35))
            ZStack {
                if isVandaag {
                    Circle().fill(Color.white).frame(width: 24, height: 24)
                }
                Text("\(dagNum)")
                    .font(.system(size: 13, weight: isVandaag ? .bold : .regular))
                    .foregroundColor(isVandaag ? .black : Color(white: 0.5))
            }
        }
        .frame(width: dagBreedte, height: 44)
        .background(isVandaag ? Color(white: 0.09) : Color.clear)
    }

    // MARK: - Load

    private func herlaad() async {
        guard let email = store.shop?.email else { return }
        let via_shop   = await CloudKitManager.shared.fetchAfspraken(shopEmail: email)
        let via_arties = await CloudKitManager.shared.fetchAfspraken(artiesEmail: email)
        let alle = (via_shop + via_arties).reduce(into: [String: Afspraak]()) { $0[$1.id] = $1 }
        await MainActor.run {
            afspraken = Array(alle.values).sorted { $0.datum < $1.datum }
        }
    }
}
