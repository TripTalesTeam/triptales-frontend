import SwiftUI

class SessionManager: ObservableObject {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false {
        didSet { objectWillChange.send() }
    }

    // Optional: Other shared session data
    @AppStorage("username") var username: String = ""
    @AppStorage("token") var token: String = ""

    func login(token: String, username: String) {
        self.token = token
        self.username = username
        self.isLoggedIn = true
    }

    func logout() {
        isLoggedIn = false
        token = ""
        username = ""

        UserDefaults.standard.removeObject(forKey: "userID")
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "profileImageUrl")
    }
}
