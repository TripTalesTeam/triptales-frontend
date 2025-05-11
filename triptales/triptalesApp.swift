import SwiftUI

@main
struct triptalesApp: App {
    @StateObject var session = SessionManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
        }
    }
}
