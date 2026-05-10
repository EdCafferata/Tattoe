import SwiftUI
import AuthenticationServices

// MARK: - Flow orchestrator

struct KlantFlowView: View {
    @EnvironmentObject var store: KlantStore
    let onLogout: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if store.isLoggedIn, let klant = store.klant {
                if klant.voornaam.isEmpty {
                    KlantNAWView(onLogout: onLogout)
                } else if !store.consentGegeven {
                    KlantConsentView(onLogout: onLogout)
                } else {
                    KlantDashboardView(onLogout: onLogout)
                }
            } else {
                KlantAppleLoginView(onLogout: onLogout)
            }
        }
    }
}

// MARK: - Login keuze scherm

struct KlantAppleLoginView: View {
    @EnvironmentObject var store: KlantStore
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

                Text("WELKOM")
                    .font(.system(size: 32, weight: .black))
                    .tracking(8)
                    .foregroundColor(.white)

                Spacer().frame(height: 8)

                Text("Maak een account aan om verder te gaan")
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

            // Laadscherm tijdens CloudKit check
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
            KlantEmailLoginView(onLogout: onLogout)
                .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showEmailRegister) {
            KlantEmailRegisterView(onLogout: onLogout)
                .environmentObject(store)
        }
    }

    #if DEBUG
    private func devInloggen() {
        let testKlant = Klant(
            authMethod:  .email,
            appleUserID: "",
            voornaam:    "Lisa",
            achternaam:  "de Vries",
            email:       "lisa@klant.nl",
            wachtwoord:  "test1234",
            telefoon:    "0687654321",
            straat:      "Damrak",
            huisnummer:  "10",
            postcode:    "1012LG",
            woonplaats:  "Amsterdam"
        )
        store.save(testKlant)
    }
    #endif

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            #if DEBUG
            guard !store.isLoggedIn else { return }
            store.saveLocal(Klant(
                authMethod:  .apple,
                appleUserID: cred.user,
                voornaam:    cred.fullName?.givenName  ?? "",
                achternaam:  cred.fullName?.familyName ?? "",
                email:       cred.email ?? "",
                wachtwoord:  "",
                telefoon:    "",
                straat:      "",
                huisnummer:  "",
                postcode:    "",
                woonplaats:  ""
            ))
            #else
            Task {
                await store.checkCloud(appleUserID: cred.user)
                if !store.isLoggedIn {
                    store.save(Klant(
                        authMethod:  .apple,
                        appleUserID: cred.user,
                        voornaam:    cred.fullName?.givenName  ?? "",
                        achternaam:  cred.fullName?.familyName ?? "",
                        email:       cred.email ?? "",
                        wachtwoord:  "",
                        telefoon:    "",
                        straat:      "",
                        huisnummer:  "",
                        postcode:    "",
                        woonplaats:  ""
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

struct KlantEmailLoginView: View {
    @EnvironmentObject var store: KlantStore
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

                Text("Log in met je account")
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
                Button(action: { email = "lisa@klant.nl"; wachtwoord = "test1234" }) {
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
            WachtwoordResetView(rol: .klant)
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

struct KlantEmailRegisterView: View {
    @EnvironmentObject var store: KlantStore
    let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var voornaam    = ""
    @State private var achternaam  = ""
    @State private var email       = ""
    @State private var wachtwoord  = ""
    @State private var bevestig    = ""
    @State private var telefoon    = ""
    @State private var straat      = ""
    @State private var huisnummer  = ""
    @State private var postcode    = ""
    @State private var woonplaats  = ""
    @State private var fout: String?
    @FocusState private var focus: Veld?

    enum Veld: Hashable {
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

                    Text("Vul al je gegevens in")
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
        voornaam   = "Lisa"
        achternaam = "de Vries"
        email      = "lisa@klant.nl"
        wachtwoord = "test1234"
        bevestig   = "test1234"
        telefoon   = "0687654321"
        straat     = "Damrak"
        huisnummer = "10"
        postcode   = "1012LG"
        woonplaats = "Amsterdam"
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
        fout = nil
        focus = nil

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

        let klant = Klant(
            authMethod:  .email,
            appleUserID: "",
            voornaam:    voornaam,
            achternaam:  achternaam,
            email:       email,
            wachtwoord:  wachtwoord,
            telefoon:    telefoon,
            straat:      straat,
            huisnummer:  huisnummer,
            postcode:    postcode,
            woonplaats:  woonplaats
        )
        store.save(klant)
        dismiss()
    }
}

// MARK: - NAW aanvullen (na Apple login)

struct KlantNAWView: View {
    @EnvironmentObject var store: KlantStore
    let onLogout: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var voornaam   = ""
    @State private var achternaam = ""
    @State private var email      = ""
    @State private var telefoon   = ""
    @State private var straat     = ""
    @State private var huisnummer = ""
    @State private var postcode   = ""
    @State private var woonplaats = ""
    @State private var fout: String?
    @State private var toonVerwijderBevestiging = false
    @State private var bezig = false
    @FocusState private var focus: Veld?

    enum Veld: Hashable {
        case voornaam, achternaam, email, telefoon, straat, huisnummer, postcode, woonplaats
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
                .padding(.bottom, 12)
                Button(action: { toonVerwijderBevestiging = true }) {
                    Text("ACCOUNT VERWIJDEREN")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundColor(Color(red: 0.9, green: 0.25, blue: 0.25))
                }
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
            Text("Al je gegevens worden definitief verwijderd. Dit kan niet ongedaan worden gemaakt.")
        }
    }

    private func prefill() {
        if let k = store.klant {
            voornaam   = k.voornaam
            achternaam = k.achternaam
            email      = k.email
            telefoon   = k.telefoon
            straat     = k.straat
            huisnummer = k.huisnummer
            postcode   = k.postcode
            woonplaats = k.woonplaats
        }
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
        var k = store.klant ?? Klant(authMethod: .apple, appleUserID: "", voornaam: "", achternaam: "",
                                     email: "", wachtwoord: "", telefoon: "", straat: "",
                                     huisnummer: "", postcode: "", woonplaats: "")
        k.voornaam   = voornaam
        k.achternaam = achternaam
        k.email      = email
        k.telefoon   = telefoon
        k.straat     = straat
        k.huisnummer = huisnummer
        k.postcode   = postcode
        k.woonplaats = woonplaats
        store.save(k)
        dismiss()
    }
}

// MARK: - InkField

struct InkField: View {
    let label: String
    @Binding var text: String
    var type:     UITextContentType? = nil
    var keyboard: UIKeyboardType     = .default
    var width:    CGFloat?           = nil
    var secure:   Bool               = false

    init(_ label: String, text: Binding<String>,
         type: UITextContentType? = nil,
         keyboard: UIKeyboardType = .default,
         width: CGFloat? = nil,
         secure: Bool = false) {
        self.label    = label
        self._text    = text
        self.type     = type
        self.keyboard = keyboard
        self.width    = width
        self.secure   = secure
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .tracking(3)
                .foregroundColor(Color(white: 0.4))
            Group {
                if secure {
                    SecureField("", text: $text)
                } else {
                    TextField("", text: $text)
                        .textContentType(type)
                        .keyboardType(keyboard)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(
                            keyboard == .emailAddress || keyboard == .phonePad ? .never : .words
                        )
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .tint(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: width ?? .infinity, alignment: .leading)
        .background(Color(white: 0.07))
        .overlay(Rectangle().stroke(Color(white: 0.15), lineWidth: 1))
    }
}

// MARK: - Consent

struct KlantConsentView: View {
    @EnvironmentObject var store: KlantStore
    let onLogout: () -> Void

    @State private var consentFormulier = false
    @State private var handtekening     = false
    @State private var risicoNazorg     = false
    @State private var bevestiging      = false
    @State private var uitgevouwen: Int? = nil

    private var alleAkkoord: Bool {
        consentFormulier && handtekening && risicoNazorg && bevestiging
    }

    private let items: [(Int, String, String, String)] = [
        (0, "doc.text.fill",       "Digitale consentformulieren",
         "Ik heb het consentformulier voor de tattoo behandeling gelezen en ga akkoord met de inhoud hiervan."),
        (1, "pencil.and.scribble", "Digitale handtekening",
         "Ik bevestig met mijn akkoord dat ik dit formulier rechtsgeldig digitaal onderteken als vervanging van een fysieke handtekening."),
        (2, "link",                "Risico-informatie & nazorg",
         "Ik heb de informatie over de risico's van tatoeëren en de nazorginstructies gelezen en begrepen. Ik weet wat er van mij wordt verwacht na de behandeling."),
        (3, "checkmark.shield.fill","Bevestiging",
         "Ik bevestig dat ik volledig op de hoogte ben van alle risico's verbonden aan het tatoeëren en dat ik deze risico's vrijwillig en bewust accepteer."),
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Header ────────────────────────────────
                VStack(spacing: 6) {
                    Spacer().frame(height: 56)
                    Text("CONSENT &")
                        .font(.system(size: 26, weight: .black))
                        .tracking(6)
                        .foregroundColor(.white)
                    Text("INFORMATIEPLICHT")
                        .font(.system(size: 26, weight: .black))
                        .tracking(6)
                        .foregroundColor(.white)
                    Spacer().frame(height: 8)
                    Text("Lees elk punt en vink het aan om verder te gaan")
                        .font(.system(size: 11))
                        .tracking(1.5)
                        .foregroundColor(Color(white: 0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer().frame(height: 32)

                // ── Consent kaarten ───────────────────────
                ScrollView {
                    VStack(spacing: 10) {
                        consentKaart(index: 0, binding: $consentFormulier)
                        consentKaart(index: 1, binding: $handtekening)
                        consentKaart(index: 2, binding: $risicoNazorg)
                        consentKaart(index: 3, binding: $bevestiging)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }

                // ── Bevestig knop ─────────────────────────
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(white: 0.1))
                        .frame(height: 1)

                    Button(action: { if alleAkkoord { store.saveConsent() } }) {
                        HStack {
                            Spacer()
                            Text("IK GA AKKOORD")
                                .font(.system(size: 14, weight: .black))
                                .tracking(4)
                                .foregroundColor(alleAkkoord ? .black : Color(white: 0.3))
                            Spacer()
                        }
                        .frame(height: 56)
                        .background(alleAkkoord ? Color.white : Color(white: 0.12))
                    }
                    .disabled(!alleAkkoord)
                    .animation(.easeInOut(duration: 0.2), value: alleAkkoord)

                    Button(action: { store.logout(); onLogout() }) {
                        Text("UITLOGGEN")
                            .font(.system(size: 10))
                            .tracking(3)
                            .foregroundColor(Color(white: 0.25))
                    }
                    .padding(.vertical, 14)
                }
            }
        }
    }

    @ViewBuilder
    private func consentKaart(index: Int, binding: Binding<Bool>) -> some View {
        let (i, icoon, titel, tekst) = items[index]
        let open = uitgevouwen == i

        Button(action: {
            withAnimation(.easeInOut(duration: 0.22)) {
                uitgevouwen = open ? nil : i
            }
        }) {
            VStack(spacing: 0) {
                // ── Rij ──
                HStack(spacing: 14) {
                    Image(systemName: icoon)
                        .font(.system(size: 18))
                        .foregroundColor(binding.wrappedValue ? .white : Color(white: 0.4))
                        .frame(width: 24)

                    Text(titel)
                        .font(.system(size: 13, weight: .semibold))
                        .tracking(1)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Vinkje
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(binding.wrappedValue ? Color.white : Color(white: 0.3), lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                        if binding.wrappedValue {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                // ── Uitgevouwen tekst ──
                if open {
                    VStack(alignment: .leading, spacing: 16) {
                        Rectangle()
                            .fill(Color(white: 0.15))
                            .frame(height: 1)

                        Text(tekst)
                            .font(.system(size: 12))
                            .tracking(0.3)
                            .foregroundColor(Color(white: 0.6))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 16)

                        // Akkoord knop in kaart
                        Button(action: {
                            binding.wrappedValue = true
                            withAnimation { uitgevouwen = nil }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: binding.wrappedValue ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 13))
                                Text(binding.wrappedValue ? "Akkoord" : "Klik om akkoord te gaan")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(1)
                            }
                            .foregroundColor(binding.wrappedValue ? Color(white: 0.5) : .white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .disabled(binding.wrappedValue)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(binding.wrappedValue ? Color(white: 0.09) : Color(white: 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(binding.wrappedValue ? Color(white: 0.3) : Color(white: 0.12), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tattoo machine pin

private struct TattoeMachineIcon: View {
    var color: Color = .white

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height

            // Motor/body bovenaan (breed afgerond blok)
            ctx.fill(
                Path(roundedRect: CGRect(x: w*0.18, y: h*0.00, width: w*0.64, height: h*0.24), cornerRadius: w*0.08),
                with: .color(color)
            )
            // Spoel links van motor (twee ovalen)
            ctx.stroke(
                Path(ellipseIn: CGRect(x: w*0.02, y: h*0.03, width: w*0.18, height: h*0.14)),
                with: .color(color), lineWidth: max(1.0, w*0.06)
            )
            ctx.stroke(
                Path(ellipseIn: CGRect(x: w*0.02, y: h*0.10, width: w*0.18, height: h*0.14)),
                with: .color(color), lineWidth: max(1.0, w*0.06)
            )
            // Grip (smalere cilinder in het midden)
            ctx.fill(
                Path(roundedRect: CGRect(x: w*0.30, y: h*0.24, width: w*0.40, height: h*0.42), cornerRadius: w*0.06),
                with: .color(color)
            )
            // Grip ribbels
            for i in 0..<4 {
                let y = h * (0.29 + Double(i) * 0.09)
                ctx.fill(
                    Path(roundedRect: CGRect(x: w*0.28, y: y, width: w*0.44, height: h*0.025), cornerRadius: 1),
                    with: .color(color.opacity(0.30))
                )
            }
            // Verbinding grip → naald (smaller blok)
            ctx.fill(
                Path(roundedRect: CGRect(x: w*0.38, y: h*0.66, width: w*0.24, height: h*0.12), cornerRadius: w*0.04),
                with: .color(color)
            )
            // Naald (driehoek naar beneden)
            var naald = Path()
            naald.move(to:    CGPoint(x: w*0.38, y: h*0.77))
            naald.addLine(to: CGPoint(x: w*0.62, y: h*0.77))
            naald.addLine(to: CGPoint(x: w*0.50, y: h*1.00))
            naald.closeSubpath()
            ctx.fill(naald, with: .color(color))
        }
    }
}

private struct TattoePinView: View {
    var geselecteerd: Bool = false
    var kleur: Color = .white

    var body: some View {
        TattoeMachineIcon(color: geselecteerd ? kleur.opacity(0.5) : kleur)
            .frame(width: 36, height: 44)
            .shadow(color: .white.opacity(0.0), radius: 0)
            .background(Color.clear)
            .scaleEffect(geselecteerd ? 1.25 : 1.0)
            .animation(.spring(duration: 0.2), value: geselecteerd)
    }
}

// MARK: - Dashboard

#if DEBUG
private let standaardCoord = CLLocationCoordinate2D(latitude: 51.4416, longitude: 5.4697) // Eindhoven
#else
private let standaardCoord = CLLocationCoordinate2D(latitude: 52.3676, longitude: 4.9041) // Amsterdam fallback
#endif

// Wikkelt CLLocationManager zodat SwiftUI de locatie kan observeren
@MainActor
@Observable
final class LocatieBeheerder: NSObject, CLLocationManagerDelegate {
    var locatie: CLLocationCoordinate2D? = nil
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        Task { @MainActor in self.locatie = loc.coordinate }
    }

    nonisolated func locationManager(_ manager: CLLocationManager,
                                     didFailWithError error: Error) {}
}

struct KlantDashboardView: View {
    @EnvironmentObject var store: KlantStore
    let onLogout: () -> Void

    @State private var showBewerken     = false
    @State private var showOntdekken    = false
    @State private var showShopZoeker   = false
    @State private var showArtiesZoeker = false
    @State private var showBerichten    = false
    @State private var shopArtiesten:   [ArtiestProfiel] = []
    @State private var ladenArtiesten   = false

    // Kaart
    @State private var alleShops:      [ShopProfiel] = []
    @State private var shopLocaties:   [String: CLLocationCoordinate2D] = [:]
    @State private var ladenKaart      = false
    @State private var kaartZoekterm   = ""
    @State private var zoekResultaten: [ShopPin] = []
    @State private var ladenZoek       = false
    @State private var geselecteerdePin: ShopPin? = nil
    @State private var cameraPosition  = MapCameraPosition.region(MKCoordinateRegion(
        center: standaardCoord,
        span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
    ))
    #if !DEBUG
    @State private var locatieBeheerder = LocatieBeheerder()
    #endif
    @State private var favorietShopLocatie:   CLLocationCoordinate2D? = nil
    @State private var favorietArtiesLocatie: CLLocationCoordinate2D? = nil
    @State private var showAfspraakShop      = false
    @State private var showAfspraakArties    = false

    private var favorietShopPin: ShopPin? {
        guard let coord = favorietShopLocatie, let shop = store.favorietShop else { return nil }
        return ShopPin(id: "fav-shop-\(shop.email)", naam: shop.bedrijfsnaam, coordinate: coord, email: shop.email)
    }

    private var favorietArtiesPin: ShopPin? {
        guard let coord = favorietArtiesLocatie, let artiest = store.favorietArties else { return nil }
        return ShopPin(id: "fav-arties-\(artiest.email)",
                       naam: artiest.kunstnaam.isEmpty ? artiest.email : artiest.kunstnaam,
                       coordinate: coord, email: artiest.email)
    }

    private var dichtstbijzijndeShops: [ShopPin] {
        #if DEBUG
        let centrum = standaardCoord
        #else
        let centrum = locatieBeheerder.locatie ?? standaardCoord
        #endif
        let metLocatie: [ShopPin] = alleShops.compactMap { shop in
            guard let coord = shopLocaties[shop.email] else { return nil }
            return ShopPin(id: shop.email, naam: shop.bedrijfsnaam, coordinate: coord, email: shop.email)
        }
        let gesorteerd = metLocatie.sorted {
            afstand($0.coordinate, centrum) < afstand($1.coordinate, centrum)
        }
        return Array(gesorteerd.prefix(5))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 52)

                    // ── Header ──────────────────────────────
                    VStack(spacing: 5) {
                        Text("WELKOM TERUG")
                            .font(.system(size: 24, weight: .black))
                            .tracking(5)
                            .foregroundColor(.white)
                        if let k = store.klant {
                            Text("\(k.voornaam) \(k.achternaam)")
                                .font(.system(size: 12))
                                .tracking(2)
                                .foregroundColor(Color(white: 0.4))
                        }
                        HStack(spacing: 14) {
                            Button(action: { showBewerken = true }) {
                                Text("AANPASSEN")
                                    .font(.system(size: 9, weight: .semibold))
                                    .tracking(2)
                                    .foregroundColor(Color(white: 0.28))
                            }
                            Text("·").foregroundColor(Color(white: 0.15))
                            Button(action: { showBerichten = true }) {
                                ZStack(alignment: .topTrailing) {
                                    Text("BERICHTEN")
                                        .font(.system(size: 9, weight: .semibold))
                                        .tracking(2)
                                        .foregroundColor(Color(white: 0.28))
                                    if store.ongelezen > 0 {
                                        Text("\(store.ongelezen)")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.black)
                                            .frame(minWidth: 14, minHeight: 14)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .offset(x: 4, y: -4)
                                    }
                                }
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
                    .padding(.bottom, 16)

                    // ── Shop + Artiest compacte rij ──────────
                    HStack(spacing: 0) {
                        shopArtiesKolom(
                            label: "SHOP",
                            naam: store.favorietShop?.bedrijfsnaam,
                            isGekozen: store.favorietShop != nil,
                            onTap: { showShopZoeker = true },
                            onAfspraak: store.favorietShop != nil ? { showAfspraakShop = true } : nil
                        )
                        Rectangle().fill(Color(white: 0.11)).frame(width: 1).padding(.vertical, 8)
                        shopArtiesKolom(
                            label: "ARTIEST",
                            naam: store.favorietArties.map { $0.kunstnaam.isEmpty ? $0.email : $0.kunstnaam },
                            isGekozen: store.favorietArties != nil,
                            onTap: { showArtiesZoeker = true },
                            onAfspraak: store.favorietArties != nil ? { showAfspraakArties = true } : nil
                        )
                    }
                    .background(Color(white: 0.06))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.11), lineWidth: 1))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)

                    // ── Ontdekken knop ───────────────────────
                    Button(action: { showOntdekken = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkle.magnifyingglass")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.55))
                            Text("ONTDEK SHOPS & ARTIESTEN")
                                .font(.system(size: 10, weight: .semibold))
                                .tracking(2.5)
                                .foregroundColor(Color(white: 0.55))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10))
                                .foregroundColor(Color(white: 0.25))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(white: 0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.12), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 10)

                    // ── Kaart label ──────────────────────────
                    HStack {
                        Text("SHOPS IN DE BUURT")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(4)
                            .foregroundColor(Color(white: 0.3))
                        Spacer()
                        if ladenKaart { ProgressView().tint(Color(white: 0.35)).scaleEffect(0.7) }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 6)

                    // ── Kaart (vult resterende ruimte) ───────
                    ZStack(alignment: .topLeading) {
                        Map(position: $cameraPosition) {
                            ForEach(dichtstbijzijndeShops) { pin in
                                Annotation("", coordinate: pin.coordinate, anchor: .bottom) {
                                    Button(action: { geselecteerdePin = pin }) {
                                        TattoePinView(geselecteerd: geselecteerdePin?.id == pin.id, kleur: .black)
                                    }
                                }
                            }
                            ForEach(zoekResultaten) { pin in
                                Annotation("", coordinate: pin.coordinate, anchor: .bottom) {
                                    Button(action: { geselecteerdePin = pin }) {
                                        TattoePinView(geselecteerd: geselecteerdePin?.id == pin.id, kleur: .black)
                                    }
                                }
                            }
                            if let pin = favorietShopPin {
                                Annotation("", coordinate: pin.coordinate, anchor: .bottom) {
                                    Button(action: { geselecteerdePin = pin }) {
                                        TattoePinView(geselecteerd: geselecteerdePin?.id == pin.id, kleur: Color(red: 1.0, green: 0.55, blue: 0.0))
                                    }
                                }
                            }
                            if let pin = favorietArtiesPin {
                                Annotation("", coordinate: pin.coordinate, anchor: .bottom) {
                                    TattoePinView(kleur: Color(red: 0.3, green: 0.85, blue: 0.5))
                                }
                            }
                        }
                        .mapStyle(.standard)

                        // Zoekbalk
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13))
                                .foregroundColor(Color(white: 0.4))
                            TextField("", text: $kaartZoekterm)
                                .font(.system(size: 13))
                                .foregroundColor(.black)
                                .autocorrectionDisabled()
                                .submitLabel(.search)
                                .onSubmit { Task { await zoekOpKaart() } }
                                .overlay(
                                    Group {
                                        if kaartZoekterm.isEmpty {
                                            Text("Zoek stad of plaats...")
                                                .font(.system(size: 13))
                                                .foregroundColor(Color(white: 0.5))
                                                .allowsHitTesting(false)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    }
                                )
                            if ladenZoek {
                                ProgressView().scaleEffect(0.7)
                            } else if !kaartZoekterm.isEmpty {
                                Button(action: { kaartZoekterm = ""; zoekResultaten = [] }) {
                                    Image(systemName: "xmark.circle.fill").foregroundColor(Color(white: 0.4))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, 12)
                        .padding(.top, 12)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 24)
                    .frame(maxHeight: .infinity)
                    .layoutPriority(1)

                    // ── Info-kaartje onder de kaart ──────────
                    if let pin = geselecteerdePin {
                        ShopInfoKaartje(
                            pin: pin,
                            appShop: alleShops.first(where: { $0.email == pin.email }),
                            isFavoriet: store.favorietShop?.email == pin.email,
                            onSelecteer: { shop in store.slaFavorietShop(shop); geselecteerdePin = nil },
                            onSluit: { geselecteerdePin = nil }
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                Spacer().frame(height: 24)
            }
            .animation(.easeInOut(duration: 0.2), value: geselecteerdePin?.id)
        }
        .task { await laadAlles() }
        #if !DEBUG
        .onChange(of: locatieBeheerder.locatie?.latitude) { _, _ in
            guard let loc = locatieBeheerder.locatie else { return }
            cameraPosition = .region(MKCoordinateRegion(
                center: loc,
                span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
            ))
            Task { await zoekTattooshopsOpKaart(nabij: loc) }
        }
        #endif
        .onChange(of: store.favorietShop?.email) { _, nieuw in
            guard let email = nieuw else { shopArtiesten = []; return }
            Task {
                ladenArtiesten = true
                shopArtiesten = await CloudKitManager.shared.fetchArtiesten(voorShop: email)
                ladenArtiesten = false
            }
            // Geocode favoriet shop voor op kaart
            if let shop = store.favorietShop, !shop.woonplaats.isEmpty {
                Task {
                    let geocoder = CLGeocoder()
                    if let p = try? await geocoder.geocodeAddressString(shop.woonplaats + ", Nederland"),
                       let loc = p.first?.location { favorietShopLocatie = loc.coordinate }
                }
            }
        }
        .onChange(of: store.favorietArties?.email) { _, _ in
            if let artiest = store.favorietArties, !artiest.woonplaats.isEmpty {
                Task {
                    let geocoder = CLGeocoder()
                    if let p = try? await geocoder.geocodeAddressString(artiest.woonplaats + ", Nederland"),
                       let loc = p.first?.location { favorietArtiesLocatie = loc.coordinate }
                }
            } else {
                favorietArtiesLocatie = nil
            }
        }
        .fullScreenCover(isPresented: $showBewerken) {
            KlantNAWView(onLogout: onLogout).environmentObject(store)
        }
        .fullScreenCover(isPresented: $showBerichten) {
            KlantBerichtenView().environmentObject(store)
        }
        .fullScreenCover(isPresented: $showOntdekken) {
            KlantOntdekkenView().environmentObject(store)
        }
        .fullScreenCover(isPresented: $showShopZoeker) {
            KlantShopZoekerView().environmentObject(store)
        }
        .fullScreenCover(isPresented: $showArtiesZoeker) {
            KlantArtiesZoekerView().environmentObject(store)
        }
        .sheet(isPresented: $showAfspraakShop) {
            if let shop = store.favorietShop {
                KlantAfspraakAanvraagView(naam: shop.bedrijfsnaam, email: shop.email, type: .shop)
                    .environmentObject(store)
            }
        }
        .sheet(isPresented: $showAfspraakArties) {
            if let artiest = store.favorietArties {
                KlantAfspraakAanvraagView(
                    naam:  artiest.kunstnaam.isEmpty ? artiest.email : artiest.kunstnaam,
                    email: artiest.email,
                    type:  .artiest
                )
                .environmentObject(store)
            }
        }
    }

    @ViewBuilder
    private func shopArtiesKolom(label: String, naam: String?, isGekozen: Bool,
                                  onTap: @escaping () -> Void,
                                  onAfspraak: (() -> Void)?) -> some View {
        ZStack(alignment: .trailing) {
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(label)
                            .font(.system(size: 8, weight: .bold))
                            .tracking(4)
                            .foregroundColor(Color(white: 0.3))
                        Text(naam ?? "Niet gekozen")
                            .font(.system(size: 13, weight: isGekozen ? .semibold : .regular))
                            .foregroundColor(isGekozen ? .white : Color(white: 0.22))
                            .lineLimit(1)
                    }
                    Spacer()
                    Color.clear.frame(width: 34, height: 34)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .foregroundColor(.white)

            if let onAfspraak {
                Button(action: onAfspraak) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 13))
                        .foregroundColor(Color(white: 0.38))
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .padding(.trailing, 8)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(Color(white: 0.2))
                    .padding(.trailing, 20)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private func afspraakRij(naam: String, subtitel: String, kleur: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(kleur.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 15))
                    .foregroundColor(kleur)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("AFSPRAAK · \(subtitel)")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color(white: 0.35))
                Text(naam)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
                .foregroundColor(Color(white: 0.3))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(white: 0.08))
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.14), lineWidth: 1))
    }

    private func laadAlles() async {
        ladenKaart = true

        // CloudKit shops ophalen + geocoden (app-shops, witte pins)
        alleShops = await CloudKitManager.shared.fetchPubliekeShops()

        #if DEBUG
        // Testdata: Dragon Tattoo in Eindhoven
        let dragonShop = ShopProfiel(
            id: "debug-dragontattoo@test.nl",
            bedrijfsnaam: "Dragon Tattoo",
            woonplaats: "Eindhoven",
            email: "dragontattoo@test.nl"
        )
        if !alleShops.contains(where: { $0.id == dragonShop.id }) {
            alleShops.append(dragonShop)
        }
        shopLocaties[dragonShop.email] = CLLocationCoordinate2D(latitude: 51.4379, longitude: 5.4786)
        #endif

        await geocodeShops()

        // Alle tattooshops via Apple Maps zoeken (ook niet in app, rode pins)
        #if DEBUG
        let centrumVoorZoeken = standaardCoord
        #else
        let centrumVoorZoeken = locatieBeheerder.locatie ?? standaardCoord
        #endif
        await zoekTattooshopsOpKaart(nabij: centrumVoorZoeken)

        ladenKaart = false

        // Geocode favorieten voor op kaart
        let geocoder = CLGeocoder()
        if let shop = store.favorietShop, favorietShopLocatie == nil, !shop.woonplaats.isEmpty {
            if let p = try? await geocoder.geocodeAddressString(shop.woonplaats + ", Nederland"),
               let loc = p.first?.location { favorietShopLocatie = loc.coordinate }
        }
        if let artiest = store.favorietArties, favorietArtiesLocatie == nil, !artiest.woonplaats.isEmpty {
            if let p = try? await geocoder.geocodeAddressString(artiest.woonplaats + ", Nederland"),
               let loc = p.first?.location { favorietArtiesLocatie = loc.coordinate }
        }

        // Artiesten van geselecteerde shop
        if let shop = store.favorietShop {
            ladenArtiesten = true
            shopArtiesten = await CloudKitManager.shared.fetchArtiesten(voorShop: shop.email)
            ladenArtiesten = false
        }
    }

    private func zoekTattooshopsOpKaart(nabij center: CLLocationCoordinate2D) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "tattoo"
        request.region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
        guard let response = try? await MKLocalSearch(request: request).start() else { return }

        zoekResultaten = response.mapItems.prefix(5).map { item in
            ShopPin(
                id: "\(item.placemark.coordinate.latitude)-\(item.name ?? "")",
                naam: item.name ?? "Tattoo Shop",
                coordinate: item.placemark.coordinate,
                email: "",
                mapItem: item
            )
        }

        // Zoom strak in op de gevonden shops (max span 0.08 zodat pins goed klikbaar zijn)
        let allePins = zoekResultaten + dichtstbijzijndeShops
        guard !allePins.isEmpty else { return }
        let lats = allePins.map { $0.coordinate.latitude }
        let lons = allePins.map { $0.coordinate.longitude }
        let spanLat = min(max((lats.max()! - lats.min()!) * 1.5, 0.04), 0.12)
        let spanLon = min(max((lons.max()! - lons.min()!) * 1.5, 0.04), 0.12)
        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (lats.min()! + lats.max()!) / 2,
                                           longitude: (lons.min()! + lons.max()!) / 2),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        ))
    }

    private func geocodeShops() async {
        let geocoder = CLGeocoder()
        for shop in alleShops {
            guard shopLocaties[shop.email] == nil, !shop.woonplaats.isEmpty else { continue }
            if let placemark = try? await geocoder.geocodeAddressString(shop.woonplaats + ", Nederland"),
               let loc = placemark.first?.location {
                shopLocaties[shop.email] = loc.coordinate
            }
        }
        pasCameraAanOpShops()
    }

    private func pasCameraAanOpShops() {
        let pins = dichtstbijzijndeShops
        guard !pins.isEmpty else { return }

        let lats = pins.map(\.coordinate.latitude)
        let lons = pins.map(\.coordinate.longitude)
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        let spanLat   = max((maxLat - minLat) * 1.6, 0.05)
        let spanLon   = max((maxLon - minLon) * 1.6, 0.05)

        cameraPosition = .region(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: MKCoordinateSpan(latitudeDelta: spanLat, longitudeDelta: spanLon)
        ))
    }

    private func afstand(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let lat = (a.latitude - b.latitude)
        let lon = (a.longitude - b.longitude)
        return lat * lat + lon * lon
    }

    private func zoekOpKaart() async {
        let term = kaartZoekterm.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return }
        ladenZoek = true
        defer { ladenZoek = false }

        let geocoder = CLGeocoder()
        guard let placemark = try? await geocoder.geocodeAddressString(term + ", Nederland"),
              let center = placemark.first?.location?.coordinate else { return }

        await zoekTattooshopsOpKaart(nabij: center)
    }
}

