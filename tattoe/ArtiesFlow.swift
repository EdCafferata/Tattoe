import SwiftUI
import AuthenticationServices
import PhotosUI

// MARK: - Flow orchestrator

struct ArtiesFlowView: View {
    @EnvironmentObject var store: ArtiesStore
    let onLogout: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if store.isLoggedIn, let arties = store.arties {
                if arties.voornaam.isEmpty {
                    ArtiesNAWView(onLogout: onLogout)
                } else {
                    ArtiesDashboardView(onLogout: onLogout)
                }
            } else {
                ArtiesLoginView(onLogout: onLogout)
            }
        }
    }
}

// MARK: - Login keuze scherm

struct ArtiesLoginView: View {
    @EnvironmentObject var store: ArtiesStore
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

                Text("ARTIEST")
                    .font(.system(size: 32, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)

                Spacer().frame(height: 8)

                Text("Meld je aan als tattoo artiest")
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
            ArtiesEmailLoginView(onLogout: onLogout)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showEmailRegister) {
            ArtiesEmailRegisterView(onLogout: onLogout)
                .environmentObject(store)
        }
    }

    #if DEBUG
    private func devInloggen() {
        let testArties = Arties(
            authMethod: .email, appleUserID: "",
            voornaam: "Jim", achternaam: "Orie",
            email: "jim@dragontattoo.nl", wachtwoord: "test1234",
            kunstnaam: "Jim Orie", specialisatie: "Realism",
            telefoon: "0612345678", straat: "Kalverstraat", huisnummer: "1",
            postcode: "1012NX", woonplaats: "Amsterdam",
            shopEmails: [], bio: "Tattoo artiest gespecialiseerd in realism en blackwork.",
            stijlen: ["Realism", "Blackwork", "Fineline"], jarenervaring: 8,
            instagram: "https://www.instagram.com/jimorie/",
            facebook: "", pinterest: "", tiktok: "", website: "https://www.dragontattoo.nl"
        )
        store.save(testArties)
    }
    #endif

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            #if DEBUG
            guard !store.isLoggedIn else { return }
            store.saveLocal(Arties(
                authMethod:    .apple,
                appleUserID:   cred.user,
                voornaam:      cred.fullName?.givenName  ?? "",
                achternaam:    cred.fullName?.familyName ?? "",
                email:         cred.email ?? "",
                wachtwoord:    "",
                kunstnaam:     "",
                specialisatie: "",
                telefoon:      "",
                straat:        "",
                huisnummer:    "",
                postcode:      "",
                woonplaats:    ""
            ))
            #else
            Task {
                await store.checkCloud(appleUserID: cred.user)
                if !store.isLoggedIn {
                    store.save(Arties(
                        authMethod:    .apple,
                        appleUserID:   cred.user,
                        voornaam:      cred.fullName?.givenName  ?? "",
                        achternaam:    cred.fullName?.familyName ?? "",
                        email:         cred.email ?? "",
                        wachtwoord:    "",
                        kunstnaam:     "",
                        specialisatie: "",
                        telefoon:      "",
                        straat:        "",
                        huisnummer:    "",
                        postcode:      "",
                        woonplaats:    ""
                    ))
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

struct ArtiesEmailLoginView: View {
    @EnvironmentObject var store: ArtiesStore
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

                Text("Log in met je artiest account")
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
                Button(action: { email = "jim@dragontattoo.nl"; wachtwoord = "test1234" }) {
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
            WachtwoordResetView(rol: .arties)
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

struct ArtiesEmailRegisterView: View {
    @EnvironmentObject var store: ArtiesStore
    let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var voornaam      = ""
    @State private var achternaam    = ""
    @State private var email         = ""
    @State private var wachtwoord    = ""
    @State private var bevestig      = ""
    @State private var kunstnaam     = ""
    @State private var specialisatie = ""
    @State private var telefoon      = ""
    @State private var straat        = ""
    @State private var huisnummer    = ""
    @State private var postcode      = ""
    @State private var woonplaats    = ""
    @State private var gekozenShops:   [ShopProfiel] = []
    @State private var showShopZoeker = false
    @State private var fout: String?
    @FocusState private var focus: Veld?

    enum Veld: Hashable {
        case voornaam, achternaam, email, wachtwoord, bevestig
        case kunstnaam, specialisatie, telefoon
        case straat, huisnummer, postcode, woonplaats
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

                    Text("Vul je gegevens in als artiest")
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

                    // ── Sectie: Artiest ──────────────────
                    sectionLabel("ARTIEST")

                    VStack(spacing: 1) {
                        InkField("KUNSTNAAM / ALIAS", text: $kunstnaam)
                            .focused($focus, equals: .kunstnaam)
                        InkField("SPECIALISATIE (bijv. traditional, realism)", text: $specialisatie)
                            .focused($focus, equals: .specialisatie)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 24)

                    // ── Sectie: Shop ─────────────────────
                    sectionLabel("SHOPS (OPTIONEEL)")
                    shopKiezerRijen(shops: gekozenShops, onToevoegen: { showShopZoeker = true }, onVerwijder: { e in gekozenShops.removeAll { $0.email == e } })
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

                    Spacer().frame(height: 100) // ruimte voor vaste knop
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
        .fullScreenCover(isPresented: $showShopZoeker) {
            MultiShopZoekerView(gekozen: gekozenShops) { shops in
                gekozenShops = shops
                showShopZoeker = false
            }
        }
    }

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

    #if DEBUG
    private func devVulIn() {
        voornaam      = "Jim"
        achternaam    = "Orie"
        email         = "jim@dragontattoo.nl"
        wachtwoord    = "test1234"
        bevestig      = "test1234"
        kunstnaam     = "Jim Orie"
        specialisatie = "Realism"
        telefoon      = "0612345678"
        straat        = "Kalverstraat"
        huisnummer    = "1"
        postcode      = "1012NX"
        woonplaats    = "Amsterdam"
    }
    #endif

    private func registreer() {
        fout = nil; focus = nil
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
        let arties = Arties(
            authMethod:    .email,
            appleUserID:   "",
            voornaam:      voornaam,
            achternaam:    achternaam,
            email:         email,
            wachtwoord:    wachtwoord,
            kunstnaam:     kunstnaam,
            specialisatie: specialisatie,
            telefoon:      telefoon,
            straat:        straat,
            huisnummer:    huisnummer,
            postcode:      postcode,
            woonplaats:    woonplaats,
            shopEmails:    gekozenShops.map { $0.email }
        )
        store.save(arties)
        dismiss()
    }
}

// MARK: - NAW aanvullen (na Apple login)

struct ArtiesNAWView: View {
    @EnvironmentObject var store: ArtiesStore
    let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var voornaam      = ""
    @State private var achternaam    = ""
    @State private var email         = ""
    @State private var kunstnaam     = ""
    @State private var specialisatie = ""
    @State private var telefoon      = ""
    @State private var straat        = ""
    @State private var huisnummer    = ""
    @State private var postcode      = ""
    @State private var woonplaats    = ""
    @State private var gekozenShops:  [ShopProfiel] = []
    @State private var showShopZoeker = false
    @State private var fout: String?
    @FocusState private var focus: Veld?

    enum Veld: Hashable {
        case voornaam, achternaam, email, kunstnaam, specialisatie
        case telefoon, straat, huisnummer, postcode, woonplaats
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

                    Text("Vul je gegevens aan om door te gaan")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.4))

                    Spacer().frame(height: 36)

                    VStack(spacing: 1) {
                        HStack(spacing: 1) {
                            InkField("VOORNAAM", text: $voornaam, type: .givenName)
                                .focused($focus, equals: .voornaam)
                            InkField("ACHTERNAAM", text: $achternaam, type: .familyName)
                                .focused($focus, equals: .achternaam)
                        }
                        InkField("E-MAILADRES", text: $email, type: .emailAddress, keyboard: .emailAddress)
                            .focused($focus, equals: .email)
                        InkField("KUNSTNAAM / ALIAS", text: $kunstnaam)
                            .focused($focus, equals: .kunstnaam)
                        InkField("SPECIALISATIE", text: $specialisatie)
                            .focused($focus, equals: .specialisatie)
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

                    Spacer().frame(height: 16)

                    // ── Shop kiezer ───────────────────────
                    sectionLabel("SHOPS (OPTIONEEL)")
                    shopKiezerRijen(shops: gekozenShops, onToevoegen: { showShopZoeker = true }, onVerwijder: { e in gekozenShops.removeAll { $0.email == e } })
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
        .fullScreenCover(isPresented: $showShopZoeker) {
            MultiShopZoekerView(gekozen: gekozenShops) { shops in
                gekozenShops = shops
                showShopZoeker = false
            }
        }
    }

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
        .padding(.top, 4)
    }

    private func prefill() {
        guard let a = store.arties else { return }
        voornaam      = a.voornaam
        achternaam    = a.achternaam
        email         = a.email
        kunstnaam     = a.kunstnaam
        specialisatie = a.specialisatie
        telefoon      = a.telefoon
        straat        = a.straat
        huisnummer    = a.huisnummer
        postcode      = a.postcode
        woonplaats    = a.woonplaats
        // Shops worden asynchroon geladen via task hieronder
    }

    private func opslaan() {
        guard !voornaam.trimmingCharacters(in: .whitespaces).isEmpty else {
            fout = "Voornaam is verplicht."; return
        }
        guard !achternaam.trimmingCharacters(in: .whitespaces).isEmpty else {
            fout = "Achternaam is verplicht."; return
        }
        guard email.contains("@") else {
            fout = "E-mailadres is verplicht."; return
        }
        fout = nil; focus = nil
        var a = store.arties ?? Arties(authMethod: .apple, appleUserID: "", voornaam: "", achternaam: "",
                                       email: "", wachtwoord: "", kunstnaam: "", specialisatie: "",
                                       telefoon: "", straat: "", huisnummer: "", postcode: "", woonplaats: "")
        a.voornaam      = voornaam
        a.achternaam    = achternaam
        a.email         = email
        a.kunstnaam     = kunstnaam
        a.specialisatie = specialisatie
        a.telefoon      = telefoon
        a.straat        = straat
        a.huisnummer    = huisnummer
        a.postcode      = postcode
        a.woonplaats    = woonplaats
        a.shopEmails    = gekozenShops.map { $0.email }
        store.save(a)
        dismiss()
    }
}

// MARK: - Shop zoeker (voor artiest registratie/NAW)

struct ShopZoekerView: View {
    let onKies: (ShopProfiel) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var shops: [ShopProfiel] = []
    @State private var laden = true
    @State private var zoekterm = ""

    private var gefilterdeShops: [ShopProfiel] {
        guard !zoekterm.isEmpty else { return shops }
        return shops.filter {
            $0.bedrijfsnaam.localizedCaseInsensitiveContains(zoekterm) ||
            $0.woonplaats.localizedCaseInsensitiveContains(zoekterm)
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 56)

                Text("KIES JE SHOP")
                    .font(.system(size: 22, weight: .black))
                    .tracking(5)
                    .foregroundColor(.white)

                Spacer().frame(height: 6)

                Text("Zoek de shop waar je werkt")
                    .font(.system(size: 11))
                    .tracking(1.5)
                    .foregroundColor(Color(white: 0.4))

                Spacer().frame(height: 20)

                // Zoekbalk
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.4))
                    TextField("Zoek op naam of plaats…", text: $zoekterm)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .tint(.white)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(white: 0.07))
                .overlay(Rectangle().stroke(Color(white: 0.15), lineWidth: 1))
                .padding(.horizontal, 24)

                Spacer().frame(height: 16)

                if laden {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if gefilterdeShops.isEmpty {
                    Spacer()
                    Text("Geen shops gevonden")
                        .font(.system(size: 13))
                        .tracking(1)
                        .foregroundColor(Color(white: 0.3))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(gefilterdeShops) { shop in
                                Button(action: { onKies(shop) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(shop.bedrijfsnaam)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text(shop.woonplaats)
                                                .font(.system(size: 11))
                                                .foregroundColor(Color(white: 0.4))
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                            .foregroundColor(Color(white: 0.25))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color(white: 0.07))
                                    .overlay(Rectangle().stroke(Color(white: 0.1), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }

            // TERUG knop
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
        .task {
            shops = await CloudKitManager.shared.fetchPubliekeShops()
            laden = false
        }
    }
}

// MARK: - Gedeelde shop-kiezer UI helper

@ViewBuilder
func shopKiezerRijen(shops: [ShopProfiel], onToevoegen: @escaping () -> Void, onVerwijder: @escaping (String) -> Void) -> some View {
    VStack(spacing: 1) {
        ForEach(shops) { shop in
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(shop.bedrijfsnaam)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    Text(shop.woonplaats)
                        .font(.system(size: 11))
                        .foregroundColor(Color(white: 0.4))
                }
                Spacer()
                Button(action: { onVerwijder(shop.email) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(white: 0.4))
                        .frame(width: 32, height: 32)
                        .background(Color(white: 0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(white: 0.07))
            .overlay(Rectangle().stroke(Color(white: 0.12), lineWidth: 1))
        }
        Button(action: onToevoegen) {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(white: 0.3))
                Text(shops.isEmpty ? "Kies je shop(s)" : "Nog een shop toevoegen")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.35))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(Color(white: 0.2))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color(white: 0.07))
            .overlay(Rectangle().stroke(Color(white: 0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Multi-shop zoeker

struct MultiShopZoekerView: View {
    let gekozen:   [ShopProfiel]
    let onKies:    ([ShopProfiel]) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var shops:     [ShopProfiel] = []
    @State private var selectie:  Set<String>   = []
    @State private var laden      = true
    @State private var zoekterm   = ""

    private var gefilterdeShops: [ShopProfiel] {
        guard !zoekterm.isEmpty else { return shops }
        return shops.filter {
            $0.bedrijfsnaam.localizedCaseInsensitiveContains(zoekterm) ||
            $0.woonplaats.localizedCaseInsensitiveContains(zoekterm)
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 56)

                Text("KIES JE SHOPS")
                    .font(.system(size: 22, weight: .black))
                    .tracking(5)
                    .foregroundColor(.white)

                Spacer().frame(height: 6)

                Text("Selecteer alle shops waar je werkt")
                    .font(.system(size: 11))
                    .tracking(1.5)
                    .foregroundColor(Color(white: 0.4))

                Spacer().frame(height: 20)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(Color(white: 0.4))
                    TextField("Zoek op naam of plaats…", text: $zoekterm)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .tint(.white)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(white: 0.07))
                .overlay(Rectangle().stroke(Color(white: 0.15), lineWidth: 1))
                .padding(.horizontal, 24)

                Spacer().frame(height: 16)

                if laden {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if gefilterdeShops.isEmpty {
                    Spacer()
                    Text("Geen shops gevonden")
                        .font(.system(size: 13))
                        .tracking(1)
                        .foregroundColor(Color(white: 0.3))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(gefilterdeShops) { shop in
                                Button(action: { toggle(shop.email) }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(shop.bedrijfsnaam)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text(shop.woonplaats)
                                                .font(.system(size: 11))
                                                .foregroundColor(Color(white: 0.4))
                                        }
                                        Spacer()
                                        Image(systemName: selectie.contains(shop.email) ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(selectie.contains(shop.email) ? .white : Color(white: 0.25))
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(selectie.contains(shop.email) ? Color(white: 0.12) : Color(white: 0.07))
                                    .overlay(Rectangle().stroke(Color(white: 0.12), lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
            }

            // BEVESTIGEN knop
            VStack(spacing: 0) {
                Spacer()
                Button(action: bevestig) {
                    Text(selectie.isEmpty ? "OVERSLAAN" : "BEVESTIGEN (\(selectie.count))")
                        .font(.system(size: 14, weight: .black))
                        .tracking(3)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }

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
        .task {
            shops    = await CloudKitManager.shared.fetchPubliekeShops()
            selectie = Set(gekozen.map { $0.email })
            laden    = false
        }
    }

    private func toggle(_ email: String) {
        if selectie.contains(email) { selectie.remove(email) } else { selectie.insert(email) }
    }

    private func bevestig() {
        let gekozenShops = shops.filter { selectie.contains($0.email) }
        onKies(gekozenShops)
    }
}

// MARK: - Shops beheer (vanuit dashboard)

struct ArtiesShopsBeheerView: View {
    @EnvironmentObject var store: ArtiesStore
    @Environment(\.dismiss) private var dismiss

    @State private var shopProfielen: [ShopProfiel] = []
    @State private var showZoeker    = false
    @State private var laden         = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 56)

                Text("MIJN SHOPS")
                    .font(.system(size: 22, weight: .black))
                    .tracking(5)
                    .foregroundColor(.white)

                Spacer().frame(height: 6)

                Text("Shops waar je werkt of freelance")
                    .font(.system(size: 11))
                    .tracking(1.5)
                    .foregroundColor(Color(white: 0.4))

                Spacer().frame(height: 24)

                if laden {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            shopKiezerRijen(
                                shops:       shopProfielen,
                                onToevoegen: { showZoeker = true },
                                onVerwijder: { email in verwijder(email) }
                            )
                            .padding(.horizontal, 24)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }

            VStack(spacing: 0) {
                Spacer()
                Button(action: opslaan) {
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
                .padding(.bottom, 40)
            }

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
        .task {
            await laadShops()
        }
        .fullScreenCover(isPresented: $showZoeker) {
            MultiShopZoekerView(gekozen: shopProfielen) { nieuweShops in
                shopProfielen = nieuweShops
                showZoeker    = false
            }
        }
    }

    private func laadShops() async {
        let emails = store.arties?.shopEmails ?? []
        if emails.isEmpty { laden = false; return }
        let alle = await CloudKitManager.shared.fetchPubliekeShops()
        shopProfielen = alle.filter { emails.contains($0.email) }
        laden = false
    }

    private func verwijder(_ email: String) {
        shopProfielen.removeAll { $0.email == email }
    }

    private func opslaan() {
        guard var a = store.arties else { dismiss(); return }
        a.shopEmails = shopProfielen.map { $0.email }
        store.save(a)
        dismiss()
    }
}

// MARK: - Dashboard

struct ArtiesDashboardView: View {
    @EnvironmentObject var store: ArtiesStore
    let onLogout: () -> Void

    @State private var showBewerken  = false
    @State private var showAfspraken = false
    @State private var showShops     = false
    @State private var showBerichten = false

    private let portfolioColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    profielHeader

                    // Berichten sectie
                    dashSection("BERICHTEN") {
                        Button(action: { showBerichten = true }) {
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

                    // Afspraken sectie
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

                    // Shops sectie
                    dashSection("MIJN SHOPS") {
                        if let a = store.arties, !a.shopEmails.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(a.shopEmails, id: \.self) { email in
                                    HStack(spacing: 10) {
                                        Image(systemName: "storefront")
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(white: 0.4))
                                        Text(email)
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(white: 0.7))
                                            .lineLimit(1)
                                        Spacer()
                                    }
                                }
                                Button(action: { showShops = true }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 13))
                                        Text("Shops beheren")
                                            .font(.system(size: 13))
                                    }
                                    .foregroundColor(Color(white: 0.4))
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                        } else {
                            Button(action: { showShops = true }) {
                                HStack {
                                    Image(systemName: "storefront")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(white: 0.5))
                                    Text("Voeg je shop(s) toe")
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

                    if let a = store.arties {
                        if !a.bio.isEmpty {
                            dashSection("OVER MIJ") {
                                Text(a.bio)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(white: 0.75))
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        if !a.stijlen.isEmpty {
                            dashSection("STIJLEN") {
                                stijlenChips(a.stijlen)
                            }
                        }
                        if a.jarenervaring > 0 {
                            dashSection("ERVARING") {
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text("\(a.jarenervaring)")
                                        .font(.system(size: 28, weight: .black))
                                        .foregroundColor(.white)
                                    Text("jaar")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(white: 0.4))
                                }
                            }
                        }
                        let links = socialLinks(a)
                        if !links.isEmpty {
                            dashSection("SOCIAL & WEB") {
                                VStack(spacing: 12) {
                                    ForEach(links, id: \.label) { link in
                                        socialRow(link)
                                    }
                                }
                            }
                        }
                    }

                    let filled = store.portfolioFotos.enumerated().filter { $0.element != nil }
                    if !filled.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PORTFOLIO")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(4)
                                .foregroundColor(Color(white: 0.3))
                                .padding(.horizontal, 24)

                            LazyVGrid(columns: portfolioColumns, spacing: 2) {
                                ForEach(0..<9, id: \.self) { i in
                                    if let data = store.portfolioFotos[i],
                                       let img = UIImage(data: data) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: .infinity)
                                            .aspectRatio(1, contentMode: .fill)
                                            .clipped()
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                    }

                    let filledVoorbeelden = store.voorbeeldFotos.enumerated().filter { $0.element != nil }
                    if !filledVoorbeelden.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("VOORBEELD TATTOO'S")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(4)
                                .foregroundColor(Color(white: 0.3))
                                .padding(.horizontal, 24)
                            LazyVGrid(columns: portfolioColumns, spacing: 2) {
                                ForEach(0..<9, id: \.self) { i in
                                    if let data = store.voorbeeldFotos[i], let img = UIImage(data: data) {
                                        Image(uiImage: img)
                                            .resizable().scaledToFill()
                                            .frame(maxWidth: .infinity)
                                            .aspectRatio(1, contentMode: .fill)
                                            .clipped()
                                    }
                                }
                            }
                        }
                        .padding(.top, 20)
                    }

                    if isProfielLeeg {
                        Spacer().frame(height: 40)
                        Text("Vul je profiel in via AANPASSEN")
                            .font(.system(size: 12))
                            .tracking(1)
                            .foregroundColor(Color(white: 0.25))
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .fullScreenCover(isPresented: $showBewerken) {
            ArtiesProfielBewerkenView(onLogout: onLogout)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showAfspraken) {
            ArtiesAfsprakenView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showShops) {
            ArtiesShopsBeheerView()
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showBerichten) {
            ArtiesBerichtenView().environmentObject(store)
        }
    }

    // MARK: Header

    @ViewBuilder
    private var profielHeader: some View {
        VStack(spacing: 12) {
            if let data = store.profielFotoData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 1))
            } else {
                ZStack {
                    Circle()
                        .fill(Color(white: 0.1))
                        .frame(width: 100, height: 100)
                        .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 1))
                    Image(systemName: "person.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color(white: 0.2))
                }
            }

            if let a = store.arties {
                Text(a.kunstnaam.isEmpty ? "\(a.voornaam) \(a.achternaam)" : a.kunstnaam)
                    .font(.system(size: 22, weight: .black))
                    .tracking(3)
                    .foregroundColor(.white)

                if !a.specialisatie.isEmpty {
                    Text(a.specialisatie.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(3)
                        .foregroundColor(Color(white: 0.4))
                }

                if !a.woonplaats.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.3))
                        Text(a.woonplaats)
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

    // MARK: Section wrapper

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
        Rectangle()
            .fill(Color(white: 0.1))
            .frame(height: 1)
    }

    @ViewBuilder
    private func stijlenChips(_ stijlen: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(stijlen, id: \.self) { s in
                    Text(s)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(white: 0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color(white: 0.25), lineWidth: 1))
                }
            }
        }
    }

    private struct SocialLink: Identifiable {
        let id = UUID()
        let label: String
        let icon:  String
        let url:   String
    }

    private func socialLinks(_ a: Arties) -> [SocialLink] {
        var out: [SocialLink] = []
        if !a.instagram.isEmpty { out.append(.init(label: "Instagram", icon: "camera",    url: a.instagram)) }
        if !a.facebook.isEmpty  { out.append(.init(label: "Facebook",  icon: "person.2",  url: a.facebook)) }
        if !a.pinterest.isEmpty { out.append(.init(label: "Pinterest", icon: "pin",       url: a.pinterest)) }
        if !a.tiktok.isEmpty    { out.append(.init(label: "TikTok",    icon: "music.note",url: a.tiktok)) }
        if !a.website.isEmpty   { out.append(.init(label: "Website",   icon: "globe",     url: a.website)) }
        return out
    }

    @ViewBuilder
    private func socialRow(_ link: SocialLink) -> some View {
        HStack(spacing: 12) {
            Image(systemName: link.icon)
                .font(.system(size: 14))
                .foregroundColor(Color(white: 0.45))
                .frame(width: 20)
            Text(link.url)
                .font(.system(size: 13))
                .foregroundColor(Color(white: 0.7))
                .lineLimit(1)
            Spacer()
            Text(link.label.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
                .foregroundColor(Color(white: 0.3))
        }
    }

    private var isProfielLeeg: Bool {
        guard let a = store.arties else { return true }
        return a.bio.isEmpty && a.stijlen.isEmpty && a.jarenervaring == 0 &&
               a.instagram.isEmpty && a.facebook.isEmpty && a.pinterest.isEmpty &&
               a.tiktok.isEmpty && a.website.isEmpty &&
               store.portfolioFotos.allSatisfy { $0 == nil } &&
               store.profielFotoData == nil
    }
}

// MARK: - Afspraken beheer

struct ArtiesAfsprakenView: View {
    @EnvironmentObject var store: ArtiesStore
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
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if afspraken.isEmpty {
                    Spacer()
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundColor(Color(white: 0.2))
                    Spacer().frame(height: 16)
                    Text("Nog geen afspraakaanvragen")
                        .font(.system(size: 13))
                        .tracking(1)
                        .foregroundColor(Color(white: 0.3))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(afspraken) { a in
                                afspraakRij(a)
                            }
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
            .padding(.leading, 24)
            .padding(.top, 16)
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
        if let email = store.arties?.email {
            let direct = await CloudKitManager.shared.fetchAfspraken(artiesEmail: email)
            afspraken = direct.filter { !["geweigerd", "geannuleerd"].contains($0.status) }
                              .sorted { $0.datum < $1.datum }
        }
        #if DEBUG
        let testIds = Set(afspraken.map { $0.id })
        let extra = TestData.afsprakenArties.filter { !testIds.contains($0.id) }
        afspraken = (extra + afspraken).sorted { $0.datum < $1.datum }
        #endif
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
                } else if !isBevestigd && (a.status == "aangevraagd" || a.status == "shop_akkoord") {
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
                    Button(action: { toonAfzeggen = a }) {
                        Text("Afzeggen")
                            .font(.system(size: 11, weight: .semibold)).tracking(1)
                            .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.3))
                            .frame(maxWidth: .infinity).frame(height: 32).background(Color(white: 0.1)).cornerRadius(5)
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(red: 0.5, green: 0.15, blue: 0.15), lineWidth: 1))
                    }
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .background(Color(white: isBevestigd ? 0.09 : 0.07))
        .overlay(Rectangle().stroke(Color(white: isBevestigd ? 0.18 : 0.1), lineWidth: 1))
    }

    @ViewBuilder
    private func statusLabel(_ status: String) -> some View {
        let (tekst, kleur): (String, Color) = switch status {
            case "arties_akkoord": ("Wacht op shop", Color.yellow)
            case "shop_akkoord":   ("Shop akkoord – jouw beurt", Color.orange)
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

// MARK: - Profiel bewerken

struct ArtiesProfielBewerkenView: View {
    @EnvironmentObject var store: ArtiesStore
    let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss

    // Foto picker state
    enum FotoDoel { case profiel; case portfolio(Int); case voorbeeld(Int) }
    @State private var fotoDoel:    FotoDoel? = nil
    @State private var pickerItem:  PhotosPickerItem? = nil

    // Bewerkbare velden
    @State private var bio           = ""
    @State private var stijlInput    = ""
    @State private var stijlen:       [String] = []
    @State private var jarenervaring = 0
    @State private var instagram     = ""
    @State private var facebook      = ""
    @State private var pinterest     = ""
    @State private var tiktok        = ""
    @State private var website       = ""

    @State private var bezig                    = false
    @State private var toonVerwijderBevestiging = false

    // URL importer
    @State private var importURL          = ""
    @State private var importBezig        = false
    @State private var importFout:        String? = nil
    @State private var importVoorbeeld:   ImportResultaat? = nil
    @State private var showImportPreview  = false

    private let portfolioColumns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    // URL importer
                    sectionLabel("IMPORTEER VAN WEBSITE")
                    urlImportSection
                    Spacer().frame(height: 28)

                    // Profielfoto
                    profielFotoKnop
                    Spacer().frame(height: 32)

                    // Bio
                    sectionLabel("BIO")
                    bioEditor
                    Spacer().frame(height: 24)

                    // Stijlen
                    sectionLabel("STIJLEN")
                    stijlenEditor
                    Spacer().frame(height: 24)

                    // Portfolio
                    sectionLabel("PORTFOLIO (MAX 9 FOTO'S)")
                    LazyVGrid(columns: portfolioColumns, spacing: 2) {
                        ForEach(0..<9, id: \.self) { portfolioCell(index: $0) }
                    }
                    .padding(.horizontal, 24)
                    Spacer().frame(height: 24)

                    // Voorbeeld foto's
                    sectionLabel("VOORBEELD TATTOO'S (MAX 9)")
                    LazyVGrid(columns: portfolioColumns, spacing: 2) {
                        ForEach(0..<9, id: \.self) { voorbeeldCell(index: $0) }
                    }
                    .padding(.horizontal, 24)
                    Spacer().frame(height: 24)

                    // Jaren ervaring
                    sectionLabel("JAREN ERVARING")
                    ervaringStepper
                    Spacer().frame(height: 24)

                    // Social
                    sectionLabel("SOCIAL MEDIA & WEB")
                    VStack(spacing: 1) {
                        InkField("INSTAGRAM URL", text: $instagram, keyboard: .URL)
                        InkField("FACEBOOK URL",  text: $facebook,  keyboard: .URL)
                        InkField("PINTEREST URL", text: $pinterest, keyboard: .URL)
                        InkField("TIKTOK URL",    text: $tiktok,    keyboard: .URL)
                        InkField("WEBSITE URL",   text: $website,   keyboard: .URL)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 100)
                }
            }

            // Vaste OPSLAAN + VERWIJDER knoppen
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

            // TERUG knop
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
            Text("Je profiel, portfolio en alle gegevens worden definitief verwijderd.")
        }
        .photosPicker(
            isPresented: Binding(
                get: { fotoDoel != nil },
                set: { if !$0 { fotoDoel = nil } }
            ),
            selection: $pickerItem,
            matching: .images
        )
        .onChange(of: pickerItem) { _, item in
            guard let item, let doel = fotoDoel else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    switch doel {
                    case .profiel:           store.saveProfielFoto(data)
                    case .portfolio(let i):  store.savePortfolioFoto(data, at: i)
                    case .voorbeeld(let i):  store.saveVoorbeeldFoto(data, at: i)
                    }
                }
                pickerItem = nil
                fotoDoel   = nil
            }
        }
        .sheet(isPresented: $showImportPreview) {
            if let r = importVoorbeeld {
                ImportPreviewSheet(resultaat: r) { gekozen in
                    if !gekozen.bio.isEmpty       { bio       = gekozen.bio }
                    if !gekozen.instagram.isEmpty { instagram = gekozen.instagram }
                    if !gekozen.facebook.isEmpty  { facebook  = gekozen.facebook }
                    if !gekozen.pinterest.isEmpty { pinterest = gekozen.pinterest }
                    if !gekozen.tiktok.isEmpty    { tiktok    = gekozen.tiktok }
                    if !gekozen.website.isEmpty   { website   = gekozen.website }
                    for s in gekozen.stijlen where !stijlen.contains(s) { stijlen.append(s) }

                    // Foto's downloaden op de achtergrond
                    Task {
                        if !gekozen.profielFotoURL.isEmpty,
                           let data = await downloadImage(gekozen.profielFotoURL) {
                            store.saveProfielFoto(data)
                        }
                        var pSlot = 0
                        for url in gekozen.portfolioFotoURLs {
                            while pSlot < 9 && store.portfolioFotos[pSlot] != nil { pSlot += 1 }
                            guard pSlot < 9 else { break }
                            if let data = await downloadImage(url) { store.savePortfolioFoto(data, at: pSlot); pSlot += 1 }
                        }
                        var vSlot = 0
                        for url in gekozen.voorbeeldFotoURLs {
                            while vSlot < 9 && store.voorbeeldFotos[vSlot] != nil { vSlot += 1 }
                            guard vSlot < 9 else { break }
                            if let data = await downloadImage(url) { store.saveVoorbeeldFoto(data, at: vSlot); vSlot += 1 }
                        }
                    }
                }
            }
        }
    }

    // MARK: Subviews

    @ViewBuilder
    private var profielFotoKnop: some View {
        VStack(spacing: 10) {
            Button(action: { fotoDoel = .profiel }) {
                ZStack(alignment: .bottomTrailing) {
                    if let data = store.profielFotoData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 1))
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color(white: 0.1))
                                .frame(width: 100, height: 100)
                                .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 1))
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color(white: 0.2))
                        }
                    }
                    ZStack {
                        Circle().fill(Color.white).frame(width: 28, height: 28)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.black)
                    }
                    .offset(x: 4, y: 4)
                }
            }
            .buttonStyle(.plain)

            Text("PROFIELFOTO")
                .font(.system(size: 9, weight: .bold))
                .tracking(3)
                .foregroundColor(Color(white: 0.35))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var bioEditor: some View {
        ZStack(alignment: .topLeading) {
            if bio.isEmpty {
                Text("Vertel iets over jezelf als artiest…")
                    .font(.system(size: 14))
                    .foregroundColor(Color(white: 0.3))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $bio)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .tint(.white)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minHeight: 100)
        }
        .background(Color(white: 0.07))
        .overlay(Rectangle().stroke(Color(white: 0.15), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var stijlenEditor: some View {
        VStack(spacing: 8) {
            if !stijlen.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(stijlen, id: \.self) { stijl in
                            HStack(spacing: 6) {
                                Text(stijl)
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(1)
                                    .foregroundColor(.white)
                                Button(action: { stijlen.removeAll { $0 == stijl } }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(Color(white: 0.5))
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color(white: 0.12))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(white: 0.25), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            HStack(spacing: 8) {
                TextField("Voeg stijl toe (bijv. realism)", text: $stijlInput)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .tint(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(white: 0.07))
                    .overlay(Rectangle().stroke(Color(white: 0.15), lineWidth: 1))
                    .onSubmit { voegStijlToe() }
                Button(action: voegStijlToe) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 44, height: 44)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .disabled(stijlInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var ervaringStepper: some View {
        HStack {
            Button(action: { if jarenervaring > 0 { jarenervaring -= 1 } }) {
                Image(systemName: "minus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color(white: 0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(white: 0.2), lineWidth: 1))
            }
            Text("\(jarenervaring) jaar")
                .font(.system(size: 18, weight: .black))
                .tracking(2)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
            Button(action: { jarenervaring += 1 }) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 44, height: 44)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func portfolioCell(index: Int) -> some View {
        ZStack {
            if let data = store.portfolioFotos[index], let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        Button(action: { store.removePortfolioFoto(at: index) }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .shadow(radius: 3)
                        }
                        .padding(6)
                    }
            } else {
                Button(action: { fotoDoel = .portfolio(index) }) {
                    Color(white: 0.07)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .overlay(Rectangle().stroke(Color(white: 0.15), lineWidth: 1))
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(Color(white: 0.3))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func voorbeeldCell(index: Int) -> some View {
        ZStack {
            if let data = store.voorbeeldFotos[index], let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable().scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
                    .overlay(alignment: .topTrailing) {
                        Button(action: { store.removeVoorbeeldFoto(at: index) }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)
                                .shadow(radius: 3)
                        }
                        .padding(6)
                    }
            } else {
                Button(action: { fotoDoel = .voorbeeld(index) }) {
                    Color(white: 0.07)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .overlay(Rectangle().stroke(Color(white: 0.15), lineWidth: 1))
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .light))
                                .foregroundColor(Color(white: 0.3))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

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

    // MARK: Logic

    private func prefill() {
        guard let a = store.arties else { return }
        bio           = a.bio
        stijlen       = a.stijlen
        jarenervaring = a.jarenervaring
        instagram     = a.instagram
        facebook      = a.facebook
        pinterest     = a.pinterest
        tiktok        = a.tiktok
        website       = a.website
    }

    private func voegStijlToe() {
        let s = stijlInput.trimmingCharacters(in: .whitespaces)
        guard !s.isEmpty, !stijlen.contains(s) else { stijlInput = ""; return }
        stijlen.append(s)
        stijlInput = ""
    }

    private func opslaan() {
        bezig = true
        var a = store.arties ?? Arties(authMethod: .email, appleUserID: "", voornaam: "",
                                       achternaam: "", email: "", wachtwoord: "", kunstnaam: "",
                                       specialisatie: "", telefoon: "", straat: "", huisnummer: "",
                                       postcode: "", woonplaats: "")
        a.bio           = bio
        a.stijlen       = stijlen
        a.jarenervaring = jarenervaring
        a.instagram     = instagram
        a.facebook      = facebook
        a.pinterest     = pinterest
        a.tiktok        = tiktok
        a.website       = website
        store.save(a)
        bezig = false
        dismiss()
    }

    // MARK: URL importer UI

    @ViewBuilder
    private var urlImportSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("https://www.jouwnaam.nl", text: $importURL)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .tint(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(white: 0.07))
                    .overlay(Rectangle().stroke(Color(white: 0.15), lineWidth: 1))

                Button(action: { Task { await importeerURL() } }) {
                    Group {
                        if importBezig {
                            ProgressView().tint(.black).scaleEffect(0.8)
                        } else {
                            Text("LADEN")
                                .font(.system(size: 11, weight: .black))
                                .tracking(2)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(width: 64, height: 44)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .disabled(importBezig || importURL.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let fout = importFout {
                Text(fout)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 1, green: 0.3, blue: 0.3))
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: URL fetch + parse

    private func importeerURL() async {
        importFout = nil
        var urlStr = importURL.trimmingCharacters(in: .whitespaces)
        if !urlStr.hasPrefix("http") { urlStr = "https://" + urlStr }
        guard let url = URL(string: urlStr) else { importFout = "Ongeldige URL."; return }

        importBezig = true
        defer { importBezig = false }

        guard let (data, response) = try? await URLSession.shared.data(from: url) else {
            importFout = "Kon de pagina niet laden."; return
        }
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            importFout = "Pagina niet gevonden (fout \(http.statusCode)). Controleer de URL."; return
        }
        guard let html = String(data: data, encoding: .utf8)
                      ?? String(data: data, encoding: .isoLatin1) else {
            importFout = "Kon de pagina niet lezen."; return
        }

        let resultaat = parseHTML(html, baseURL: url)
        if resultaat.isLeeg {
            importFout = "Geen profielgegevens gevonden op deze pagina."
        } else {
            importVoorbeeld   = resultaat
            showImportPreview = true
        }
    }

    private func parseHTML(_ html: String, baseURL: URL) -> ImportResultaat {
        let fotos = extractFotos(html, baseURL: baseURL)
        return ImportResultaat(
            bio:               extractMetaBeschrijving(html),
            instagram:         extractSocialURL(html, domain: "instagram.com"),
            facebook:          extractSocialURL(html, domain: "facebook.com"),
            pinterest:         extractSocialURL(html, domain: "pinterest.com"),
            tiktok:            extractSocialURL(html, domain: "tiktok.com"),
            website:           (baseURL.scheme ?? "https") + "://" + (baseURL.host ?? ""),
            stijlen:           extractStijlen(html),
            profielFotoURL:    fotos.profiel,
            portfolioFotoURLs: fotos.portfolio,
            voorbeeldFotoURLs: fotos.voorbeelden
        )
    }

    private func extractMetaBeschrijving(_ html: String) -> String {
        let patronen = [
            #"name=["']description["'][^>]+content=["']([^"']{15,})["']"#,
            #"content=["']([^"']{15,})["'][^>]+name=["']description["']"#,
            #"property=["']og:description["'][^>]+content=["']([^"']{15,})["']"#,
            #"content=["']([^"']{15,})["'][^>]+property=["']og:description["']"#
        ]
        for patroon in patronen {
            guard let regex = try? NSRegularExpression(pattern: patroon, options: .caseInsensitive),
                  let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  match.numberOfRanges > 1,
                  let r = Range(match.range(at: 1), in: html) else { continue }
            let result = stripHTML(String(html[r]))
            if !result.isEmpty { return result }
        }
        // Fallback: eerste alinea met voldoende tekst
        return extractEersteParagraaf(html)
    }

    private func extractEersteParagraaf(_ html: String) -> String {
        // Verwijder script/style blokken zodat we geen code oppikken
        var schoon = html
        for tag in ["script", "style", "noscript"] {
            let patroon = "(?i)<\(tag)[^>]*>[\\s\\S]*?</\(tag)>"
            schoon = schoon.replacingOccurrences(of: patroon, with: "", options: .regularExpression)
        }
        let patroon = #"<p[^>]*>([\s\S]*?)</p>"#
        guard let rx = try? NSRegularExpression(pattern: patroon, options: .caseInsensitive) else { return "" }
        let matches = rx.matches(in: schoon, range: NSRange(schoon.startIndex..., in: schoon))
        for m in matches {
            guard m.numberOfRanges > 1, let r = Range(m.range(at: 1), in: schoon) else { continue }
            let tekst = stripHTML(String(schoon[r]))
            // Sla regels over die eruitzien als code
            if tekst.count >= 80 && !tekst.contains("{") && !tekst.contains("function") {
                return String(tekst.prefix(600))
            }
        }
        return ""
    }

    private func stripHTML(_ raw: String) -> String {
        raw.replacingOccurrences(of: #"<[^>]+>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&amp;",  with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;",  with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&lt;",   with: "<")
            .replacingOccurrences(of: "&gt;",   with: ">")
            .replacingOccurrences(of: #"\s+"#,  with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractSocialURL(_ html: String, domain: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: domain)
        let patroon = "https?://(?:www\\.)?\(escaped)/[\\w@._/%-]+"
        guard let regex = try? NSRegularExpression(pattern: patroon, options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let r = Range(match.range, in: html) else { return "" }
        return String(html[r]).replacingOccurrences(of: "\"", with: "")
    }

    private static let bekendeStijlen = [
        "traditional", "neo-traditional", "neotraditional", "realism", "realistic",
        "blackwork", "watercolor", "watercolour", "geometric", "tribal", "japanese",
        "new school", "newschool", "illustrative", "dotwork", "trash polka",
        "fine line", "fineline", "biomechanical", "lettering", "portrait",
        "minimalist", "mandala", "celtic", "polynesian", "abstract", "surrealism",
        "sketch", "chicano", "old school", "oldschool"
    ]

    private func extractStijlen(_ html: String) -> [String] {
        let lower = html.lowercased()
        return Self.bekendeStijlen.filter { lower.contains($0) }
    }

    private func extractFotos(_ html: String, baseURL: URL) -> (profiel: String, portfolio: [String], voorbeelden: [String]) {
        var profiel = extractOGImage(html, baseURL: baseURL)
        var alle    = extractPortfolioImages(html, baseURL: baseURL, skip: profiel)
        if profiel.isEmpty && !alle.isEmpty { profiel = alle.removeFirst() }
        let portfolio   = Array(alle.prefix(9))
        let voorbeelden = Array(alle.dropFirst(9).prefix(9))
        return (profiel, portfolio, voorbeelden)
    }

    private func extractOGImage(_ html: String, baseURL: URL) -> String {
        let patronen = [
            #"property=["']og:image["'][^>]+content=["']([^"']+)["']"#,
            #"content=["']([^"']+)["'][^>]+property=["']og:image["']"#
        ]
        for p in patronen {
            guard let rx = try? NSRegularExpression(pattern: p, options: .caseInsensitive),
                  let m  = rx.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
                  m.numberOfRanges > 1,
                  let r  = Range(m.range(at: 1), in: html) else { continue }
            let url = String(html[r]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !url.isEmpty { return absoluteURL(url, base: baseURL) }
        }
        return ""
    }

    private func extractPortfolioImages(_ html: String, baseURL: URL, skip: String) -> [String] {
        let patroon = #"(?:src|data-src)=["']([^"']*\.(?:jpg|jpeg|png|webp))["']"#
        guard let rx = try? NSRegularExpression(pattern: patroon, options: .caseInsensitive) else { return [] }
        let matches = rx.matches(in: html, range: NSRange(html.startIndex..., in: html))
        let skipWoorden = ["logo", "icon", "hand_", "avatar", "banner", "sprite", "bg", "background", "pixel", "track"]
        var urls: [String] = []
        for m in matches {
            guard m.numberOfRanges > 1, let r = Range(m.range(at: 1), in: html) else { continue }
            let src   = String(html[r])
            let lower = src.lowercased()
            if skipWoorden.contains(where: { lower.contains($0) }) { continue }
            let abs = absoluteURL(src, base: baseURL)
            if abs != skip && !urls.contains(abs) { urls.append(abs) }
            if urls.count >= 18 { break }
        }
        return urls
    }

    private func absoluteURL(_ src: String, base: URL) -> String {
        if src.hasPrefix("http")  { return src }
        if src.hasPrefix("//")    { return (base.scheme ?? "https") + ":" + src }
        if src.hasPrefix("/")     { return (base.scheme ?? "https") + "://" + (base.host ?? "") + src }
        return base.deletingLastPathComponent().appendingPathComponent(src).absoluteString
    }

    private func downloadImage(_ urlStr: String) async -> Data? {
        guard let url = URL(string: urlStr) else { return nil }
        return try? await URLSession.shared.data(from: url).0
    }
}

// MARK: - Import resultaat model

struct ImportResultaat {
    var bio:               String
    var instagram:         String
    var facebook:          String
    var pinterest:         String
    var tiktok:            String
    var website:           String
    var stijlen:           [String]
    var profielFotoURL:     String   = ""
    var portfolioFotoURLs:  [String] = []
    var voorbeeldFotoURLs:  [String] = []

    var isLeeg: Bool {
        bio.isEmpty && instagram.isEmpty && facebook.isEmpty &&
        pinterest.isEmpty && tiktok.isEmpty && stijlen.isEmpty &&
        profielFotoURL.isEmpty && portfolioFotoURLs.isEmpty && voorbeeldFotoURLs.isEmpty
    }
}

// MARK: - Import preview sheet

struct ImportPreviewSheet: View {
    let resultaat:   ImportResultaat
    let onToepassen: (ImportResultaat) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var applyBio       = true
    @State private var applyInstagram = true
    @State private var applyFacebook  = true
    @State private var applyPinterest = true
    @State private var applyTiktok    = true
    @State private var applyWebsite   = true
    @State private var applyStijlen   = true
    @State private var applyFotos     = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 60)

                    Text("GEVONDEN GEGEVENS")
                        .font(.system(size: 22, weight: .black))
                        .tracking(5)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 6)

                    Text("Selecteer wat je wil overnemen")
                        .font(.system(size: 12))
                        .tracking(1)
                        .foregroundColor(Color(white: 0.4))
                        .padding(.horizontal, 24)

                    Spacer().frame(height: 32)

                    VStack(spacing: 1) {
                        if !resultaat.bio.isEmpty {
                            importRij("BIO", waarde: resultaat.bio, aan: $applyBio)
                        }
                        if !resultaat.instagram.isEmpty {
                            importRij("INSTAGRAM", waarde: resultaat.instagram, aan: $applyInstagram)
                        }
                        if !resultaat.facebook.isEmpty {
                            importRij("FACEBOOK", waarde: resultaat.facebook, aan: $applyFacebook)
                        }
                        if !resultaat.pinterest.isEmpty {
                            importRij("PINTEREST", waarde: resultaat.pinterest, aan: $applyPinterest)
                        }
                        if !resultaat.tiktok.isEmpty {
                            importRij("TIKTOK", waarde: resultaat.tiktok, aan: $applyTiktok)
                        }
                        if !resultaat.website.isEmpty {
                            importRij("WEBSITE", waarde: resultaat.website, aan: $applyWebsite)
                        }
                        if !resultaat.stijlen.isEmpty {
                            importRij("STIJLEN", waarde: resultaat.stijlen.joined(separator: ", "), aan: $applyStijlen)
                        }
                        if !resultaat.profielFotoURL.isEmpty || !resultaat.portfolioFotoURLs.isEmpty {
                            fotoRij
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 100)
                }
            }

            VStack(spacing: 0) {
                Spacer()
                Button(action: toepassen) {
                    Text("OVERNEMEN")
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

    @ViewBuilder
    private var fotoRij: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: $applyFotos)
                .toggleStyle(SwitchToggleStyle(tint: Color(white: 0.9)))
                .labelsHidden()
                .scaleEffect(0.8)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 8) {
                Text("FOTO'S")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color(white: 0.4))
                let totaal = (resultaat.profielFotoURL.isEmpty ? 0 : 1) + resultaat.portfolioFotoURLs.count
                Text("\(totaal) foto\(totaal == 1 ? "" : "'s") gevonden")
                    .font(.system(size: 13))
                    .foregroundColor(.white)

                // Thumbnail strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if !resultaat.profielFotoURL.isEmpty,
                           let url = URL(string: resultaat.profielFotoURL) {
                            AsyncImage(url: url) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                Color(white: 0.12)
                            }
                            .frame(width: 56, height: 56)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color(white: 0.3), lineWidth: 1))
                        }
                        ForEach(resultaat.portfolioFotoURLs.prefix(9), id: \.self) { urlStr in
                            if let url = URL(string: urlStr) {
                                AsyncImage(url: url) { img in
                                    img.resizable().scaledToFill()
                                } placeholder: {
                                    Color(white: 0.12)
                                }
                                .frame(width: 56, height: 56)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(white: 0.07))
        .overlay(Rectangle().stroke(Color(white: 0.1), lineWidth: 1))
    }

    @ViewBuilder
    private func importRij(_ label: String, waarde: String, aan: Binding<Bool>) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: aan)
                .toggleStyle(SwitchToggleStyle(tint: Color(white: 0.9)))
                .labelsHidden()
                .scaleEffect(0.8)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color(white: 0.4))
                Text(waarde)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .lineLimit(4)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(white: 0.07))
        .overlay(Rectangle().stroke(Color(white: 0.1), lineWidth: 1))
    }

    private func toepassen() {
        var r = resultaat
        if !applyBio       { r.bio               = "" }
        if !applyInstagram { r.instagram          = "" }
        if !applyFacebook  { r.facebook           = "" }
        if !applyPinterest { r.pinterest          = "" }
        if !applyTiktok    { r.tiktok             = "" }
        if !applyWebsite   { r.website            = "" }
        if !applyStijlen   { r.stijlen            = [] }
        if !applyFotos     { r.profielFotoURL     = ""; r.portfolioFotoURLs = [] }
        onToepassen(r)
        dismiss()
    }
}

// MARK: - Arties Berichten

struct ArtiesBerichtenView: View {
    @EnvironmentObject var store: ArtiesStore
    @Environment(\.dismiss) private var dismiss

    private var berichten: [Bericht] { store.berichten }

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
                if berichten.isEmpty {
                    Spacer()
                    Image(systemName: "message").font(.system(size: 40)).foregroundColor(Color(white: 0.2))
                    Spacer().frame(height: 16)
                    Text("Geen berichten").font(.system(size: 13)).tracking(1).foregroundColor(Color(white: 0.3))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(berichten) { b in
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
        case "aangevraagd":   "NIEUWE AANVRAAG"
        case "arties_akkoord","shop_akkoord": "AKKOORD ONTVANGEN"
        case "bevestigd":     "AFSPRAAK BEVESTIGD"
        case "geweigerd":     "AFSPRAAK GEWEIGERD"
        default:              type.uppercased()
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
