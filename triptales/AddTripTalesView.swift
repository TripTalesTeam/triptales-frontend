//
//  AddTripTalesView.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 9/5/2568 BE.
//

import SwiftUI
import UIKit
import CoreLocation

struct FriendResponse: Decodable, Identifiable {
    var id: String { friend_id }
    let friend_id: String
    let friend: User
}

struct CountryResponse: Decodable {
    let country_id: String
    let name: String
}

struct AddTripRequest: Encodable {
    let title: String
    let description: String
    let image: String?
    let latitude: Double?
    let longitude: Double?
    let country_id: String
}


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var locationError: String?
    @Published var locationName: String = "Fetching location..."

    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        self.latitude = newLocation.coordinate.latitude
        self.longitude = newLocation.coordinate.longitude
        self.locationError = nil
        reverseGeocode(location: newLocation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.locationError = "Location error: \(error.localizedDescription)"
        print("Location error: \(error.localizedDescription)")
    }

    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = "Location access denied. Please enable location services."
        case .authorizedWhenInUse, .authorizedAlways:
            break
        @unknown default:
            locationError = "Unknown location authorization status"
        }
    }

    private func reverseGeocode(location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let _ = error {
                self.locationName = "Unable to get location name"
                return
            }

            if let placemark = placemarks?.first {
                let locality = placemark.locality ?? placemark.name ?? ""
                let country = placemark.country ?? ""
                DispatchQueue.main.async {
                    self.locationName = "\(locality), \(country)"
                }
            }
        }
    }
}