// MARK: - Shop zoeker

import MapKit
import CoreLocation

// MARK: - Ontdekken (browse alle shops + artiesten)

struct KlantOntdekkenView: View {
    @EnvironmentObject var store: KlantStore
    @Environment(\.dismiss) private var dismiss

    @State private var segment:   Int              = 0   // 0=Shops, 1=Artiesten
    @State private var zoekterm:  String           = ""
    @State private var shops:     [ShopProfiel]    = []
    @State private var artiesten: [ArtiestProfiel] = []
    @State private var laden:     Bool             = false

    private var gefilterdShops: [ShopProfiel] {
        zoekterm.isEmpty ? shops : shops.filter {
            $0.bedrijfsnaam.localizedCaseInsensitiveContains(zoekterm) ||
            $0.woonplaats.localizedCaseInsensitiveContains(zoekterm)
        }
    }

    private var gefilterdArtiesten: [ArtiestProfiel] {
        zoekterm.isEmpty ? artiesten : artiesten.filter {
            $0.kunstnaam.localizedCaseInsensitiveContains(zoekterm) ||
            $0.woonplaats.localizedCaseInsensitiveContains(zoekterm) ||
            $0.stijlen.joined(separator: " ").localizedCaseInsensitiveContains(zoekterm) ||
            $0.specialisatie.localizedCaseInsensitiveContains(zoekterm)
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──
                HStack {
                    Text("ONTDEKKEN")
                        .font(.system(size: 20, weight: .black))
                        .tracking(5)
                        .foregroundColor(.white)
                    Spacer()
                    if laden { ProgressView().tint(Color(white: 0.4)).scaleEffect(0.8) }
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(white: 0.4))
                            .frame(width: 34, height: 34)
                            .background(Color(white: 0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 16)

                // ── Segment ──
                HStack(spacing: 0) {
                    ForEach(["SHOPS", "ARTIESTEN"].indices, id: \.self) { i in
                        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { segment = i; zoekterm = "" } }) {
                            Text(["SHOPS", "ARTIESTEN"][i])
                                .font(.system(size: 10, weight: .bold))
                                .tracking(3)
                                .foregroundColor(segment == i ? .black : Color(white: 0.4))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(segment == i ? Color.white : Color.clear)
                        }
                    }
                }
                .background(Color(white: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 24)
                .padding(.bottom, 12)

                // ── Zoekveld ──
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(white: 0.4))
                        .font(.system(size: 13))
                    TextField("", text: $zoekterm)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .overlay(
                            Group {
                                if zoekterm.isEmpty {
                                    Text(segment == 0 ? "ZOEK OP NAAM OF STAD" : "ZOEK OP NAAM, STIJL OF STAD")
                                        .font(.system(size: 10))
                                        .tracking(2)
                                        .foregroundColor(Color(white: 0.3))
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        )
                    if !zoekterm.isEmpty {
                        Button(action: { zoekterm = "" }) {
                            Image(systemName: "xmark.circle.fill").foregroundColor(Color(white: 0.35))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color(white: 0.08))
                .overlay(Rectangle().stroke(Color(white: 0.13), lineWidth: 1))
                .padding(.horizontal, 24)
                .padding(.bottom, 4)

                // ── Lijst ──
                ScrollView {
                    LazyVStack(spacing: 1) {
                        if segment == 0 {
                            if gefilterdShops.isEmpty && !laden {
                                leegMelding("Geen shops gevonden")
                            } else {
                                ForEach(gefilterdShops) { shop in shopRij(shop) }
                            }
                        } else {
                            if gefilterdArtiesten.isEmpty && !laden {
                                leegMelding("Geen artiesten gevonden")
                            } else {
                                ForEach(gefilterdArtiesten) { artiest in artiesRij(artiest) }
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .task { await laadAlles() }
    }

    @ViewBuilder
    private func shopRij(_ shop: ShopProfiel) -> some View {
        let isFav = store.favorietShop?.email == shop.email
        Button(action: { store.slaFavorietShop(shop); dismiss() }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isFav ? Color.white.opacity(0.12) : Color(white: 0.08))
                        .frame(width: 40, height: 40)
                    Image(systemName: "storefront")
                        .font(.system(size: 16))
                        .foregroundColor(isFav ? .white : Color(white: 0.3))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(shop.bedrijfsnaam)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    if !shop.woonplaats.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin").font(.system(size: 9))
                            Text(shop.woonplaats).font(.system(size: 11))
                        }
                        .foregroundColor(Color(white: 0.4))
                    }
                }
                Spacer()
                if isFav {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(isFav ? Color(white: 0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        Rectangle().fill(Color(white: 0.09)).frame(height: 1).padding(.horizontal, 24)
    }

    @ViewBuilder
    private func artiesRij(_ artiest: ArtiestProfiel) -> some View {
        let isFav = store.favorietArties?.email == artiest.email
        Button(action: { store.slaFavorietArties(artiest); dismiss() }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isFav ? Color.white.opacity(0.12) : Color(white: 0.08))
                        .frame(width: 40, height: 40)
                    Image(systemName: "paintbrush.pointed")
                        .font(.system(size: 15))
                        .foregroundColor(isFav ? .white : Color(white: 0.3))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(artiest.kunstnaam.isEmpty ? artiest.email : artiest.kunstnaam)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    if !artiest.specialisatie.isEmpty || !artiest.woonplaats.isEmpty {
                        HStack(spacing: 6) {
                            if !artiest.woonplaats.isEmpty {
                                HStack(spacing: 3) {
                                    Image(systemName: "mappin").font(.system(size: 9))
                                    Text(artiest.woonplaats).font(.system(size: 11))
                                }
                            }
                            if !artiest.specialisatie.isEmpty && !artiest.woonplaats.isEmpty {
                                Text("·").font(.system(size: 10)).foregroundColor(Color(white: 0.25))
                            }
                            if !artiest.specialisatie.isEmpty {
                                Text(artiest.specialisatie).font(.system(size: 11))
                            }
                        }
                        .foregroundColor(Color(white: 0.4))
                    }
                    if !artiest.stijlen.isEmpty {
                        Text(artiest.stijlen.prefix(3).joined(separator: " · "))
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.28))
                    }
                }
                Spacer()
                if isFav {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(isFav ? Color(white: 0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        Rectangle().fill(Color(white: 0.09)).frame(height: 1).padding(.horizontal, 24)
    }

    @ViewBuilder
    private func leegMelding(_ tekst: String) -> some View {
        Text(tekst)
            .font(.system(size: 12)).tracking(2)
            .foregroundColor(Color(white: 0.3))
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
    }

    private func laadAlles() async {
        laden = true
        async let s = CloudKitManager.shared.fetchPubliekeShops()
        async let a = CloudKitManager.shared.fetchPubliekeArtiesten()
        shops     = await s
        artiesten = await a
        laden = false
    }
}

struct KlantShopZoekerView: View {
    @EnvironmentObject var store: KlantStore
    @Environment(\.dismiss) private var dismiss

    @State private var shops: [ShopProfiel] = []
    @State private var locaties: [String: CLLocationCoordinate2D] = [:]
    @State private var zoekterm = ""
    @State private var laden = false
    @State private var cameraPosition = MapCameraPosition.region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 52.37, longitude: 4.89),
        span: MKCoordinateSpan(latitudeDelta: 3.5, longitudeDelta: 3.5)
    ))

    private var gefilterd: [ShopProfiel] {
        zoekterm.isEmpty ? shops : shops.filter {
            $0.bedrijfsnaam.localizedCaseInsensitiveContains(zoekterm) ||
            $0.woonplaats.localizedCaseInsensitiveContains(zoekterm)
        }
    }

    private var pinsOpKaart: [ShopPin] {
        gefilterd.compactMap { shop in
            guard let coord = locaties[shop.email] else { return nil }
            return ShopPin(id: shop.email, naam: shop.bedrijfsnaam, coordinate: coord, email: shop.email)
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──
                HStack {
                    Text("SHOP ZOEKEN")
                        .font(.system(size: 20, weight: .black))
                        .tracking(5)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(white: 0.4))
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 16)

                // ── Kaart ──
                Map(position: $cameraPosition) {
                    ForEach(pinsOpKaart) { pin in
                        Annotation(pin.naam, coordinate: pin.coordinate, anchor: .bottom) {
                            Button(action: {
                                if let shop = shops.first(where: { $0.email == pin.email }) {
                                    store.slaFavorietShop(shop)
                                    dismiss()
                                }
                            }) {
                                TattoePinView(
                                    geselecteerd: store.favorietShop?.email == pin.email,
                                    kleur: .white
                                )
                            }
                        }
                    }
                }
                .mapStyle(.standard)
                .frame(height: 250)

                // ── Zoek veld ──
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(white: 0.4))
                        .font(.system(size: 13))
                    TextField("", text: $zoekterm)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .overlay(
                            Group {
                                if zoekterm.isEmpty {
                                    Text("ZOEK OP NAAM OF STAD")
                                        .font(.system(size: 10))
                                        .tracking(2)
                                        .foregroundColor(Color(white: 0.3))
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                .overlay(Rectangle().stroke(Color(white: 0.15), lineWidth: 1))
                .padding(.horizontal, 24)
                .padding(.top, 12)

                // ── Lijst ──
                if laden {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if gefilterd.isEmpty {
                    Spacer()
                    Text("Geen shops gevonden")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.3))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(gefilterd) { shop in
                                Button(action: {
                                    store.slaFavorietShop(shop)
                                    dismiss()
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(shop.bedrijfsnaam)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                            Text(shop.woonplaats)
                                                .font(.system(size: 11))
                                                .foregroundColor(Color(white: 0.4))
                                        }
                                        Spacer()
                                        if store.favorietShop?.email == shop.email {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(store.favorietShop?.email == shop.email ? Color(white: 0.1) : Color.clear)
                                }
                                Rectangle().fill(Color(white: 0.1)).frame(height: 1)
                                    .padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .task {
            laden = true
            shops = await CloudKitManager.shared.fetchPubliekeShops()
            laden = false
            await geocodeShops()
        }
    }

    private func geocodeShops() async {
        let geocoder = CLGeocoder()
        for shop in shops {
            guard locaties[shop.email] == nil, !shop.woonplaats.isEmpty else { continue }
            if let placemark = try? await geocoder.geocodeAddressString(shop.woonplaats + ", Nederland"),
               let loc = placemark.first?.location {
                locaties[shop.email] = loc.coordinate
            }
        }
    }
}

private struct ShopPin: Identifiable {
    let id: String
    let naam: String
    let coordinate: CLLocationCoordinate2D
    let email: String
    let mapItem: MKMapItem?

    init(id: String, naam: String, coordinate: CLLocationCoordinate2D, email: String, mapItem: MKMapItem? = nil) {
        self.id = id; self.naam = naam; self.coordinate = coordinate
        self.email = email; self.mapItem = mapItem
    }
}

// MARK: - Shop info kaartje (pin detail)

private struct ShopInfoKaartje: View {
    let pin: ShopPin
    let appShop: ShopProfiel?
    let isFavoriet: Bool
    let onSelecteer: (ShopProfiel) -> Void
    let onSluit: () -> Void

    @State private var gevondenEmail: String? = nil
    @State private var zoektEmail = false

    private var adres: String? {
        guard let p = pin.mapItem?.placemark else { return nil }
        let delen = [p.subThoroughfare, p.thoroughfare, p.postalCode, p.locality]
            .compactMap { $0 }.filter { !$0.isEmpty }
        return delen.isEmpty ? nil : delen.joined(separator: " ")
    }
    private var telefoon: String? { pin.mapItem?.phoneNumber }
    private var website: URL?     { pin.mapItem?.url }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ── Header ──
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(pin.naam)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    if appShop != nil {
                        Label("In de Tattoe app", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.3, green: 0.9, blue: 0.5))
                    } else {
                        Text("Tattooshop · Nog niet in de app")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.45))
                    }
                }
                Spacer()
                Button(action: onSluit) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(white: 0.5))
                        .frame(width: 28, height: 28)
                        .background(Color(white: 0.22))
                        .clipShape(Circle())
                }
            }

            // ── Info regels ──
            VStack(alignment: .leading, spacing: 6) {
                if let adres {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin").frame(width: 14)
                        Text(adres)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.6))
                }
                if let tel = telefoon {
                    Button(action: {
                        if let url = URL(string: "tel://\(tel.filter { $0.isNumber || $0 == "+" })") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "phone").frame(width: 14)
                            Text(tel)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1))
                    }
                }
                if let url = website {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "globe").frame(width: 14)
                            Text(url.host ?? url.absoluteString)
                                .lineLimit(1)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1))
                    }
                }
                // Gevonden e-mailadres (als scraper iets vond)
                if let email = gevondenEmail {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope").frame(width: 14)
                        Text(email)
                            .lineLimit(1)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.6))
                } else if zoektEmail {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.65).tint(Color(white: 0.4))
                        Text("E-mailadres zoeken op website…")
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.35))
                    }
                }
            }

            // ── Knoppen ──
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    // Open in Apple Maps
                    Button(action: { pin.mapItem?.openInMaps(launchOptions: nil) }) {
                        HStack(spacing: 5) {
                            Image(systemName: "map")
                            Text("Route")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(height: 38)
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 0.18))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(white: 0.28), lineWidth: 1))
                    }

                    if let shop = appShop {
                        Button(action: { onSelecteer(shop) }) {
                            Text(isFavoriet ? "✓ MIJN SHOP" : "SELECTEER")
                                .font(.system(size: 12, weight: .black))
                                .tracking(1)
                                .foregroundColor(isFavoriet ? Color(white: 0.5) : .black)
                                .frame(height: 38)
                                .frame(maxWidth: .infinity)
                                .background(isFavoriet ? Color(white: 0.15) : Color.white)
                                .cornerRadius(6)
                        }
                        .disabled(isFavoriet)
                    }
                }

                // Afspraak-knop: altijd tonen voor niet-app shops
                if appShop == nil {
                    Button(action: {
                        if let email = gevondenEmail {
                            stuurAfspraakMail(naar: email)
                        }
                    }) {
                        HStack(spacing: 8) {
                            if zoektEmail {
                                ProgressView().tint(.black).scaleEffect(0.75)
                                Text("E-mail zoeken…")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(1)
                                    .foregroundColor(Color(white: 0.4))
                            } else if gevondenEmail != nil {
                                Image(systemName: "envelope.badge")
                                    .font(.system(size: 13))
                                Text("AFSPRAAK AANVRAGEN")
                                    .font(.system(size: 12, weight: .black))
                                    .tracking(1)
                            } else {
                                Image(systemName: "envelope")
                                    .font(.system(size: 13))
                                Text("GEEN E-MAIL GEVONDEN")
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(1)
                            }
                        }
                        .foregroundColor(gevondenEmail != nil ? .black : Color(white: 0.35))
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(gevondenEmail != nil ? Color.white : Color(white: 0.1))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(white: gevondenEmail != nil ? 0 : 0.2), lineWidth: gevondenEmail != nil ? 0 : 1)
                        )
                    }
                    .disabled(gevondenEmail == nil)
                    .animation(.easeInOut(duration: 0.25), value: gevondenEmail)
                    .animation(.easeInOut(duration: 0.25), value: zoektEmail)
                }
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            // Alleen voor niet-app shops: zoek email op hun website
            if appShop == nil, let url = website {
                Task { await zoekEmailOp(url: url) }
            }
        }
        .onChange(of: pin.id) { _, _ in
            gevondenEmail = nil
            if appShop == nil, let url = website {
                Task { await zoekEmailOp(url: url) }
            }
        }
    }

    @MainActor
    private func zoekEmailOp(url: URL) async {
        zoektEmail = true
        gevondenEmail = await emailUitWebsite(url)
        zoektEmail = false
    }

    private func emailUitWebsite(_ url: URL) async -> String? {
        // Voeg timeout toe zodat trage sites de UI niet blokkeren
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        let session = URLSession(configuration: config)

        guard let (data, _) = try? await session.data(from: url) else { return nil }
        let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""

        // Patroon 1: mailto: link (meest betrouwbaar)
        let mailtoPattern = #"mailto:([a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,})"#
        if let range = html.range(of: mailtoPattern, options: .regularExpression) {
            let found = String(html[range]).replacingOccurrences(of: "mailto:", with: "")
            if isGeldigEmail(found) { return found }
        }

        // Patroon 2: los e-mailadres in HTML tekst
        let emailPattern = #"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"#
        var zoekVanaf = html.startIndex
        while let range = html.range(of: emailPattern, options: .regularExpression, range: zoekVanaf..<html.endIndex) {
            let kandidaat = String(html[range])
            if isGeldigEmail(kandidaat) { return kandidaat }
            zoekVanaf = range.upperBound
        }
        return nil
    }

    private func isGeldigEmail(_ email: String) -> Bool {
        let laag = email.lowercased()
        let weiger = ["noreply", "no-reply", "donotreply", "sentry", "example",
                      "wixpress", "squarespace", "wordpress", "@2x", "@3x"]
        let ongeldigeSuffixen = [".png", ".jpg", ".gif", ".svg", ".webp", ".ico", ".js", ".css"]
        if weiger.contains(where: { laag.contains($0) }) { return false }
        if ongeldigeSuffixen.contains(where: { laag.hasSuffix($0) }) { return false }
        return laag.contains("@") && laag.contains(".")
    }

    private func stuurAfspraakMail(naar email: String) {
        let naam = pin.naam

        #if DEBUG
        let ontvanger = "edcafferata@icloud.com"
        let subj = "[DEV TEST] Afspraak aanvraag via Tattoe – \(naam) (eigenlijk naar: \(email))"
        #else
        let ontvanger = email
        let subj = "Afspraak aanvraag via Tattoe – \(naam)"
        #endif

        let body = wervingsTekst(shopNaam: naam)
        let encS = subj.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encB = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(ontvanger)?subject=\(encS)&body=\(encB)") {
            UIApplication.shared.open(url)
        }
    }

    private func wervingsTekst(shopNaam: String) -> String {
        """
        Hallo \(shopNaam),

        Ik wil graag een tattoo laten zetten en ik kwam jullie shop tegen via de Tattoe-app. \
        Zijn jullie beschikbaar voor een afspraak? Dan hoor ik graag de mogelijkheden!

        ──────────────────────────────
        🖋  Trouwens — zijn jullie al aangesloten bij Tattoe?

        Tattoe is dé Nederlandse app voor tattoo-klanten en artiesten. \
        Klanten vinden via de app tattooshops in hun buurt, bekijken portfolio's en plannen direct een afspraak. \
        En dat alles zonder social media of Google — gewoon één plek, speciaal voor de tattoo-wereld.

        Shops die zich aanmelden:
        ✅  Worden zichtbaar voor honderden klanten in de buurt
        ✅  Ontvangen afspraakaanvragen rechtstreeks in de app
        ✅  Krijgen een eigen profielpagina met foto's en artiesten
        ✅  Zijn als eerste zichtbaar — want we zijn nog in de beginfase

        👉  Download de app en meld je shop aan:
        https://apps.apple.com/nl/app/tattoe/id6741678835

        De eerste shops die instappen krijgen de meeste zichtbaarheid. \
        Wacht dus niet te lang — jullie klanten zoeken al.

        Met vriendelijke groet,
        Een Tattoe-gebruiker

        ──────────────────────────────
        Tattoe · dé app voor tattoo Nederland
        https://apps.apple.com/nl/app/tattoe/id6741678835
        """
    }
}

