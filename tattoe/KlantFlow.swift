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
                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleResult(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    // Email registratie
                    Button(action: { showEmailRegister = true }) {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                            Text("Registreren met e-mail")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        case .failure(let err):
            if (err as NSError).code != ASAuthorizationError.canceled.rawValue {
                error = "Aanmelden mislukt. Probeer opnieuw."
            }
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

                    Spacer().frame(height: 32)

                    Button(action: registreer) {
                        HStack {
                            Spacer()
                            Text("ACCOUNT AANMAKEN")
                                .font(.system(size: 14, weight: .black))
                                .tracking(4)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(height: 54)
                        .background(Color.white)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    Button(action: { dismiss() }) {
                        Text("ANNULEREN")
                            .font(.system(size: 11))
                            .tracking(3)
                            .foregroundColor(Color(white: 0.3))
                    }

                    Spacer().frame(height: 40)
                }
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
        ZStack {
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

                    Spacer().frame(height: 32)

                    Button(action: opslaan) {
                        HStack {
                            Spacer()
                            Text("OPSLAAN")
                                .font(.system(size: 14, weight: .black))
                                .tracking(5)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .frame(height: 54)
                        .background(Color.white)
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)

                    Button(action: { store.logout(); onLogout() }) {
                        Text("UITLOGGEN")
                            .font(.system(size: 11))
                            .tracking(3)
                            .foregroundColor(Color(white: 0.3))
                    }

                    Spacer().frame(height: 40)
                }
            }
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
        var k = store.klant ?? Klant(authMethod: .apple, appleUserID: "", voornaam: "", achternaam: "", email: "", wachtwoord: "", telefoon: "", straat: "", huisnummer: "", postcode: "", woonplaats: "")
        k.voornaam   = voornaam
        k.achternaam = achternaam
        k.email      = email
        k.telefoon   = telefoon
        k.straat     = straat
        k.huisnummer = huisnummer
        k.postcode   = postcode
        k.woonplaats = woonplaats
        store.save(k)
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

// MARK: - Dashboard

struct KlantDashboardView: View {
    @EnvironmentObject var store: KlantStore
    let onLogout: () -> Void

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
                Spacer().frame(height: 60)
                Text("Hier komt het klant scherm")
                    .font(.system(size: 12))
                    .tracking(2)
                    .foregroundColor(Color(white: 0.3))
                Spacer()
                Button(action: { store.logout(); onLogout() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrowtriangle.left.fill").font(.system(size: 8))
                        Text("UITLOGGEN").font(.system(size: 11, weight: .semibold)).tracking(3)
                    }
                    .foregroundColor(Color(white: 0.35))
                }
                .padding(.bottom, 40)
            }
        }
    }
}
