import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode

    // Use AppStorage for persistence
    @AppStorage("username") private var username: String = ""
    @AppStorage("email") private var email: String = ""
    @AppStorage("token") private var token: String = ""
    @AppStorage("profileImageUrl") var profileImageUrl = ""
    @State private var profileImage: Image = Image("profile_placeholder") // Replace with actual image logic
    @State private var selectedItems: [PhotosPickerItem] = [] // Change to an array for selection
    @State private var selectedImageData: Data? = nil // Store the selected image data
    @State private var showImagePicker: Bool = false
    @State private var isLoading: Bool = false
    @State private var imageUrl: String = ""
    @State private var newUsername: String = ""
    @State private var newEmail: String = ""
    private var cloudinaryUploader = CloudinaryUploader()

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(title: "Edit Profile") {
                presentationMode.wrappedValue.dismiss()
            }

            ScrollView {
                ZStack(alignment: .top) {
                    VStack(spacing: 20) {
                        ZStack {
                            profileImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                                .shadow(radius: 4)

                            Image(systemName: "camera.fill")
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .offset(x: 40, y: 40)
                                .onTapGesture {
                                    showImagePicker.toggle()
                                }
                        }
                        .onAppear {
                            loadImageFromURL()
                        }

                        VStack(spacing: 16) {
                            CustomTextField(title: "Username", text: $newUsername)
                            CustomTextField(title: "Email", text: $newEmail)
                        }
                        .padding(.horizontal, 24)

                        Button(action: {
                            saveProfile()
                        }) {
                            Text("Save Profile")
                                .foregroundColor(.orange)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(radius: 1)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    }
                    .padding(.top, 100) // Padding from top of ScrollView

                    // Show a loading indicator when isLoading is true
                    if isLoading {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                                    .scaleEffect(2)
                                    .padding(50)
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(Color.black.opacity(0))
                        .edgesIgnoringSafeArea(.all)
                    }
                }
            }
            .background(Color(red: 0.98, green: 0.96, blue: 0.93))
            .navigationBarBackButtonHidden(true)
            .onAppear{
                newUsername = username
                newEmail = email
            }
        }
        .photosPicker(isPresented: $showImagePicker, selection: $selectedItems, maxSelectionCount: 1, matching: .images, photoLibrary: .shared()) // PhotosPicker setup
        .onChange(of: selectedItems) { newItems in
            // Check if the selectedItems array is not empty
            if let selectedItem = newItems.first {
                Task {
                    // Retrieve selected asset
                    // Retrieve selected image data
                    if let data = try? await selectedItem.loadTransferable(type: Data.self) {
                        self.selectedImageData = data
                        if let uiImage = UIImage(data: data) {
                            self.profileImage = Image(uiImage: uiImage)
                            // Upload to Cloudinary
                            uploadProfileImage(uiImage)
                        }
                    }
                }
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


    // Function to upload image to Cloudinary
    private func uploadProfileImage(_ image: UIImage) {
        isLoading = true
        cloudinaryUploader.uploadImage(image) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    // Successfully uploaded image, store the URL
                    self.imageUrl = url
                    print("Image uploaded: \(url)")
                    self.isLoading = false
                case .failure(let error):
                    // Handle error
                    print("Cloudinary upload failed: \(error.localizedDescription)")
                    self.isLoading = false
                }
            }
        }
    }

    private func saveProfile() {
        guard let url = URL(string: "https://www.breezejirasak.com/api/users/update") else { return }
        isLoading = true

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "username": newUsername.isEmpty ? username : newUsername,
            "email": newEmail.isEmpty ? email : newEmail,
            "profile_image": imageUrl.isEmpty ? profileImageUrl : imageUrl
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing request body: \(error)")
            isLoading = false
            return
        }
        
        // Create a custom session configuration
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        
        // Create a session with this configuration
        let session = URLSession(configuration: config)

        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
            }

            if let error = error {
                print("API call failed: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                print("Server error")
                return
            }

            DispatchQueue.main.async {
                // Update AppStorage values and dismiss view
                username = newUsername.isEmpty ? username : newUsername
                email = newEmail.isEmpty ? email : newEmail
                profileImageUrl = imageUrl.isEmpty ? profileImageUrl : imageUrl
                presentationMode.wrappedValue.dismiss()
            }
        }.resume()
    }
}
