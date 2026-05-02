import SwiftUI

enum UserRole {
    case arties
    case klant
    case shop
}

struct LoginView: View {
    @Binding var selectedRole: UserRole?

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

                // Logo
                Image("TattoeLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 32))

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

#Preview {
    LoginView(selectedRole: .constant(nil))
}
