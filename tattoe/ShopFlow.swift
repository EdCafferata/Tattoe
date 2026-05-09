import SwiftUI
import AuthenticationServices

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
                } else if !store.heeftToegang {
                    ShopAbonnementView(onLogout: onLogout)
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
            Task {
                await store.checkCloud(appleUserID: cred.user)
                if !store.isLoggedIn {
                    let shop = Shop(
                        authMethod:   .apple,
                        appleUserID:  cred.user,
                        bedrijfsnaam: "",
                        kvk:          "",
                        btw:          "",
                        voornaam:     cred.fullName?.givenName  ?? "",
                        achternaam:   cred.fullName?.familyName ?? "",
                        email:        cred.email ?? "",
                        wachtwoord:   "",
                        telefoon:     "",
                        straat:       "",
                        huisnummer:   "",
                        postcode:     "",
                        woonplaats:   ""
                    )
                    store.save(shop)
                }
            }
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

    @State private var email      = ""
    @State private var wachtwoord = ""
    @State private var fout: String?
    @State private var bezig = false
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

                    Spacer().frame(height: 36)

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

            // Vaste OPSLAAN knop onderaan
            VStack(spacing: 0) {
                Spacer()
                Button(action: opslaan) {
                    Text("OPSLAAN")
                        .font(.system(size: 14, weight: .black))
                        .tracking(5)
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

struct ShopDashboardView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void

    @State private var showBewerken  = false
    @State private var showAfspraken = false
    @State private var artiesten:    [ArtiestProfiel] = []

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    shopHeader
                    dashSection("AFSPRAKEN") {
                        Button(action: { showAfspraken = true }) {
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
        .fullScreenCover(isPresented: $showBewerken) {
            ShopNAWView(onLogout: onLogout).environmentObject(store)
        }
        .fullScreenCover(isPresented: $showAfspraken) {
            ShopAfsprakenView().environmentObject(store)
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
            ZStack {
                Circle()
                    .fill(Color(white: 0.1))
                    .frame(width: 100, height: 100)
                    .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 1))
                Image(systemName: "storefront")
                    .font(.system(size: 40))
                    .foregroundColor(Color(white: 0.25))
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
                    Button(action: { showBewerken = true }) {
                        Text("AANPASSEN")
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

// MARK: - Abonnement scherm (proefperiode verlopen)

struct ShopAbonnementView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void

    @State private var activeren = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color(white: 0.08))
                        .frame(width: 90, height: 90)
                        .overlay(Circle().stroke(Color(white: 0.18), lineWidth: 1))
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundColor(Color(white: 0.35))
                }

                Spacer().frame(height: 28)

                Text("PROEFPERIODE VERLOPEN")
                    .font(.system(size: 20, weight: .black))
                    .tracking(4)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 10)

                Text("Je gratis proefperiode van 30 dagen is verlopen.\nKies een abonnement om door te gaan.")
                    .font(.system(size: 13))
                    .foregroundColor(Color(white: 0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer().frame(height: 40)

                // Abonnement kaart
                VStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("TATTOE SHOP")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(4)
                            .foregroundColor(Color(white: 0.4))
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("€")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Text("19,95")
                                .font(.system(size: 40, weight: .black))
                                .foregroundColor(.white)
                            Text("/ maand")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.4))
                        }
                    }
                    .padding(.top, 28).padding(.bottom, 20)

                    Rectangle().fill(Color(white: 0.12)).frame(height: 1)

                    VStack(spacing: 12) {
                        planRij("Onbeperkt afspraken beheren")
                        planRij("Artiesten aan je shop koppelen")
                        planRij("Zichtbaar in de Tattoe app")
                        planRij("Klantprofiel & reviews")
                    }
                    .padding(.vertical, 20)
                }
                .background(Color(white: 0.07))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(white: 0.15), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

                Spacer().frame(height: 28)

                Button(action: startAbonnement) {
                    Group {
                        if activeren {
                            ProgressView().tint(.black)
                        } else {
                            Text("START ABONNEMENT")
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
                .disabled(activeren)
                .padding(.horizontal, 24)

                Spacer().frame(height: 14)

                Text("Abonnement via App Store (in-app aankoop)")
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.25))

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
    }

    @ViewBuilder
    private func planRij(_ tekst: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(white: 0.5))
            Text(tekst)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.6))
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func startAbonnement() {
        guard !activeren else { return }
        activeren = true
        Task {
            // TODO: StoreKit in-app purchase flow hier inbouwen
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            store.activeerAbonnement()
            activeren = false
        }
    }
}

