import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let shareText = """
Tattoe — De app voor tattoo liefhebbers, artiesten en shops.

🎨 ARTIEST
Beheer je afspraken, portfolio en klantcontact — alles op één plek.

💉 KLANT
Vind de perfecte tattoo artiest bij jou in de buurt en boek direct.

🏪 SHOP
Presenteer je studio professioneel en bereik nieuwe klanten.

Download Tattoe:
https://apps.apple.com/app/tattoe
"""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Canvas { context, size in
                for _ in 0..<1500 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    let opacity = Double.random(in: 0.02...0.05)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1.5, height: 1.5)),
                        with: .color(.white.opacity(opacity))
                    )
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 0) {
                        Spacer().frame(height: 56)

                        Image("TattoeLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 20))

                        Spacer().frame(height: 16)

                        Text("TATTOE")
                            .font(.system(size: 30, weight: .black))
                            .tracking(10)
                            .foregroundColor(.white)

                        Spacer().frame(height: 6)

                        Text("EST. 2026")
                            .font(.system(size: 10, weight: .medium))
                            .tracking(4)
                            .foregroundColor(Color(white: 0.3))

                        Spacer().frame(height: 32)

                        Text("Jouw platform voor tattoo kunst — waar artiest, klant en studio samenkomen.")
                            .font(.system(size: 14, weight: .regular))
                            .tracking(0.5)
                            .foregroundColor(Color(white: 0.55))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)

                        Spacer().frame(height: 40)
                    }

                    // Divider
                    DiamondDivider()
                        .padding(.horizontal, 32)

                    Spacer().frame(height: 40)

                    // Roles
                    VStack(spacing: 28) {
                        AboutRolKaart(
                            icon: "paintbrush.pointed.fill",
                            titel: "ARTIEST",
                            subtitel: "Voor tattoo artiesten",
                            tekst: "Presenteer je werk aan duizenden liefhebbers. Beheer al je afspraken, klantberichten en portfolio in één overzichtelijke app — zodat jij je kunt focussen op waar je goed in bent: kunst."
                        )

                        AboutRolKaart(
                            icon: "heart.fill",
                            titel: "KLANT",
                            subtitel: "Voor tattoo liefhebbers",
                            tekst: "Vind de perfecte artiest bij jou in de buurt. Blader door stijlen, bekijk portfolio's en plan je afspraak direct. Van eerste idee tot permanente herinnering — Tattoe begeleidt je door het hele proces."
                        )

                        AboutRolKaart(
                            icon: "storefront.fill",
                            titel: "SHOP",
                            subtitel: "Voor tattoo studios",
                            tekst: "Zet je studio op de kaart — letterlijk. Beheer je artiesten, voorraad en klantafspraken professioneel. Bereik nieuwe klanten in jouw regio en bouw een sterke digitale aanwezigheid op."
                        )
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 40)

                    // Divider
                    DiamondDivider()
                        .padding(.horizontal, 32)

                    Spacer().frame(height: 36)

                    // Tagline
                    Text("INKT VERBINDT")
                        .font(.system(size: 13, weight: .black))
                        .tracking(6)
                        .foregroundColor(Color(white: 0.25))

                    Spacer().frame(height: 36)

                    // Share button
                    ShareLink(item: shareText) {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("DEEL TATTOE")
                                .font(.system(size: 14, weight: .black))
                                .tracking(3)
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)

                    // Credits
                    VStack(spacing: 10) {
                        Text("GEMAAKT DOOR")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(4)
                            .foregroundColor(Color(white: 0.22))

                        VStack(spacing: 4) {
                            Text("Ed Cafferata")
                                .font(.system(size: 13, weight: .black))
                                .tracking(2)
                                .foregroundColor(Color(white: 0.4))
                            Text("Eigenaar · App, software & sites")
                                .font(.system(size: 10))
                                .tracking(1)
                                .foregroundColor(Color(white: 0.25))
                        }

                        VStack(spacing: 4) {
                            Text("Tarek")
                                .font(.system(size: 13, weight: .black))
                                .tracking(2)
                                .foregroundColor(Color(white: 0.4))
                            Text("Mede-ontwikkelaar")
                                .font(.system(size: 10))
                                .tracking(1)
                                .foregroundColor(Color(white: 0.25))
                        }

                        Spacer().frame(height: 4)

                        Text("ONDERSTEUND DOOR")
                            .font(.system(size: 9, weight: .semibold))
                            .tracking(4)
                            .foregroundColor(Color(white: 0.22))

                        Text("The IT Crowd")
                            .font(.system(size: 13, weight: .black))
                            .tracking(2)
                            .foregroundColor(Color(white: 0.4))
                    }
                    .multilineTextAlignment(.center)

                    Spacer().frame(height: 20)

                    Text("© 2026 Tattoe")
                        .font(.system(size: 10))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.2))

                    Spacer().frame(height: 48)
                }
            }

            // Sluit knop
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(white: 0.5))
                            .frame(width: 36, height: 36)
                            .background(Color(white: 0.12))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
    }
}

private struct AboutRolKaart: View {
    let icon: String
    let titel: String
    let subtitel: String
    let tekst: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(Color(white: 0.7))
                .frame(width: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(titel)
                        .font(.system(size: 16, weight: .black))
                        .tracking(3)
                        .foregroundColor(.white)
                    Text(subtitel)
                        .font(.system(size: 10, weight: .medium))
                        .tracking(2)
                        .foregroundColor(Color(white: 0.35))
                }
                Text(tekst)
                    .font(.system(size: 13, weight: .regular))
                    .tracking(0.3)
                    .foregroundColor(Color(white: 0.5))
                    .lineSpacing(4)
            }
        }
        .padding(20)
        .overlay(
            Rectangle()
                .stroke(Color(white: 0.14), lineWidth: 1)
        )
    }
}

#Preview {
    AboutView()
}
