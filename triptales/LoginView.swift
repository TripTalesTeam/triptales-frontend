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
    @EnvironmentObject var session: SessionManager
    @State private var username = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @AppStorage("isLoggedIn") var isLoggedIn = false
    @State private var isLoading = false
    
    @AppStorage("token") var token = ""
    @AppStorage("userID") var userID = ""
    @AppStorage("username") var savedUsername = ""
    @AppStorage("email") var savedEmail = ""
    @AppStorage("expireAt") var expireAt = ""
    @AppStorage("profileImageUrl") var profileImageUrl = ""
    
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
                        .foregroundColor(.black)
                    
                    VStack(spacing: 16) {
                        // Username field
                        TextField("Username", text: $username)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .foregroundColor(.black)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        
                        // Password field
                        SecureField("Password", text: $password)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .foregroundColor(.black)
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 5)
                        
                        // Login button
                        Button(action: {
                            loginUser()
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
                                    .foregroundColor(.blue)
                            }
                            .padding(.trailing, 24)
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Login Failed"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .background(Color(red: 0.98, green: 0.96, blue: 0.93))
            .navigationBarHidden(true)
            // Navigation link is hidden but activated when login is successful
            .background(
                NavigationLink(destination: FeedView(), isActive: $isLoggedIn) {
                    EmptyView().navigationBarBackButtonHidden(true)
                }
            )
        }
    }
    
    func loginUser() {
        let parameters: [String: Any] = [
            "username": username,
            "password": password
        ]
        
        guard !username.isEmpty && !password.isEmpty else {
            self.alertMessage = "Username and password cannot be empty"
            self.showAlert = true
            return
        }
        
        self.isLoading = true
        
        guard let url = URL(string: "https://www.breezejirasak.com/api/auth/login") else {
            self.alertMessage = "Invalid URL"
            self.showAlert = true
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            self.alertMessage = "Failed to encode parameters"
            self.showAlert = true
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    return
                }
                
                guard let data = data else {
                    self.alertMessage = "No data received from server"
                    self.showAlert = true
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let token = json["token"] as? String,
                       let expire = json["expire_at"] as? String,
                       let user = json["user"] as? [String: Any],
                       let id = user["user_id"] as? String,
                       let uname = user["username"] as? String,
                       let profilePicURLString = user["profile_image"] as? String,
                       let mail = user["email"] as? String {
                        
                        session.login(token: token, username: uname)
                        self.token = token
                        self.userID = id
                        self.savedUsername = uname
                        self.savedEmail = mail
                        self.expireAt = expire
                        self.profileImageUrl = profilePicURLString
                        self.isLoggedIn = true
                    } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let errorMsg = json["error"] as? String {
                        self.alertMessage = errorMsg
                        self.showAlert = true
                    } else {
                        self.alertMessage = "Unexpected response format"
                        self.showAlert = true
                    }
                } catch {
                    self.alertMessage = "Failed to decode server response"
                    self.showAlert = true
                }
            }
        }.resume()
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
    
    struct LoginView_Previews: PreviewProvider {
        static var previews: some View {
            LoginView()
        }
    }
}
