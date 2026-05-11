import SwiftUI
import PassKit

// MARK: - Aanbetaling sheet

struct AanbetalingView: View {
    let afspraak: Afspraak
    let onSuccess: () async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var bezig   = false
    @State private var gelukt  = false
    @State private var fout: String?

    static let bedrag: Decimal = 9.90

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if gelukt { successView } else { contentView }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Gelukt scherm

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundColor(.white)
            Text("BETALING GESLAAGD")
                .font(.system(size: 18, weight: .black)).tracking(4)
                .foregroundColor(.white)
            Text("Aanbetaling van €9,90 ontvangen.\nJe afspraak is definitief bevestigd.")
                .font(.system(size: 14)).foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center)
            Spacer()
            Button(action: { dismiss() }) {
                Text("SLUITEN")
                    .font(.system(size: 13, weight: .bold)).tracking(3)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.white).cornerRadius(8)
            }
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
    }

    // MARK: - Betaalscherm

    private var contentView: some View {
        VStack(spacing: 0) {
            // Sluitknop
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(white: 0.45))
                }
                Spacer()
            }
            .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 4)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // Bedrag
                    VStack(spacing: 6) {
                        Text("AANBETALING")
                            .font(.system(size: 10, weight: .bold)).tracking(3)
                            .foregroundColor(Color(white: 0.35))
                        Text("€ 9,90")
                            .font(.system(size: 56, weight: .black))
                            .foregroundColor(.white)
                        Text("Verrekend met je totale tattoopijs")
                            .font(.system(size: 12)).foregroundColor(Color(white: 0.35))
                    }
                    .padding(.top, 8)

                    // Afspraak samenvatting
                    afspraakKaart

                    // Betaalknoppen
                    VStack(spacing: 10) {
                        // Apple Pay
                        if PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .maestro]) {
                            ApplePayKnop(bedrag: Self.bedrag) { success in
                                if success { await bevestig() }
                                else { fout = "Betaling niet geslaagd. Probeer opnieuw." }
                            }
                            .frame(height: 50)
                            .cornerRadius(8)
                        }

                        // iDEAL
                        betaalKnop(icon: "building.columns.fill", label: "Betaal met iDEAL", actie: betaalIDeal)

                        // Kaart
                        betaalKnop(icon: "creditcard.fill", label: "Creditcard / Debitcard", actie: betaalKaart)

                        #if DEBUG
                        Button(action: { Task { await bevestig() } }) {
                            Text("DEV: Simuleer geslaagde betaling")
                                .font(.system(size: 11)).foregroundColor(Color(white: 0.25))
                        }
                        .padding(.top, 4)
                        #endif
                    }
                    .padding(.horizontal, 24)

                    if let fout {
                        Text(fout)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.9, green: 0.3, blue: 0.3))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    VStack(spacing: 4) {
                        Label("256-bit beveiligde verbinding", systemImage: "lock.fill")
                            .font(.system(size: 11)).foregroundColor(Color(white: 0.25))
                        Text("De aanbetaling wordt verrekend bij je bezoek.")
                            .font(.system(size: 11)).foregroundColor(Color(white: 0.25))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Afspraak kaart

    private var afspraakKaart: some View {
        let df = DateFormatter()
        df.locale = Locale(identifier: "nl_NL")
        df.dateFormat = "EEEE d MMMM yyyy 'om' HH:mm"

        return VStack(alignment: .leading, spacing: 10) {
            Text("AFSPRAAK")
                .font(.system(size: 9, weight: .bold)).tracking(2)
                .foregroundColor(Color(white: 0.35))

            Text(df.string(from: afspraak.datum).capitalized)
                .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)

            if !afspraak.artiesEmail.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "paintbrush").font(.system(size: 11))
                        .foregroundColor(Color(white: 0.35))
                    Text(afspraak.artiesEmail).font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))
                }
            }
            if !afspraak.shopEmail.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin").font(.system(size: 11))
                        .foregroundColor(Color(white: 0.35))
                    Text(afspraak.shopEmail).font(.system(size: 12))
                        .foregroundColor(Color(white: 0.5))
                }
            }
            if !afspraak.notitie.isEmpty {
                Text(afspraak.notitie)
                    .font(.system(size: 12)).foregroundColor(Color(white: 0.45))
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(white: 0.07))
        .overlay(Rectangle().stroke(Color(white: 0.12), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // MARK: - Herbruikbare betaalknop

    @ViewBuilder
    private func betaalKnop(icon: String, label: String, actie: @escaping () -> Void) -> some View {
        Button(action: actie) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 15))
                Text(label).font(.system(size: 14, weight: .semibold))
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12))
                    .foregroundColor(Color(white: 0.3))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity).frame(height: 50)
            .padding(.horizontal, 16)
            .background(Color(white: 0.1))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(white: 0.18), lineWidth: 1))
        }
    }

    // MARK: - Acties

    private func bevestig() async {
        bezig = true
        fout = nil
        await onSuccess()
        withAnimation(.easeInOut(duration: 0.4)) { gelukt = true }
        bezig = false
    }

    private func betaalIDeal() {
        // Integreer Mollie of Stripe iDEAL:
        // 1. Maak een payment intent aan op je backend
        // 2. Open de Mollie checkout URL in Safari
        // 3. Verwerk de return via deep link (tattoe://betaling-geslaagd?afspraakId=...)
        fout = "iDEAL betaling binnenkort beschikbaar."
    }

    private func betaalKaart() {
        // Integreer Stripe PaymentSheet voor kaartbetalingen:
        // 1. Maak PaymentIntent aan op backend
        // 2. Initialiseer Stripe PaymentSheet met clientSecret
        // 3. Presenteer sheet, verwerk resultaat
        fout = "Kaartbetaling binnenkort beschikbaar."
    }
}