// MARK: - Artiest zoeker

struct KlantArtiesZoekerView: View {
    @EnvironmentObject var store: KlantStore
    @Environment(\.dismiss) private var dismiss

    @State private var artiesten: [ArtiestProfiel] = []
    @State private var zoekterm = ""
    @State private var laden = false

    private var gefilterd: [ArtiestProfiel] {
        zoekterm.isEmpty ? artiesten : artiesten.filter {
            $0.kunstnaam.localizedCaseInsensitiveContains(zoekterm) ||
            $0.specialisatie.localizedCaseInsensitiveContains(zoekterm) ||
            $0.woonplaats.localizedCaseInsensitiveContains(zoekterm)
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ARTIEST ZOEKEN")
                            .font(.system(size: 20, weight: .black))
                            .tracking(5)
                            .foregroundColor(.white)
                        if let shop = store.favorietShop {
                            Text("in \(shop.bedrijfsnaam)")
                                .font(.system(size: 11))
                                .tracking(1)
                                .foregroundColor(Color(white: 0.4))
                        }
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(white: 0.4))
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 16)

                // ── Zoek veld ──
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color(white: 0.4))
                        .font(.system(size: 13))
                    TextField("", text: $zoekterm)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .overlay(
                            Group {
                                if zoekterm.isEmpty {
                                    Text("ZOEK OP NAAM OF STIJL")
                                        .font(.system(size: 10))
                                        .tracking(2)
                                        .foregroundColor(Color(white: 0.3))
                                        .allowsHitTesting(false)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        )
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(white: 0.08))
                .overlay(Rectangle().stroke(Color(white: 0.15), lineWidth: 1))
                .padding(.horizontal, 24)

                Spacer().frame(height: 8)

                // ── Lijst ──
                if laden {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if gefilterd.isEmpty {
                    Spacer()
                    Text("Geen artiesten gevonden")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.3))
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 1) {
                            ForEach(gefilterd) { artiest in
                                Button(action: {
                                    store.slaFavorietArties(artiest)
                                    dismiss()
                                }) {
                                    HStack(spacing: 14) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(artiest.kunstnaam.isEmpty ? artiest.email : artiest.kunstnaam)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                            if !artiest.specialisatie.isEmpty {
                                                Text(artiest.specialisatie)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color(white: 0.5))
                                            }
                                            if !artiest.woonplaats.isEmpty {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "mappin")
                                                        .font(.system(size: 9))
                                                    Text(artiest.woonplaats)
                                                        .font(.system(size: 11))
                                                }
                                                .foregroundColor(Color(white: 0.35))
                                            }
                                            if !artiest.stijlen.isEmpty {
                                                Text(artiest.stijlen.prefix(3).joined(separator: " · "))
                                                    .font(.system(size: 10))
                                                    .foregroundColor(Color(white: 0.3))
                                            }
                                        }
                                        Spacer()
                                        if store.favorietArties?.email == artiest.email {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(store.favorietArties?.email == artiest.email ? Color(white: 0.1) : Color.clear)
                                }
                                Rectangle().fill(Color(white: 0.1)).frame(height: 1)
                                    .padding(.horizontal, 24)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
        }
        .task {
            laden = true
            if let shop = store.favorietShop {
                artiesten = await CloudKitManager.shared.fetchArtiesten(voorShop: shop.email)
            } else {
                artiesten = await CloudKitManager.shared.fetchPubliekeArtiesten()
            }
            laden = false
        }
    }
}

