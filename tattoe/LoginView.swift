import SwiftUI
import UIKit

enum UserRole {
    case arties
    case klant
    case shop
}

struct LoginView: View {
    @Binding var selectedRole: UserRole?
    @State private var showAbout = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Subtle grain overlay
            Canvas { context, size in
                for _ in 0..<2000 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let opacity = Double.random(in: 0.02...0.06)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                // Logo — tik voor About
                Button(action: { showAbout = true }) {
                    Image("TattoeLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showAbout) { AboutView() }

                Spacer().frame(height: 16)

                Text("TATTOE")
                    .font(.system(size: 38, weight: .black))
                    .tracking(10)
                    .foregroundColor(.white)

                Spacer().frame(height: 48)

                Text("KIES JE PROFIEL")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(4)
                    .foregroundColor(Color(white: 0.4))

                Spacer().frame(height: 28)

                // User buttons
                VStack(spacing: 12) {
                    InkButton(label: "ARTIEST", sub: "Tattoo artiest") {
                        selectedRole = .arties
                    }
                    InkButton(label: "KLANT", sub: "Ik wil een tattoo") {
                        selectedRole = .klant
                    }
                    InkButton(label: "SHOP", sub: "Studio beheer") {
                        selectedRole = .shop
                    }
                }
                .padding(.horizontal, 32)

                Spacer()

                Text("EST. 2026")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(4)
                    .foregroundColor(Color(white: 0.25))
                    .padding(.bottom, 32)
            }
        }
    }
}

// Decorative top/bottom border like old tattoo flash sheets
struct FlashBorder: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                // Top line
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(white: 0.25))
                    .frame(maxHeight: .infinity, alignment: .top)
                // Bottom line
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(white: 0.25))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                // Corner marks
                HStack {
                    CornerMark()
                    Spacer()
                    CornerMark().scaleEffect(x: -1)
                }
            }
        }
    }
}

struct CornerMark: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().frame(width: 12, height: 1).foregroundColor(Color(white: 0.3))
            Rectangle().frame(width: 1, height: 12).foregroundColor(Color(white: 0.3))
        }
    }
}

struct DiamondDivider: View {
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(white: 0.2))
            Spacer().frame(width: 12)
            Rectangle()
                .frame(width: 8, height: 8)
                .foregroundColor(Color(white: 0.35))
                .rotationEffect(.degrees(45))
            Spacer().frame(width: 12)
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(white: 0.2))
        }
    }
}

struct InkButton: View {
    let label: String
    let sub: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.system(size: 22, weight: .black))
                        .tracking(4)
                        .foregroundColor(.white)
                    Text(sub)
                        .font(.system(size: 11, weight: .regular))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.45))
                }
                Spacer()
                // Arrow
                HStack(spacing: 4) {
                    Rectangle().frame(width: 20, height: 1).foregroundColor(Color(white: 0.4))
                    Image(systemName: "arrowtriangle.right.fill")
                        .font(.system(size: 8))
                        .foregroundColor(Color(white: 0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .overlay(
                Rectangle()
                    .stroke(Color(white: 0.2), lineWidth: 1)
            )
        }
        .buttonStyle(InkButtonStyle())
        .accessibilityIdentifier("btn_\(label.lowercased())")
    }
}

struct InkButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(white: 0.1) : Color.black)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Wachtwoord reset (gedeeld voor alle drie rollen)

struct WachtwoordResetView: View {
    let rol: CloudKitManager.ResetRolType
    @Environment(\.dismiss) private var dismiss

    enum Stap { case email, code }

    @State private var stap:              Stap   = .email
    @State private var emailInvoer:       String = ""
    @State private var codeInvoer:        String = ""
    @State private var nieuwWachtwoord:   String = ""
    @State private var bevestig:          String = ""
    @State private var fout:              String?
    @State private var bezig:             Bool   = false
    @State private var geslaagd:          Bool   = false
    @FocusState private var focus:        Veld?

