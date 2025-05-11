//
//  JournalView.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 9/5/2568 BE.
//

import SwiftUI
import MapKit

// MARK: - Location Model
struct Location: Identifiable {
    let id = UUID()
    let tripId: String
    let coordinate: CLLocationCoordinate2D
    let title: String
    let description: String
}

// MARK: - Trip API Response Model
struct TripResponse: Decodable {
    let trip_id: String
    let title: String
    let description: String
    let latitude: Double
    let longitude: Double
    let image: String
    let user: User
    let country: TripCountry
}

// MARK: - Trip Detail View
struct TripDetailView: View {
    let tripId: String

    var body: some View {
        VStack {
            Text("Trip Detail View")
                .font(.title)
                .padding(.bottom, 10)
            Text("Trip ID: \(tripId)")
                .font(.subheadline)
        }
        .navigationTitle("Trip Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Journal View
struct JournalView: View {
    @AppStorage("username") var username: String = ""
    @AppStorage("token") var token: String = ""
    
    @State private var locations: [Location] = []
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 16.0, longitude: 103.0),
        span: MKCoordinateSpan(latitudeDelta: 5.0, longitudeDelta: 5.0)
    )
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, annotationItems: locations) { location in
                    MapAnnotation(coordinate: location.coordinate) {
                        NavigationLink(destination: JournalTripDetailView(tripId: location.tripId)) {
                            VStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .foregroundColor(.red)
                                    .frame(width: 30, height: 30)
                                Text(location.title)
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                .ignoresSafeArea()

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            fetchTrips()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title)
                                .padding()
                                .background(Color.black)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .padding()
                    }
                }

                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                }

                if let message = errorMessage {
                    VStack {
                        Spacer()
                        Text(message)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                    }
                }
            }
            .onAppear {
                fetchTrips()
            }
            .navigationTitle("")
        }
    }

    // MARK: - Fetch Trips from API
    func fetchTrips() {
        guard !token.isEmpty else {
            errorMessage = "Missing token. Please log in again."
            return
        }

        guard let url = URL(string: "https://www.breezejirasak.com/api/trips") else {
            errorMessage = "Invalid URL."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        isLoading = true
        errorMessage = nil
        
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        let session = URLSession(configuration: config)

        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
            }

            if let error = error {
                print("❌ Request error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Network error. Please try again later."
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid response from server."
                }
                return
            }

            print("📥 HTTP Status Code: \(httpResponse.statusCode)")

            guard (200...299).contains(httpResponse.statusCode) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Server error: \(httpResponse.statusCode)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.errorMessage = "No data received from server."
                }
                return
            }

            if let jsonString = String(data: data, encoding: .utf8) {
                print("📦 Raw API response: \(jsonString)")
            }

            do {
                let trips = try JSONDecoder().decode([TripResponse].self, from: data)
                processTripData(trips)
            } catch {
                print("❌ Decoding error: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode data: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func processTripData(_ trips: [TripResponse]) {
        print("✅ Successfully decoded \(trips.count) trips")
        
        DispatchQueue.main.async {
            self.locations = trips.map {
                Location(
                    tripId: $0.trip_id,
                    coordinate: CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude),
                    title: $0.title,
                    description: $0.description
                )
            }

            if let firstLocation = self.locations.first {
                self.region = MKCoordinateRegion(
                    center: firstLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
            }
        }
    }
}