// MARK: - Afspraak aanvragen

enum AfspraakType { case shop, artiest }

struct KlantAfspraakAanvraagView: View {
    let naam:  String
    let email: String
    let type:  AfspraakType
    @EnvironmentObject var store: KlantStore
    @Environment(\.dismiss) private var dismiss

    @State private var geselecteerdeDatum = Date().addingTimeInterval(86400)
    @State private var notitie           = ""
    @State private var verstuurd         = false

    private var typeLabel: String { type == .shop ? "SHOP" : "ARTIEST" }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Header ──
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("AFSPRAAK AANVRAGEN")
                            .font(.system(size: 18, weight: .black))
                            .tracking(4)
                            .foregroundColor(.white)
                        Text("\(typeLabel) · \(naam)")
                            .font(.system(size: 12))
                            .tracking(1)
                            .foregroundColor(Color(white: 0.4))
                    }
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(white: 0.4))
                            .frame(width: 34, height: 34)
                            .background(Color(white: 0.12))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 28)

                if verstuurd {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 0.3, green: 0.85, blue: 0.5))
                        Text("AANVRAAG VERSTUURD")
                            .font(.system(size: 16, weight: .black))
                            .tracking(4)
                            .foregroundColor(.white)
                        Text("Je ontvangt een bevestiging zodra\nde agenda beschikbaar is.")
                            .font(.system(size: 12))
                            .tracking(0.5)
                            .foregroundColor(Color(white: 0.4))
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Datum
                            sectionLabel("GEWENSTE DATUM")
                            DatePicker("",
                                       selection: $geselecteerdeDatum,
                                       in: Date()...,
                                       displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                                .tint(.white)
                                .colorScheme(.dark)
                                .padding(.horizontal, 16)
                                .background(Color(white: 0.07))
                                .cornerRadius(10)
                                .padding(.horizontal, 24)

                            Spacer().frame(height: 24)

                            // Notitie
                            sectionLabel("OPMERKING (OPTIONEEL)")
                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $notitie)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                    .tint(.white)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .frame(minHeight: 80)
                                    .padding(12)
                                if notitie.isEmpty {
                                    Text("Beschrijf je wens, stijl of vraag…")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(white: 0.3))
                                        .padding(.horizontal, 16)
                                        .padding(.top, 20)
                                        .allowsHitTesting(false)
                                }
                            }
                            .background(Color(white: 0.07))
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.14), lineWidth: 1))
                            .padding(.horizontal, 24)

                            Spacer().frame(height: 100)
                        }
                    }
                }

                // ── Stuur knop ──
                if !verstuurd {
                    Button(action: stuurAanvraag) {
                        Text("STUUR AANVRAAG")
                            .font(.system(size: 14, weight: .black))
                            .tracking(3)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .tracking(4)
            .foregroundColor(Color(white: 0.35))
            .padding(.horizontal, 28)
            .padding(.bottom, 8)
    }

    private func stuurAanvraag() {
        withAnimation { verstuurd = true }
        let naam   = (store.klant.map { "\($0.voornaam) \($0.achternaam)".trimmingCharacters(in: .whitespaces) }) ?? ""
        let kEmail = store.klant?.email ?? ""
        let shopEm = (type == .artiest ? store.favorietShop?.email : nil) ?? ""
        let artEm  = type == .artiest ? email : ""
        let shopEm2 = type == .shop ? email : shopEm
        let a = Afspraak(id: UUID().uuidString,
                         artiesEmail: artEm,
                         shopEmail:   shopEm2,
                         klantEmail:  kEmail,
                         klantNaam:   naam,
                         datum:       geselecteerdeDatum,
                         notitie:     notitie,
                         status:      "aangevraagd")
        Task {
            await CloudKitManager.shared.saveAfspraak(a)
            let df = DateFormatter()
            df.locale = Locale(identifier: "nl_NL"); df.dateFormat = "d MMM · HH:mm"
            let tekst = "\(naam.isEmpty ? kEmail : naam) heeft een afspraak aangevraagd op \(df.string(from: a.datum))."
            if !artEm.isEmpty {
                let b = Bericht(ontvangerEmail: artEm, ontvangerRol: "arties",
                                type: "aangevraagd", tekst: tekst, afspraakId: a.id, datum: Date())
                await CloudKitManager.shared.saveBericht(b)
            }
            if !shopEm2.isEmpty {
                let b = Bericht(ontvangerEmail: shopEm2, ontvangerRol: "shop",
                                type: "aangevraagd", tekst: tekst, afspraakId: a.id, datum: Date())
                await CloudKitManager.shared.saveBericht(b)
            }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()
        }
    }
}

