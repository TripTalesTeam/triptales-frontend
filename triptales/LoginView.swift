import SwiftUI

struct LoginView: View {
    var body: some View {
        NavigationStack {
            LoginFormContent()
                .navigationBarBackButtonHidden(true)
        }
    }
}

struct LoginFormContent: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background shape
                // Bottom curved shape
                GeometryReader { geo in
                    Circle()
                    .fill(Color.orange)
                    .frame(width: geo.size.width * 2, height: geo.size.width * 2)
                    .offset(x: -geo.size.width / 2, y: geo.size.height / 2)
                }
                .ignoresSafeArea(.keyboard)
                .frame(height: 100)
                
                VStack(spacing: 30) {
                    // App title
                    Text("TripTales")
                        .font(.system(size: 32, weight: .bold))
                        .padding(.top, 60)
                    
                    VStack(spacing: 16) {
                        // Username field
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        
                        // Password field
                        SecureField("Password", text: $password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        
                        // Login button
                        Button(action: {
                            login()
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 5)
                                
                                if isLoading {
                                    ProgressView()
                                } else {
                                    Text("Login")
                                        .foregroundColor(.orange)
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(height: 50)
                        }
                        .disabled(isLoading)
                        
                        // Register link
                        HStack {
                            Spacer()
                            NavigationLink(destination:RegisterView()) {
                                Text("Register?")
                                    .font(.callout)
                                    .foregroundColor(.white)
                            }
                            .padding(.trailing, 24)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Login Failed"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .background(Color(UIColor.systemBackground))
            .navigationBarHidden(true)
            // Navigation link is hidden but activated when login is successful
            .background(
                NavigationLink(destination: FeedView(), isActive: $isLoggedIn) {
                    EmptyView().navigationBarBackButtonHidden(true)
                }
            )
        }
    }
    
    func login() {
        guard !username.isEmpty && !password.isEmpty else {
            errorMessage = "Username and password cannot be empty"
            showError = true
            return
        }
        
        isLoading = true
        
        // Create the login request
        let loginData = LoginRequest(username: username, password: password)
        let apiService = APIService()
        
        apiService.login(with: loginData) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let loginResponse):
                    // Save JWT token and user data
                    TokenManager.shared.saveToken(loginResponse.token)
                    UserDefaults.standard.set(loginResponse.user.user_id, forKey: "userId")
                    UserDefaults.standard.set(loginResponse.user.username, forKey: "username")
                    UserDefaults.standard.set(loginResponse.user.email, forKey: "email")
                    UserDefaults.standard.set(loginResponse.expire_at, forKey: "tokenExpiry")
                    
                    // Parse expiry time for token refresh logic
                    if let expiryDate = ISO8601DateFormatter().date(from: loginResponse.expire_at) {
                        UserDefaults.standard.set(expiryDate.timeIntervalSince1970, forKey: "tokenExpiryTimestamp")
                    }
                    
                    // Navigate to home screen
                    isLoggedIn = true
                    NavigationLink(destination: FeedView(), isActive: $isLoggedIn) {
                        EmptyView()
                    }
                    
                case .failure(let error):
                    // Handle specific error types
                    if let apiError = error as? APIError {
                        switch apiError {
                        case .authenticationError(let message):
                            errorMessage = message
                        case .serverError(let message):
                            errorMessage = message
                        default:
                            errorMessage = apiError.localizedDescription
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    showError = true
                }
            }
        }
    }
}

// Custom shape for the orange wave at the bottom
struct RoundedShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: height * 0.6))
        path.addQuadCurve(
            to: CGPoint(x: width, y: height * 0.6),
            control: CGPoint(x: width * 0.5, y: 0)
        )
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        
        return path
    }
}

// API Models and Service
struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct ErrorResponse: Codable {
    let error: String
}

struct LoginResponse: Codable {
    let token: String
    let user: User
    let expire_at: String
}

struct User: Codable {
    let user_id: String
    let username: String
    let email: String
    let profile_image: String
    let trips: [Trip]?
    let friends: [Friend]?
    let companions: [Companion]?
    let bookmarks: [Bookmark]?
}

// Additional models for the optional arrays in User
struct Trip: Codable {
    // Add properties based on your API response
    let id: String?
    // Add other trip properties
}

struct Friend: Codable {
    // Add properties based on your API response
    let id: String?
    // Add other friend properties
}

struct Companion: Codable {
    // Add properties based on your API response
    let id: String?
    // Add other companion properties
}

struct Bookmark: Codable {
    // Add properties based on your API response
    let id: String?
    // Add other bookmark properties
}

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case serverError(String)
    case networkError(Error)
    case authenticationError(String)
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidData:
            return "Invalid data received"
        case .serverError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationError(let message):
            // Return the exact error message from the API
            return message
        }
    }
}

