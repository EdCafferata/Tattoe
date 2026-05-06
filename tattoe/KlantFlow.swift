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

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let cred = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            Task {
                // Eerst CloudKit checken — bestaand account terugzetten
                await store.checkCloud(appleUserID: cred.user)

                // Alleen nieuw aanmaken als er niets in CloudKit stond
                if !store.isLoggedIn {
                    let klant = Klant(
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
                    )
                    store.save(klant)
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

struct KlantEmailLoginView: View {
    @EnvironmentObject var store: KlantStore
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

                    Spacer().frame(height: 36)

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

// MARK: - Dashboard

struct KlantDashboardView: View {
    @EnvironmentObject var store: KlantStore
    let onLogout: () -> Void

    @State private var showBewerken   = false
    @State private var shopArtiesten: [ArtiestProfiel] = []
    @State private var laden          = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                Text("WELKOM TERUG")
                    .font(.system(size: 28, weight: .black))
                    .tracking(6)
                    .foregroundColor(.white)
                Spacer().frame(height: 8)
                if let k = store.klant {
                    Text("\(k.voornaam) \(k.achternaam)")
                        .font(.system(size: 14))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.45))
                }

                Spacer().frame(height: 40)

                // Favoriet shop + gekoppelde artiesten
                if let shop = store.favorietShop {
                    VStack(spacing: 8) {
                        Text("JOUW SHOP")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(4)
                            .foregroundColor(Color(white: 0.35))

                        Text(shop.bedrijfsnaam)
                            .font(.system(size: 15, weight: .semibold))
                            .tracking(1)
                            .foregroundColor(.white)

                        Text(shop.woonplaats)
                            .font(.system(size: 11))
                            .foregroundColor(Color(white: 0.4))
                    }
                    .padding(.horizontal, 40)

                    if !shopArtiesten.isEmpty {
                        Spacer().frame(height: 20)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("ARTIESTEN")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(4)
                                .foregroundColor(Color(white: 0.35))
                                .padding(.horizontal, 40)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(shopArtiesten) { artiest in
                                        VStack(spacing: 4) {
                                            Text(artiest.kunstnaam.isEmpty ? artiest.email : artiest.kunstnaam)
                                                .font(.system(size: 12, weight: .medium))
                                                .foregroundColor(.white)
                                                .lineLimit(1)
                                            if !artiest.specialisatie.isEmpty {
                                                Text(artiest.specialisatie)
                                                    .font(.system(size: 10))
                                                    .foregroundColor(Color(white: 0.4))
                                                    .lineLimit(1)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color(white: 0.09))
                                        .cornerRadius(6)
                                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(white: 0.15), lineWidth: 1))
                                    }
                                }
                                .padding(.horizontal, 40)
                            }
                        }
                    } else if laden {
                        Spacer().frame(height: 12)
                        ProgressView().tint(.white).scaleEffect(0.8)
                    }
                } else {
                    Text("Hier komt het klant scherm")
                        .font(.system(size: 12))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.3))
                }

                Spacer()

                // AANPASSEN + UITLOGGEN naast elkaar
                HStack(spacing: 12) {
                    Button(action: { showBewerken = true }) {
                        Text("AANPASSEN")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(white: 0.12))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(white: 0.25), lineWidth: 1)
                            )
                    }

                    Button(action: { store.logout(); onLogout() }) {
                        Text("UITLOGGEN")
                            .font(.system(size: 12, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color(white: 0.12))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(white: 0.25), lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .task {
            if let shop = store.favorietShop {
                laden = true
                shopArtiesten = await CloudKitManager.shared.fetchArtiesten(voorShop: shop.email)
                laden = false
            }
        }
        .fullScreenCover(isPresented: $showBewerken) {
            KlantNAWView(onLogout: onLogout)
                .environmentObject(store)
        }
    }
}
