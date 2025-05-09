//
//  triptalesApp.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 9/5/2568 BE.
//

import SwiftUI

@main
struct triptalesApp: App {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}