// MARK: - Apple Pay knop (PassKit wrapper)

struct ApplePayKnop: View {
    let bedrag: Decimal
    let onResult: (Bool) async -> Void

    var body: some View {
        ApplePayKnopRepresentable(bedrag: bedrag, onResult: onResult)
    }
}

private struct ApplePayKnopRepresentable: UIViewRepresentable {
    let bedrag: Decimal
    let onResult: (Bool) async -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let btn = PKPaymentButton(paymentButtonType: .plain, paymentButtonStyle: .white)
        btn.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        btn.cornerRadius = 8
        return btn
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(bedrag: bedrag, onResult: onResult)
    }

    final class Coordinator: NSObject, PKPaymentAuthorizationControllerDelegate {
        let bedrag: Decimal
        let onResult: (Bool) async -> Void

        init(bedrag: Decimal, onResult: @escaping (Bool) async -> Void) {
            self.bedrag = bedrag
            self.onResult = onResult
        }

        @objc func tapped() {
            let req = PKPaymentRequest()
            // Registreer merchant.info.cafferata.tattoe in Xcode Signing & Capabilities → Apple Pay
            req.merchantIdentifier  = "merchant.info.cafferata.tattoe"
            req.supportedNetworks   = [.visa, .masterCard, .maestro, .amex]
            req.merchantCapabilities = .threeDSecure
            req.countryCode         = "NL"
            req.currencyCode        = "EUR"
            req.paymentSummaryItems = [
                PKPaymentSummaryItem(
                    label:  "Tattoe – aanbetaling",
                    amount: NSDecimalNumber(decimal: bedrag)
                )
            ]

            let ctrl = PKPaymentAuthorizationController(paymentRequest: req)
            ctrl.delegate = self
            ctrl.present()
        }

        func paymentAuthorizationController(
            _ controller: PKPaymentAuthorizationController,
            didAuthorizePayment payment: PKPayment,
            handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
        ) {
            // Stuur payment.token.paymentData naar je backend (Stripe/Mollie) voor verwerking.
            // Hier simuleren we succes zodat de flow werkt zonder backend.
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            Task { await onResult(true) }
        }

        func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
            controller.dismiss()
        }
    }
}
