import SwiftUI

struct AandachtBanner: View {
    let berichten:  Int
    let afspraken:  Int
    let onBerichten:  () -> Void
    let onAfspraken:  () -> Void

    private var totaal: Int { berichten + afspraken }

    var body: some View {
        if totaal > 0 {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.black)
                        .padding(.leading, 14)
                    Spacer().frame(width: 10)
                    HStack(spacing: 16) {
                        if afspraken > 0 {
                            Button(action: onAfspraken) {
                                HStack(spacing: 5) {
                                    Text("\(afspraken)")
                                        .font(.system(size: 11, weight: .black))
                                    Text(afspraken == 1 ? "afspraak wacht op jou" : "afspraken wachten op jou")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.black)
                            }
                            .buttonStyle(.plain)
                        }
                        if afspraken > 0 && berichten > 0 {
                            Text("·").font(.system(size: 11)).foregroundColor(Color(white: 0.3))
                        }
                        if berichten > 0 {
                            Button(action: onBerichten) {
                                HStack(spacing: 5) {
                                    Text("\(berichten)")
                                        .font(.system(size: 11, weight: .black))
                                    Text(berichten == 1 ? "ongelezen bericht" : "ongelezen berichten")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundColor(.black)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(Color.white)
            }
        }
    }
}