// MARK: - Modus keuze (als klant / beheren)

struct ShopModeKeuzeView: View {
    @EnvironmentObject var store: ShopStore
    let onLogout: () -> Void

    @State private var showBeheren  = false
    @State private var showAlsKlant = false

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

                if store.trialActief {
                    Spacer().frame(height: 16)
                    Text("\(store.dagenResterend) dag\(store.dagenResterend == 1 ? "" : "en") proefperiode resterend")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(1.5)
                        .foregroundColor(Color(white: 0.35))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.08))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(white: 0.14), lineWidth: 1))
                }

                Spacer().frame(height: 48)

                VStack(spacing: 12) {
                    Button(action: { showAlsKlant = true }) {
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
            ShopAlsKlantView()
                .environmentObject(store)
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
        .task {
            if let email = store.shop?.email {
                afspraken = await CloudKitManager.shared.fetchAfspraken(artiesEmail: email)
            }
            laden = false
        }
    }

    @ViewBuilder
    private func afspraakRij(_ a: Afspraak) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(a.klantNaam.isEmpty ? a.klantEmail : a.klantNaam)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Text(datumFormatter.string(from: a.datum))
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.5))
                    .tracking(0.5)
                if !a.notitie.isEmpty {
                    Text(a.notitie)
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.6))
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }
            Spacer()
            VStack(spacing: 8) {
                Button(action: { bevestig(a) }) {
                    Text("OK")
                        .font(.system(size: 11, weight: .bold)).tracking(1)
                        .foregroundColor(.black)
                        .frame(width: 52, height: 32)
                        .background(Color.white)
                        .cornerRadius(5)
                }
                Button(action: { weiger(a) }) {
                    Text("NEE")
                        .font(.system(size: 11, weight: .bold)).tracking(1)
                        .foregroundColor(Color(white: 0.5))
                        .frame(width: 52, height: 32)
                        .background(Color(white: 0.1))
                        .cornerRadius(5)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(white: 0.2), lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color(white: 0.07))
        .overlay(Rectangle().stroke(Color(white: 0.1), lineWidth: 1))
    }

    private func shopNaam() -> String {
        guard let s = store.shop else { return "" }
        return s.bedrijfsnaam.isEmpty ? "\(s.voornaam) \(s.achternaam)".trimmingCharacters(in: .whitespaces) : s.bedrijfsnaam
    }

    private func bevestig(_ a: Afspraak) {
        let naam = shopNaam()
        let subj = "Afspraak bevestigd – \(naam)"
        let body = "Hoi \(a.klantNaam),\n\nJe afspraak op \(datumFormatter.string(from: a.datum)) is bevestigd!\n\nTot dan!\n\(naam)"
        mailOpen(to: a.klantEmail, subject: subj, body: body)
    }

    private func weiger(_ a: Afspraak) {
        let naam = shopNaam()
        let subj = "Afspraak helaas niet beschikbaar – \(naam)"
        let body = "Hoi \(a.klantNaam),\n\nHelaas kan ik op \(datumFormatter.string(from: a.datum)) niet. Neem contact op om een andere datum af te spreken.\n\nMet vriendelijke groet,\n\(naam)"
        mailOpen(to: a.klantEmail, subject: subj, body: body)
    }

    private func mailOpen(to: String, subject: String, body: String) {
        let s = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let b = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(to)?subject=\(s)&body=\(b)") {
            UIApplication.shared.open(url)
        }
    }
}