// MARK: - Klant Berichten

struct KlantBerichtenView: View {
    @EnvironmentObject var store: KlantStore
    @Environment(\.dismiss) private var dismiss
    @State private var bezig: Set<String> = []

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
                                berichtRij(b)
                                    .onAppear { store.markeerGelezen(b.id) }
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
        let ongelezen = !store.berichten.filter { $0.id == b.id }.isEmpty
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconNaam(b.type))
                    .font(.system(size: 13))
                    .foregroundColor(kleurVoor(b.type))
                Text(titeltje(b.type))
                    .font(.system(size: 10, weight: .bold)).tracking(2)
                    .foregroundColor(kleurVoor(b.type))
                Spacer()
                Text(df.string(from: b.datum))
                    .font(.system(size: 10)).foregroundColor(Color(white: 0.35))
            }
            Text(b.tekst)
                .font(.system(size: 13)).foregroundColor(Color(white: 0.8))
                .fixedSize(horizontal: false, vertical: true)

            if b.type == "wacht_klant" {
                HStack(spacing: 10) {
                    if bezig.contains(b.id) {
                        ProgressView().tint(.white)
                    } else {
                        Button(action: { bevestig(b) }) {
                            Text("BEVESTIGEN")
                                .font(.system(size: 11, weight: .bold)).tracking(2)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity).frame(height: 36)
                                .background(Color.white).cornerRadius(5)
                        }
                        Button(action: { annuleer(b) }) {
                            Text("ANNULEREN")
                                .font(.system(size: 11, weight: .bold)).tracking(2)
                                .foregroundColor(Color(white: 0.5))
                                .frame(maxWidth: .infinity).frame(height: 36)
                                .background(Color(white: 0.1)).cornerRadius(5)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color(white: 0.2), lineWidth: 1))
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(white: 0.07))
        .overlay(Rectangle().stroke(Color(white: 0.1), lineWidth: 1))
    }

    private func bevestig(_ b: Bericht) {
        bezig.insert(b.id)
        Task {
            await store.bevestigAfspraak(b.afspraakId)
            bezig.remove(b.id)
        }
    }

    private func annuleer(_ b: Bericht) {
        Task {
            await CloudKitManager.shared.updateAfspraakStatus(id: b.afspraakId, nieuwStatus: "geweigerd")
            store.berichten.removeAll { $0.id == b.id }
        }
    }

    private func titeltje(_ type: String) -> String {
        switch type {
        case "aangevraagd": "AANVRAAG VERSTUURD"
        case "wacht_klant": "BEVESTIGING NODIG"
        case "bevestigd":   "BEVESTIGD"
        case "geweigerd":   "NIET BESCHIKBAAR"
        default:            type.uppercased()
        }
    }

    private func kleurVoor(_ type: String) -> Color {
        switch type {
        case "wacht_klant": .orange
        case "bevestigd":   Color(white: 0.7)
        case "geweigerd":   Color(red: 0.9, green: 0.3, blue: 0.3)
        default:            Color(white: 0.5)
        }
    }

    private func iconNaam(_ type: String) -> String {
        switch type {
        case "wacht_klant": "bell.badge"
        case "bevestigd":   "checkmark.circle"
        case "geweigerd":   "xmark.circle"
        default:            "calendar"
        }
    }
}
