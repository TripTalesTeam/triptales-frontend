//
//  ProfileView.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 9/5/2568 BE.
//

import SwiftUI

// MARK: - Main Profile View
struct ProfileView: View {
    @AppStorage("username") var username: String = ""
    @AppStorage("token") var token: String = ""
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = true
    @State private var showLogoutAlert = false
    @EnvironmentObject var session: SessionManager
    @State private var showProfilePage = false
    @AppStorage("profileImageUrl") var profileImageUrl = ""
    @State private var profileImage: Image? = nil

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color(red: 1.0, green: 0.94, blue: 0.92)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 20) {
                    // Top Bar
                    HStack {
                        if let image = profileImage {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.gray)
                        }

                        VStack(alignment: .leading) {
                            Text("Welcome To Your Journal !")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(username)
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
                    .onAppear {
                        loadImageFromURL()
                    }

                    // Profile Options
                    VStack(spacing: 20) {
                        // Edit Profile Navigation
                        NavigationLink(destination: EditProfileView()) {
                            ButtonRow(icon: "person.crop.circle", label: "Edit Profile", action: {})
                        }

                        Divider()

                        // Bookmark Navigation
                        NavigationLink(destination: BookmarkView()) {
                            ButtonRow(icon: "bookmark", label: "Bookmark", action: {})
                        }

                        Divider()

                        // Friends Navigation
                        NavigationLink(destination: EmptyView()) {
                            ButtonRow(icon: "person.2.fill", label: "Friends", action: {})
                        }

                        Divider()

                        // Logout Button
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

                // Bottom Decoration
                VStack {
                    Spacer()
                    Circle()
                        .fill(Color.orange)
                        .scaleEffect(x: 2.0, y: 1.0)
                        .frame(height: 200)
                        .offset(y: 100)
                }
                .ignoresSafeArea()
            }
            .navigationBarBackButtonHidden(true)
            .alert(isPresented: $showLogoutAlert) {
                Alert(
                    title: Text("Logout"),
                    message: Text("Are you sure you want to logout?"),
                    primaryButton: .destructive(Text("Logout")) {
                        session.logout()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    func loadImageFromURL() {
        guard let url = URL(string: profileImageUrl), !profileImageUrl.isEmpty else { return }

        // Download image on background thread
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let uiImage = UIImage(data: data) else {
                return
            }

            // Update UI on the main thread
            DispatchQueue.main.async {
                profileImage = Image(uiImage: uiImage)
            }
        }.resume()
    }
}

// MARK: - Reusable Row Button
struct ButtonRow: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        .buttonStyle(PlainButtonStyle())
    }
}
