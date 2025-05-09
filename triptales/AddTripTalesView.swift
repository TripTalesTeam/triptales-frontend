//
//  AddTripTalesView.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 9/5/2568 BE.
//

import SwiftUI

struct AddTripTaleView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var selectedCompanions: Set<String> = []
    @State private var image: Image? = Image("hokkaido") // Default image
    
    let companions = ["mj", "bell", "crpariz", "grace", "preme"]
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 16) {
                    
                    // MARK: - Take a Photo
                    ZStack(alignment: .bottomTrailing) {
                        image?
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipped()
                            .cornerRadius(12)
                        
                        Button(action: {
                            // Handle photo capture
                        }) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(16)
                    }
                    
                    // MARK: - Title Input
                    TextField("Title", text: $title)
                        .font(.title3)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3))
                        )
                        .padding(.horizontal)
                    
                    // MARK: - Static Location
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.gray)
                        Text("Hokkaido, Japan")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                    
                    // MARK: - Travel Companions
                    VStack(alignment: .leading) {
                        Text("Add Travel companion")
                            .font(.subheadline)
                            .padding(.leading)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(companions, id: \.self) { name in
                                    VStack {
                                        Image("cat") // Placeholder image
                                            .resizable()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedCompanions.contains(name) ? Color.orange : Color.clear, lineWidth: 3)
                                            )
                                            .onTapGesture {
                                                if selectedCompanions.contains(name) {
                                                    selectedCompanions.remove(name)
                                                } else {
                                                    selectedCompanions.insert(name)
                                                }
                                            }
                                        
                                        Text(name)
                                            .font(.caption2)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            
            // MARK: - Submit Button
            Button(action: {
                // Handle submission
            }) {
                Image(systemName: "paperplane.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color("ButtonBlue")) // Add custom color if desired
                    .clipShape(Circle())
            }
            .padding(.bottom, 16)
        }
        .navigationBarTitle("Add My TripTales", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
        .background(Color(red: 0.98, green: 0.96, blue: 0.93).ignoresSafeArea())
    }
}


#Preview {
    AddTripTaleView()
}
