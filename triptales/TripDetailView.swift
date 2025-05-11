//
//  JournalTripDetailView.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 10/5/2568 BE.
//
import SwiftUI

struct JournalTripDetailView: View {
    let tripId: String
    @State private var tripDetail: TripResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @AppStorage("token") var token: String = ""
    @State private var bookmarkedTripIDs: Set<String> = []

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading...")
            } else if let trip = tripDetail {
                ScrollView {
                    VStack(alignment: .leading) {
                        VStack(alignment: .leading) {
                            ZStack(alignment: .topLeading) {
                                AsyncImage(url: URL(string: trip.image)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 370, height: 380)
                                .cornerRadius(16)
                                .clipped()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.gray)
                                        Text(trip.user.username)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                }

                                Text(trip.title)
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .bold()

                                Text(trip.description)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)

                                HStack {
                                    Image(systemName: "mappin.and.ellipse")
                                        .foregroundColor(.gray)
                                    Text(trip.country.name)
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
                    }
                }
            } else if let error = errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .background(Color(red: 0.98, green: 0.96, blue: 0.93))
        .navigationTitle("My TripTales @\(tripDetail?.country.name ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: fetchTripDetail)
    }

    func fetchTripDetail() {
        guard let url = URL(string: "https://www.breezejirasak.com/api/trips/\(tripId)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        
        let session = URLSession(configuration: config)

        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Error: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No data received"
                }
                return
            }

            do {
                let trip = try JSONDecoder().decode(TripResponse.self, from: data)
                DispatchQueue.main.async {
                    self.tripDetail = trip
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Decoding failed"
                }
            }
        }.resume()
    }
}