    enum Veld: Hashable { case email, code, wachtwoord, bevestig }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("WACHTWOORD VERGETEN")
                    .font(.system(size: 22, weight: .black))
                    .tracking(4)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 8)

                Text(stap == .email
                     ? "Voer je e-mailadres in. Je ontvangt een 6-cijferige resetcode via de Mail-app."
                     : "Voer de code in die je zojuist via mail hebt ontvangen, en kies een nieuw wachtwoord.")
                    .font(.system(size: 12))
                    .tracking(0.5)
                    .foregroundColor(Color(white: 0.4))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 36)

                if stap == .email {
                    VStack(spacing: 1) {
                        InkField("E-MAILADRES", text: $emailInvoer, type: .emailAddress, keyboard: .emailAddress)
                            .focused($focus, equals: .email)
                            .submitLabel(.done)
                            .onSubmit { verstuurCode() }
                    }
                    .padding(.horizontal, 24)
                } else if geslaagd {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(white: 0.7))
                        Text("Wachtwoord ingesteld!")
                            .font(.system(size: 14, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(.white)
                        Text("Je kunt nu inloggen met je nieuwe wachtwoord.")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.4))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    VStack(spacing: 1) {
                        InkField("RESETCODE (6 CIJFERS)", text: $codeInvoer, keyboard: .numberPad)
                            .focused($focus, equals: .code)
                        InkField("NIEUW WACHTWOORD", text: $nieuwWachtwoord, secure: true)
                            .focused($focus, equals: .wachtwoord)
                            .submitLabel(.next)
                            .onSubmit { focus = .bevestig }
                        InkField("BEVESTIG WACHTWOORD", text: $bevestig, secure: true)
                            .focused($focus, equals: .bevestig)
                            .submitLabel(.done)
                            .onSubmit { stelIn() }
                    }
                    .padding(.horizontal, 24)
                }

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

            // Actie knop onderaan
            VStack(spacing: 0) {
                Spacer()
                if geslaagd {
                    Button(action: { dismiss() }) {
                        Text("TERUG NAAR INLOGGEN")
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
                } else {
                    Button(action: stap == .email ? verstuurCode : stelIn) {
                        Group {
                            if bezig {
                                ProgressView().tint(.black)
                            } else {
                                Text(stap == .email ? "STUUR RESETCODE" : "WACHTWOORD INSTELLEN")
                                    .font(.system(size: 14, weight: .black))
                                    .tracking(3)
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
            }

            // TERUG knop
            Button(action: {
                if stap == .code && !geslaagd { stap = .email; fout = nil }
                else { dismiss() }
            }) {
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

    private func verstuurCode() {
        fout = nil; focus = nil
        let trimmed = emailInvoer.trimmingCharacters(in: .whitespaces).lowercased()
        guard trimmed.contains("@") else { fout = "Voer een geldig e-mailadres in."; return }
        bezig = true
        let code = String(format: "%06d", Int.random(in: 0..<1_000_000))
        Task {
            let gelukt = await CloudKitManager.shared.slaResetCodeOp(rol: rol, email: trimmed, code: code)
            await MainActor.run {
                bezig = false
                if gelukt {
                    openMailApp(email: trimmed, code: code)
                    stap = .code
                } else {
                    fout = "Geen account gevonden met dit e-mailadres."
                }
            }
        }
    }

    private func stelIn() {
        fout = nil; focus = nil
        guard codeInvoer.count == 6 else { fout = "Voer de 6-cijferige code in."; return }
        guard nieuwWachtwoord.count >= 8 else { fout = "Wachtwoord moet minimaal 8 tekens zijn."; return }
        guard nieuwWachtwoord == bevestig else { fout = "Wachtwoorden komen niet overeen."; return }
        bezig = true
        let trimmed = emailInvoer.trimmingCharacters(in: .whitespaces).lowercased()
        Task {
            let err = await CloudKitManager.shared.resetWachtwoord(
                rol: rol, email: trimmed, code: codeInvoer, nieuwWachtwoord: nieuwWachtwoord)
            await MainActor.run {
                bezig = false
                if let err { fout = err } else { geslaagd = true }
            }
        }
    }

    private func openMailApp(email: String, code: String) {
        let subject = "Tattoe – je resetcode"
        let body    = "Je resetcode is: \(code)\n\nDeze code is 15 minuten geldig.\nVoer hem in de Tattoe-app in om je wachtwoord opnieuw in te stellen."
        let s = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let b = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(email)?subject=\(s)&body=\(b)") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    LoginView(selectedRole: .constant(nil))
}
