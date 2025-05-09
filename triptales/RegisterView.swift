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
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var showAlert = false
    @State private var alertMessage = ""

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

                Group {
                    CustomInputField(title: "Username", text: $username)
                    CustomInputField(title: "Email", text: $email, placeholder: "example@email.com")
                    CustomInputField(title: "Password", text: $password, isSecure: true)
                    CustomInputField(title: "Confirm Password", text: $confirmPassword, isSecure: true)
                }
                .padding(.horizontal, 24)

                Button(action: {
                    handleRegister()
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
                            .foregroundColor(.white)
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
    }

    func handleRegister() {
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
            alertMessage = "Invalid API URL."
            showAlert = true
            return
        }

        let parameters: [String: String] = [
            "username": username,
            "password": password,
            "confirm_password": confirmPassword,
            "email": email,
            "profile_image": ""
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters) else {
            alertMessage = "Failed to encode data."
            showAlert = true
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    alertMessage = "Network error: \(error.localizedDescription)"
                    showAlert = true
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      let data = data else {
                    alertMessage = "Invalid server response."
                    showAlert = true
                    return
                }

                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

                    if let errorMessage = json?["error"] as? String {
                        alertMessage = errorMessage
                        showAlert = true
                        return
                    }

                    if let token = json?["token"] as? String {
                        // Registration successful
                        alertMessage = "Registration successful!"
                        showAlert = true
                        // TODO: Navigate to login view or store token
                        print("Token: \(token)")
                        return
                    }

                    alertMessage = "Unexpected response from server."
                    showAlert = true
                } catch {
                    alertMessage = "Failed to parse server response."
                    showAlert = true
                }
            }
        }.resume()
    }
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
                    .cornerRadius(12)
            } else {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }
}


#Preview {
    RegisterView()
}