struct AddTripTaleView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedCompanions: Set<String> = []
    @AppStorage("token") var token: String = ""
    @State private var companions: [FriendResponse] = []

    @State private var showImagePicker: Bool = false
    @State private var selectedUIImage: UIImage? = nil
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var showPhotoSourceDialog: Bool = false

    @StateObject private var locationManager = LocationManager()

    var displayedImage: Image? {
        if let uiImage = selectedUIImage {
            return Image(uiImage: uiImage)
        } else {
            return Image("hokkaido")
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    // MARK: - Image Section
                    ZStack(alignment: .bottomTrailing) {
                        displayedImage?
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipped()
                            .cornerRadius(16)
                            .padding(.horizontal)

                        Button(action: {
                            showPhotoSourceDialog = true
                        }) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 32)
                        .padding(.bottom, 16)
                    }

                    // MARK: - Title
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Trip Title")
                            .font(.headline)
                            .padding(.horizontal)

                        TextField("e.g. Hokkaido Adventure", text: $title)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                            .padding(.horizontal)
                    }

                    // MARK: - Description
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Description")
                            .font(.headline)
                            .padding(.horizontal)

                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $description)
                                .frame(height: 120)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                                .padding(.horizontal)

                            if description.isEmpty {
                                Text("Write a short description...")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 26)
                                    .padding(.top, 22)
                            }
                        }
                    }

                    // MARK: - Static Location (now dynamic)
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.gray)
                        Text(locationManager.locationName)
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .padding(.horizontal)

                    // MARK: - Travel Companions
                    VStack(alignment: .leading) {
                        Text("Travel Companions")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                ForEach(companions, id: \.friend_id) { companion in
                                    VStack {
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .frame(width: 60, height: 60)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(selectedCompanions.contains(companion.friend_id) ? Color.orange : Color.clear, lineWidth: 3)
                                            )
                                            .onTapGesture {
                                                if selectedCompanions.contains(companion.friend_id) {
                                                    selectedCompanions.remove(companion.friend_id)
                                                } else {
                                                    selectedCompanions.insert(companion.friend_id)
                                                }
                                            }

                                        Text(companion.friend.username)
                                            .font(.caption2)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // MARK: - Location Coordinates
                    VStack(alignment: .leading) {
                        Text("Location Coordinates")
                            .font(.headline)
                            .padding(.horizontal)

                        if let latitude = locationManager.latitude,
                           let longitude = locationManager.longitude {
                            Text("Latitude: \(latitude)")
                                .padding(.horizontal)
                            Text("Longitude: \(longitude)")
                                .padding(.horizontal)
                        } else {
                            Text(locationManager.locationError ?? "Fetching location...")
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.top)

                    Button(action: {
                        submitTripTale()
                    }) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Submit Trip Tale")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color("ButtonBlue"))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                .padding(.top)
            }
            .background(Color(red: 0.98, green: 0.96, blue: 0.93).ignoresSafeArea())
            .navigationTitle("Add My TripTales")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                fetchFriendList()
                locationManager.checkLocationAuthorization()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(sourceType: sourceType, selectedImage: $selectedUIImage)
            }
            .confirmationDialog("Select Photo", isPresented: $showPhotoSourceDialog, titleVisibility: .visible) {
                Button("Camera") {
                    sourceType = .camera
                    showImagePicker = true
                }
                Button("Photo Library") {
                    sourceType = .photoLibrary
                    showImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    func fetchFriendList() {
        guard let url = URL(string: "https://www.breezejirasak.com/api/friends") else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]

        let session = URLSession(configuration: config)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }

            do {
                let trip = try JSONDecoder().decode([FriendResponse].self, from: data)
                DispatchQueue.main.async {
                    self.companions = trip
                }
            } catch {
                print("Decoding failed: \(error)")
            }
        }.resume()
    }
    
    func submitTripTale() {
        print("submitTripTale() called")

        guard !title.isEmpty, !description.isEmpty else {
            print("Validation failed: Title and description are required.")
            return
        }

        if locationManager.locationName.isEmpty {
            print("Validation failed: Location name is empty.")
            return
        }

        let components = locationManager.locationName.components(separatedBy: ",")
        let countryName = components.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? locationManager.locationName
        print("Extracted country name: \(countryName)")

        guard let encodedCountryName = countryName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let countryURL = URL(string: "https://www.breezejirasak.com/api/countries/by-name?name=\(encodedCountryName)") else {
            print("Invalid country URL with name: \(countryName)")
            return
        }

        print("Fetching country from URL: \(countryURL)")

        var countryRequest = URLRequest(url: countryURL)
        countryRequest.httpMethod = "GET"
        countryRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        let session = URLSession(configuration: config)

        session.dataTask(with: countryRequest) { data, response, error in
            if let error = error {
                print("Country fetch error: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Country fetch HTTP status: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                print("No data returned from country API")
                return
            }

            if let rawJson = String(data: data, encoding: .utf8) {
                print("Raw country JSON response: \(rawJson)")
            }

            guard let country = try? JSONDecoder().decode(CountryResponse.self, from: data) else {
                print("Failed to decode country response")
                return
            }

            print("Fetched country: \(country)")

            if let image = selectedUIImage {
                print("Uploading image to Cloudinary...")

                CloudinaryUploader().uploadImage(image) { result in
                    switch result {
                    case .success(let imageUrl):
                        print("Image uploaded successfully. URL: \(imageUrl)")

                        let tripData = AddTripRequest(
                            title: title,
                            description: description,
                            image: imageUrl,
                            latitude: locationManager.latitude,
                            longitude: locationManager.longitude,
                            country_id: country.country_id
                        )

                        print("Prepared trip data: \(tripData)")

                        guard let postURL = URL(string: "https://www.breezejirasak.com/api/trips"),
                              let encoded = try? JSONEncoder().encode(tripData) else {
                            print("Failed to encode trip data")
                            return
                        }

                        var postRequest = URLRequest(url: postURL)
                        postRequest.httpMethod = "POST"
                        postRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        postRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        postRequest.httpBody = encoded

                        print("Sending POST request to \(postURL)")

                        let postConfig = URLSessionConfiguration.default
                        postConfig.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
                        let postSession = URLSession(configuration: postConfig)

                        postSession.dataTask(with: postRequest) { data, response, error in
                            if let error = error {
                                print("Submission error: \(error.localizedDescription)")
                                return
                            }

                            if let httpResponse = response as? HTTPURLResponse {
                                print("POST response HTTP status: \(httpResponse.statusCode)")
                            }

                            // Safely unwrap `data` before using it
                            guard let data = data else {
                                print("No data returned from trip submission")
                                return
                            }

                            if let responseString = String(data: data, encoding: .utf8) {
                                print("POST response body: \(responseString)")
                            }

                            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                                // Trip created successfully, now extract trip_id and add companions
                                do {
                                    let tripResponse = try JSONDecoder().decode(TripResponse.self, from: data)
                                    let tripId = tripResponse.trip_id
                                    if !tripId.isEmpty {
                                        print("Trip created with ID: \(tripId)")

                                        // Now, add companions one by one
                                        print("Selected companions", selectedCompanions)
                                        for friendId in selectedCompanions {
                                            self.addCompanionToTrip(tripId: tripId, friendId: friendId)
                                        }
                                    } else {
                                        print("Failed to parse trip response or trip_id")
                                    }
                                } catch {
                                    print("Failed to decode trip response: \(error.localizedDescription)")
                                }
                            } else {
                                print("Unexpected server response on trip submission")
                            }
                        }.resume()

                    case .failure(let error):
                        print("Image upload failed: \(error.localizedDescription)")
                    }
                }
            } else {
                print("No image selected, skipping upload")
            }

        }.resume()
    }

    // Function to add a companion to the trip
    func addCompanionToTrip(tripId: String, friendId: String) {
        let addCompanionData: [String: Any] = [
            "trip_id": tripId,
            "user_id": friendId
        ]
        print("tripp and friend", tripId, friendId)

        guard let addCompanionURL = URL(string: "https://www.breezejirasak.com/api/trip-companions"),
              let encoded = try? JSONSerialization.data(withJSONObject: addCompanionData, options: []) else {
            print("Failed to encode companion data")
            return
        }

        var postRequest = URLRequest(url: addCompanionURL)
        postRequest.httpMethod = "POST"
        postRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        postRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        postRequest.httpBody = encoded

        let postConfig = URLSessionConfiguration.default
        postConfig.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        let postSession = URLSession(configuration: postConfig)

        postSession.dataTask(with: postRequest) { data, response, error in
            if let error = error {
                print("Add companion error: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Add companion HTTP status: \(httpResponse.statusCode)")
            }

            // Safely unwrap `data` before using it
            guard let data = data else {
                print("No data returned from adding companion")
                return
            }

            if let responseString = String(data: data, encoding: .utf8) {
                print("Add companion response body: \(responseString)")
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 201 {
                print("Companion added successfully.")
            } else {
                print("Unexpected server response on adding companion")
            }
        }.resume()
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview
#Preview {
    AddTripTaleView()
}
