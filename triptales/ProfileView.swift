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
                    
                    VStack(alignment: .leading) {
                        Text("Welcome To Your Journal !")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text("Breezy")
                            .font(.headline)
                            .bold()
                    }
                    
                    Spacer()
                    
                    Image(systemName: "bell")
                        .font(.title3)
                }
                .padding()

                // Option List
                VStack(spacing: 20) {
                    ProfileRow(icon: "person.crop.circle", label: "Edit Profile")
                    ProfileRow(icon: "bookmark", label: "Bookmark")
                    ProfileRow(icon: "person.2.fill", label: "Friends")
                    ProfileRow(icon: "arrowshape.turn.up.left.fill", label: "Logout")
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
    }
}

// MARK: - Profile Row Component
struct ProfileRow: View {
    let icon: String
    let label: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
            Text(label)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
    }
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
