import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionManager

    var body: some View {
        Group {
            if session.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
