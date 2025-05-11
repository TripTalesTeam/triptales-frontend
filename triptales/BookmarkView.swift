import SwiftUI

// MARK: - ViewModel

class BookmarkViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var countries: [Country] = []


    // Updated function that works around potential Cloudflare issues
    func fetchCountries(token: String) {
        guard let url = URL(string: "https://www.breezejirasak.com/api/countries") else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        
        // Set essential headers
        request.httpMethod = "GET"
        
        // Add the authorization header with no modifications
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Create a custom session configuration
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        
        // Create a session with this configuration
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Country fetch error:", error?.localizedDescription ?? "Unknown error")
                return
            }
            
            do {
                // First try array decoding
                let countries = try JSONDecoder().decode([Country].self, from: data)
                DispatchQueue.main.async {
                    self.countries = countries
                }
            } catch {
                print("Array decoding error:", error)
                
                // If array decoding fails, try decoding as error response
                do {
                    let errorResponse = try JSONDecoder().decode([String: String].self, from: data)
                    print("Decoded error response:", errorResponse)
                } catch {
                    print("Error response decoding failed too:", error)
                }
            }
        }.resume()
    }

    func fetchTrips(for country: String, token: String) {
        guard let encodedCountry = country.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.breezejirasak.com/api/trips/bookmark?country=\(encodedCountry)") else {
            return
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Trip fetch error:", error?.localizedDescription ?? "Unknown error")
                return
            }
            do {
                let trips = try JSONDecoder().decode([Trip].self, from: data)
                DispatchQueue.main.async {
                    self.trips = trips
                }
            } catch {
                print("Trip decoding error:", error)
            }
        }.resume()
    }
}

// MARK: - FeedView

struct BookmarkView: View {
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("username") var username: String = ""
    @AppStorage("token") var token: String = ""

    @StateObject private var viewModel = BookmarkViewModel()
    @State private var selectedCountry = ""
    @State private var bookmarkedTripIDs: Set<String> = []


    var body: some View {
        VStack(spacing: 0) {
            // MARK: Header
            HeaderView(title: "Bookmark") {
                presentationMode.wrappedValue.dismiss()
            }
            // MARK: Country Selector
            ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(viewModel.countries, id: \.self) { country in
                            VStack {
                                AsyncImage(url: URL(string: country.country_image)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 70, height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                
                                Text(country.name)
                                    .font(.caption)
                                    .foregroundColor(.black)
                            }
                            .onTapGesture {
                                if selectedCountry == country.name {
                                    selectedCountry = ""
                                } else {
                                    selectedCountry = country.name
                                }
                                viewModel.fetchTrips(for: selectedCountry, token: token)
                            }
                        }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }

            // MARK: Trip Cards - Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.trips) { trip in
                        VStack(alignment: .leading) {
                            ZStack(alignment: .topLeading) {
                                AsyncImage(url: URL(string: trip.image)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color.gray.opacity(0.3)
                                }
                                .frame(width: 350, height: 380)
                                .cornerRadius(16)
                                .clipped()
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    
                                    
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.gray)
                                        Text(trip.user.username)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    Spacer()
                                    Button(action: {
                                        if bookmarkedTripIDs.contains(trip.id) {
                                            // UNBOOKMARK: Send DELETE
                                            unbookmarkTrip(tripId: trip.id, token: token) { success in
                                                if success {
                                                    viewModel.fetchTrips(for: selectedCountry, token: token)
                                                    bookmarkedTripIDs.remove(trip.id)
                                                } else {
                                                    print("Failed to remove bookmark.")
                                                }
                                            }
                                        } else {
                                            // BOOKMARK: Send POST
                                            bookmarkTrip(tripId: trip.id, token: token) { success in
                                                if success {
                                                    bookmarkedTripIDs.insert(trip.id)
                                                } else {
                                                    print("Failed to bookmark trip.")
                                                }
                                            }
                                        }
                                    }) {
                                        Image(systemName: bookmarkedTripIDs.contains(trip.id) ? "bookmark.fill" : "bookmark")
                                            .foregroundColor(bookmarkedTripIDs.contains(trip.id) ? .yellow : .gray)
                                    }
                                    .buttonStyle(PlainButtonStyle())
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
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }

            Spacer()
        }
        .onAppear {
            viewModel.fetchCountries(token: token)
            viewModel.fetchTrips(for: selectedCountry, token: token)
            fetchBookmarkedTrips(token: token) { fetchedIDs in
                self.bookmarkedTripIDs = fetchedIDs
            }
        }
        .background(Color(red: 0.98, green: 0.96, blue: 0.93))
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden(true)
    }
    
}