// Helper class for secure token storage and management
class TokenManager {
    static let shared = TokenManager()
    
    private init() {}
    
    func saveToken(_ token: String) {
        // Use Keychain for more secure storage
        // This is a simple example using UserDefaults
        // For production, consider using a keychain library like KeychainAccess
        UserDefaults.standard.set(token, forKey: "jwtToken")
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "jwtToken")
    }
    
    func deleteToken() {
        UserDefaults.standard.removeObject(forKey: "jwtToken")
    }
    
    func isTokenValid() -> Bool {
        guard let _ = getToken() else {
            return false
        }
        
        if let expiryTimestamp = UserDefaults.standard.double(forKey: "tokenExpiryTimestamp") as Double?,
           expiryTimestamp > 0 {
            // Add a buffer (e.g., 5 minutes) to refresh before actual expiry
            let bufferTime: TimeInterval = 5 * 60
            return Date().timeIntervalSince1970 < (expiryTimestamp - bufferTime)
        }
        
        return false
    }
    
    func getAuthorizationHeader() -> String {
        return "Bearer \(getToken() ?? "")"
    }
}

class APIService {
    func login(with loginData: LoginRequest, completion: @escaping (Result<LoginResponse, Error>) -> Void) {
        // Replace with your actual API endpoint
        guard let url = URL(string: "https://www.breezejirasak.com/api/auth/login") else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(loginData)
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    completion(.failure(APIError.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(APIError.invalidData))
                    return
                }
                
                // Check for error responses based on status code
                if !(200...299).contains(httpResponse.statusCode) {
                    do {
                        // Try to parse error message from API
                        let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: data)
                        print("API error received: \(errorResponse.error)")
                        completion(.failure(APIError.authenticationError(errorResponse.error)))
                    } catch {
                        // If unable to parse error, return the raw response
                        if let rawErrorString = String(data: data, encoding: .utf8) {
                            print("Raw error response: \(rawErrorString)")
                            completion(.failure(APIError.serverError(rawErrorString)))
                        } else {
                            // If we can't even get the raw string, return generic error with status code
                            let message = "Server error with status code: \(httpResponse.statusCode)"
                            completion(.failure(APIError.serverError(message)))
                        }
                    }
                    return
                }
                
                do {
                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                    completion(.success(loginResponse))
                } catch {
                    print("JSON Decoding Error: \(error)")
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
}

// Placeholder for the home view after successful login
// Home view that displays user information after successful login
struct HomeView: View {
    @State private var username: String = UserDefaults.standard.string(forKey: "username") ?? "User"
    @State private var userId: String = UserDefaults.standard.string(forKey: "userId") ?? "N/A"
    @State private var email: String = UserDefaults.standard.string(forKey: "email") ?? "N/A"
    @State private var tokenExpiry: String = UserDefaults.standard.string(forKey: "tokenExpiry") ?? "N/A"
    @State private var token: String = TokenManager.shared.getToken() ?? "N/A"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Welcome back,")
                            .font(.title2)
                            .foregroundColor(.gray)
                        
                        Text(username)
                            .font(.system(size: 32, weight: .bold))
                    }
                    
                    Spacer()
                    
                    // User profile image or placeholder
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(username.prefix(1)).uppercased())
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .padding(.bottom, 10)
                
                // User information card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Information")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    infoRow(title: "User ID:", value: userId)
                    infoRow(title: "Email:", value: email)
                    infoRow(title: "Token Expires:", value: formatExpiryDate(tokenExpiry))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                )
                
                // Token section (collapsible for better UX)
                DisclosureGroup("Session Token") {
                    Text(token)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 5)
                )
                
                // Logout button
                Button(action: {
                    logout()
                }) {
                    Text("Logout")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                .padding(.top, 12)
            }
            .padding()
        }
        .background(Color(UIColor.systemGray6))
        .navigationBarTitle("TripTales", displayMode: .large)
    }
    
    // Helper function to format the expiry date
    private func formatExpiryDate(_ isoString: String) -> String {
        guard let date = ISO8601DateFormatter().date(from: isoString) else {
            return isoString
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
    }
    
    // Helper function for creating info rows
    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .foregroundColor(.black)
            
            Spacer()
        }
    }
    
    // Logout function
    private func logout() {
        // Clear user data
        TokenManager.shared.deleteToken()
        UserDefaults.standard.removeObject(forKey: "userId")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "tokenExpiry")
        UserDefaults.standard.removeObject(forKey: "tokenExpiryTimestamp")
        
        // Present login screen again
        // Note: In a real app, you would navigate back to login
        // This depends on your navigation structure
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
