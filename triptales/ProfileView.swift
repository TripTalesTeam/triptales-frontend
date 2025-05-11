//
//  ProfileView.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 9/5/2568 BE.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("username") var username: String = ""
    @AppStorage("token") var token: String = ""
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true
    @State private var showLogoutAlert = false
    @EnvironmentObject var session: SessionManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 1.0, green: 0.94, blue: 0.92)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                // Top Bar
                HStack {
                    Image(systemName: "person.circle.fill") // Placeholder
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .foregroundColor(.gray)
                    
                    VStack(alignment: .leading) {
                        Text("Welcome To Your Journal !")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Breezy")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "bell")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding()

                // Option List
                VStack(spacing: 20) {
                    ProfileRow(icon: "person.crop.circle", label: "Edit Profile", destination: .editProfile)
                    
                    Divider()
                    
                    ProfileRow(icon: "bookmark", label: "Bookmark", destination: .bookmarks)
                    
                    Divider()
                    
                    ProfileRow(icon: "person.2.fill", label: "Friends", destination: .friends)
                    
                    Divider()
                    
                    // Logout row with custom action
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "arrowshape.turn.up.left.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("Logout")
                                .font(.body)
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)

                Spacer()
            }

            // Curved Bottom Background
            VStack(spacing: 0) {
                Spacer()
                Circle()
                    .fill(Color.orange)
                    .scaleEffect(x: 2.0, y: 1.0)
                    .frame(height: 200)
                    .offset(y: 100)
            }
            .ignoresSafeArea()
        }
        .navigationTitle("Profile")
        .alert(isPresented: $showLogoutAlert) {
            Alert(
                title: Text("Logout"),
                message: Text("Are you sure you want to logout?"),
                primaryButton: .destructive(Text("Logout")) {
                    // Perform logout action
                    session.logout()
                },
                secondaryButton: .cancel()
            )
        }
    }
}

// MARK: - Profile Row Component
struct ProfileRow: View {
    let icon: String
    let label: String
    let destination: ProfileDestination
    
    var body: some View {
        NavigationLink(destination: destinationView()) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.gray)
                Text(label)
                    .font(.body)
                    .foregroundColor(.black)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(PlainButtonStyle()) // Removes the default NavigationLink styling
    }
    
    @ViewBuilder
    private func destinationView() -> some View {
        switch destination {
        case .editProfile:
            EmptyView()
//            EditProfileView()
        case .bookmarks:
            EmptyView()
//            BookmarksView()
        case .friends:
            EmptyView()
//            FriendsView()
        case .logout:
            EmptyView() // Logout is handled differently
        }
    }
}

// Enum to represent different profile destinations
enum ProfileDestination {
    case editProfile
    case bookmarks
    case friends
    case logout
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let label: String
    var isSelected: Bool = false
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .foregroundColor(isSelected ? .blue : .black)
            Text(label)
                .font(.caption)
                .foregroundColor(isSelected ? .blue : .black)
        }
    }
}
