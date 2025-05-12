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
    @State private var isLoading: Bool = false

    @StateObject private var locationManager = LocationManager()

    var displayedImage: Image? {
        if let uiImage = selectedUIImage {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                HeaderView(title: "Add My TripTales") {
                    presentationMode.wrappedValue.dismiss()
                }
                ScrollView {
                    VStack(alignment: .leading) {
                        // MARK: - Image Section
                        ZStack(alignment: .bottomTrailing) {
                            if let image = displayedImage {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipped()
                                    .cornerRadius(16)
                                    .padding(.horizontal)
                            } else {
                                // Placeholder
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 250)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo.on.rectangle")
                                                .font(.system(size: 40))
                                                .foregroundColor(.gray)
                                            Text("No Image Selected")
                                                .foregroundColor(.gray)
                                                .font(.body)
                                        }
                                    )
                                    .padding(.horizontal)
                            }
                            
                            // Camera Button
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
                                .foregroundColor(.black)
                            
                            TextField("", text: $title)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                                .padding(.horizontal)
                        }
                        
                        // MARK: - Description
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Description")
                                .font(.headline)
                                .padding(.horizontal)
                                .foregroundColor(.black)
                            
                            
                            TextEditor(text: $description)
                                .frame(height: 120)
                                .padding(10)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.3))
                                )
                                .padding(.horizontal)
                            
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
                                .foregroundColor(.black)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(companions, id: \.friend_id) { companion in
                                        VStack {
                                            Image(systemName: "person.crop.circle.fill")
                                                .resizable()
                                                .foregroundColor(.gray)
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
                                                .foregroundColor(.black)
                                        }
                                    }
                                }
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
                            .background(Color.blue)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.top)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            if isLoading {
                Color.black.opacity(0.4) // Dimmed background
                    .edgesIgnoringSafeArea(.all)
                    .zIndex(1)

                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        .scaleEffect(2)
                        .padding(50)
                        .background(Color.white)
                        .cornerRadius(15)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(2)
            }
        }
        
            .background(Color(red: 0.98, green: 0.96, blue: 0.93).ignoresSafeArea())
            .navigationBarBackButtonHidden(true)
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
        isLoading = true
        print("Loading started...")

        guard !title.isEmpty, !description.isEmpty else {
            print("Validation failed: Title or Description is empty")
            isLoading = false
            print("Loading stopped due to validation failure")
            return
        }

        if locationManager.locationName.isEmpty {
            print("Validation failed: Location name is empty")
            isLoading = false
            print("Loading stopped due to missing location name")
            return
        }

        let components = locationManager.locationName.components(separatedBy: ",")
        let countryName = components.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? locationManager.locationName
        print("Extracted country name: \(countryName)")

        guard let encodedCountryName = countryName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let countryURL = URL(string: "https://www.breezejirasak.com/api/countries/by-name?name=\(encodedCountryName)") else {
            print("Failed to create valid URL for country API")
            isLoading = false
            print("Loading stopped due to invalid country URL")
            return
        }

        print("Sending GET request to country API: \(countryURL)")

        var countryRequest = URLRequest(url: countryURL)
        countryRequest.httpMethod = "GET"
        countryRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        let session = URLSession(configuration: config)

        session.dataTask(with: countryRequest) { data, response, error in
            if let error = error {
                print("Country API error: \(error.localizedDescription)")
                isLoading = false
                print("Loading stopped due to API error")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("Country API status code: \(httpResponse.statusCode)")
            }

            guard let data = data else {
                print("No data returned from country API")
                isLoading = false
                print("Loading stopped due to empty country API response")
                return
            }

            if let rawJson = String(data: data, encoding: .utf8) {
                print("Raw country JSON response: \(rawJson)")
            }

            guard let country = try? JSONDecoder().decode(CountryResponse.self, from: data) else {
                print("Failed to decode country JSON")
                isLoading = false
                print("Loading stopped due to decode error")
                return
            }

            print("Successfully decoded country: \(country)")

            if let image = selectedUIImage {
                print("Uploading selected image to Cloudinary...")
                CloudinaryUploader().uploadImage(image) { result in
                    switch result {
                    case .success(let imageUrl):
                        print("Image uploaded. URL: \(imageUrl)")

                        let tripData = AddTripRequest(
                            title: title,
                            description: description,
                            image: imageUrl,
                            latitude: locationManager.latitude,
                            longitude: locationManager.longitude,
                            country_id: country.country_id
                        )

                        guard let postURL = URL(string: "https://www.breezejirasak.com/api/trips"),
                              let encoded = try? JSONEncoder().encode(tripData) else {
                            print("Failed to encode trip data")
                            isLoading = false
                            print("Loading stopped due to encoding failure")
                            return
                        }

                        print("Sending POST request to: \(postURL)")

                        var postRequest = URLRequest(url: postURL)
                        postRequest.httpMethod = "POST"
                        postRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                        postRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
                        postRequest.httpBody = encoded
                        
                        // Create a custom session configuration
                        let config = URLSessionConfiguration.default
                        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
                        
                        // Create a session with this configuration
                        let session = URLSession(configuration: config)
                        
                        session.dataTask(with: postRequest) { data, response, error in
                            defer {
                                isLoading = false
                                print("Loading stopped after POST request")
                            }

                            if let error = error {
                                print("POST request error: \(error.localizedDescription)")
                                return
                            }

                            guard let data = data else {
                                print("No data returned from POST request")
                                return
                            }

                            if let responseString = String(data: data, encoding: .utf8) {
                                print("Trip POST response: \(responseString)")
                            }

                            if let httpResponse = response as? HTTPURLResponse {
                                print("Trip POST status code: \(httpResponse.statusCode)")
                                if httpResponse.statusCode == 201 {
                                    do {
                                        let tripResponse = try JSONDecoder().decode(TripResponse.self, from: data)
                                        let tripId = tripResponse.trip_id
                                        print("Trip created with ID: \(tripId)")

                                        if !tripId.isEmpty {
                                            print("Adding companions: \(selectedCompanions)")
                                            for friendId in selectedCompanions {
                                                self.addCompanionToTrip(tripId: tripId, friendId: friendId)
                                            }
                                        }
                                    } catch {
                                        print("Failed to decode trip response: \(error.localizedDescription)")
                                    }
                                } else {
                                    print("Trip POST failed with status code: \(httpResponse.statusCode)")
                                }
                            }

                        }.resume()

                    case .failure(let error):
                        print("Image upload failed: \(error.localizedDescription)")
                        isLoading = false
                        print("Loading stopped due to image upload failure")
                    }
                }

            } else {
                print("No image selected. Skipping upload.")
                isLoading = false
                print("Loading stopped due to missing image")
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
            DispatchQueue.main.async {
                print("Submission succeeded, navigating back")
                self.presentationMode.wrappedValue.dismiss()
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
