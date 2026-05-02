import SwiftUI

struct ContentView: View {
    @State private var selectedRole: UserRole? = nil
    @StateObject private var klantStore  = KlantStore()
    @StateObject private var artiesStore = ArtiesStore()
    @StateObject private var shopStore   = ShopStore()

    var body: some View {
        Group {
            if let role = selectedRole {
                switch role {
                case .klant:
                    KlantFlowView(onLogout: { selectedRole = nil })
                        .environmentObject(klantStore)
                case .arties:
                    ArtiesFlowView(onLogout: { selectedRole = nil })
                        .environmentObject(artiesStore)
                case .shop:
                    ShopFlowView(onLogout: { selectedRole = nil })
                        .environmentObject(shopStore)
                }
            } else {
                LoginView(selectedRole: $selectedRole)
            }
        }
    }
}


#Preview {
    ContentView()
}
