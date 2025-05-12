//
//  RegisterView.swift
//  triptales
//
//  Created by Jiratchaya Thongsuthum on 9/5/2568 BE.
//

import SwiftUI

struct RegisterView: View {
    var body: some View {
        NavigationStack {
            RegisterFormContent()
                .navigationBarBackButtonHidden(true)
        }
    }
}

struct RegisterFormContent: View {
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var email = ""
    @State private var profileImage = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var session: SessionManager
    @AppStorage("isLoggedIn") var isRegistered = false
    
    @AppStorage("token") var token = ""
    @AppStorage("userID") var userID = ""
    @AppStorage("username") var savedUsername = ""
    @AppStorage("email") var savedEmail = ""
    
    var body: some View {
        ZStack {
            Color(red: 244/255, green: 242/255, blue: 233/255)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer().frame(height: 40)
                
                Text("Register")
                    .font(.system(size: 28, weight: .bold))
                    .padding(.top, 180)
                    .padding(.bottom, 10)
                    .foregroundColor(.black)
                
                Group {
                    CustomInputField(title: "Username", text: $username)
                    CustomInputField(title: "Email", text: $email, placeholder: "example@email.com")
                    CustomInputField(title: "Password", text: $password, isSecure: true)
                    CustomInputField(title: "Confirm Password", text: $confirmPassword, isSecure: true)
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    registerUser()
                }) {
                    Text("Submit")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.orange)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange, lineWidth: 1.5)
                        )
                        .cornerRadius(12)
                        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 24)
                .padding(.top, 10)
                
                HStack {
                    Spacer()
                    NavigationLink(destination: LoginView()) {
                        Text("Login?")
                            .font(.callout)
                            .foregroundColor(.blue)
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 8)
                }
                
                Spacer()
                
                GeometryReader { geo in
                    Circle()
                        .fill(Color.orange)
                        .frame(width: geo.size.width * 2, height: geo.size.width * 2)
                        .offset(x: -geo.size.width / 2, y: geo.size.height / 2)
                }
                .ignoresSafeArea(edges: .bottom)
                .frame(height: 200)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Registeration"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .background(Color(red: 0.98, green: 0.96, blue: 0.93))
        .navigationBarHidden(true)
        // Navigation link is hidden but activated when login is successful
        .background(
            NavigationLink(destination: FeedView(), isActive: $isRegistered) {
                EmptyView().navigationBarBackButtonHidden(true)
            }
        )
    }
    
    struct CustomInputField: View {
        var title: String
        @Binding var text: String
        var placeholder: String = ""
        var isSecure: Bool = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.black)
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                } else {
                    TextField(placeholder, text: $text)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    func registerUser() {
        let parameters: [String: Any] = [
            "username": username,
            "password": password,
            "confirm_password": confirmPassword,
            "email": email,
            "profile_image": profileImage // Make sure this is a base64 string or handled correctly on backend
        ]
        
        // Validate inputs
        guard !username.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty else {
            alertMessage = "Please fill in all fields."
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match."
            showAlert = true
            return
        }

        guard let url = URL(string: "https://www.breezejirasak.com/api/auth/register") else {
            alertMessage = "Invalid URL."
            showAlert = true
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            alertMessage = "Failed to encode parameters."
            showAlert = true
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.alertMessage = error.localizedDescription
                    self.showAlert = true
                    return
                }

                guard let data = data else {
                    self.alertMessage = "No data received from server."
                    self.showAlert = true
                    return
                }

                print("DATA: \(String(data: data, encoding: .utf8) ?? "No response data")")

                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let token = json["token"] as? String,
                       let user = json["user"] as? [String: Any],
                       let id = user["user_id"] as? String,
                       let uname = user["username"] as? String,
                       let mail = user["email"] as? String {
                        
                        session.login(token: token, username: uname)

                        self.token = token
                        self.userID = id
                        self.savedUsername = uname
                        self.savedEmail = mail
                        self.isRegistered = true
                    } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let errorMsg = json["error"] as? String {
                        self.alertMessage = errorMsg
                        self.showAlert = true
                    } else {
                        self.alertMessage = "Unexpected response format."
                        self.showAlert = true
                    }
                } catch {
                    self.alertMessage = "Failed to decode server response."
                    self.showAlert = true
                }
            }
        }.resume()
    }

    
    
    #Preview {
        RegisterView()
    }
}
