//
//  FeedView.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 9/5/2568 BE.
//

import SwiftUI

struct FeedView: View {
    @AppStorage("username") var username: String = ""
    @AppStorage("token") var token: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            HStack {
                Image("profile")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .padding(.leading)

                VStack(alignment: .leading) {
                    Text("Welcome To Your Journal !")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(username)
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                Image(systemName: "bell")
                    .font(.title2)
                    .padding(.trailing)
            }
            .padding(.vertical)

            // MARK: - Country Selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(["Japan", "Thailand", "England", "China", "Vietnam", "Singapore"], id: \.self) { country in
                        VStack {
                            Image(country.lowercased())
                                .resizable()
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            Text(country)
                                .font(.caption)
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.horizontal)
            }

            // MARK: - Featured Journal Card
            VStack(alignment: .leading) {
                ZStack(alignment: .topLeading) {
                    Image("hokkaido")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .cornerRadius(16)
                        .clipped()
                    
                    Image("profile")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                        .padding(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Travel to Hokkaido")
                            .font(.headline)
                            .bold()
                        Spacer()
                        Image(systemName: "bookmark.fill")
                            .foregroundColor(.yellow)
                    }

                    Text("Hokkaido is a dream! ❄️🗻 Stunning views, delicious food, and endless adventures! 🇯🇵✨")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.gray)
                        Text("Hokkaido, Japan")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
            }
            .padding()

            // MARK: - Page Indicators
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    Circle()
                        .fill(index == 0 ? Color.orange : Color.gray.opacity(0.4))
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()
        }
        .background(Color(red: 0.98, green: 0.96, blue: 0.93))
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
    }
}


struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
