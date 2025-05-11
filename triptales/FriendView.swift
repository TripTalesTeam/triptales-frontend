import SwiftUI

struct UserProfile: Identifiable, Codable {
    let user_id: String
    let username: String
    let email: String
    let profile_image: String
    
    var id: String { user_id }
}

struct Friend: Identifiable, Codable {
    let friend_id: String
    let user_id: String
    
    var id: String { friend_id }
}

class FriendViewModel: ObservableObject {
    @Published var users: [UserProfile] = []
    @Published var friends: [Friend] = []
    @Published var searchText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @AppStorage("userID") var currentUserId = ""
    
    private let backendURL = ProcessInfo.processInfo.environment["BACKEND_URL"] ?? ""
    
    var filteredUsers: [UserProfile] {
        // Filter out the current user
        let usersWithoutSelf = users.filter { $0.user_id != currentUserId }
        
        if searchText.isEmpty {
            // First sort by friend status, then by username
            return usersWithoutSelf.sorted { (user1, user2) in
                let isFriend1 = isFriend(userId: user1.user_id)
                let isFriend2 = isFriend(userId: user2.user_id)
                
                if isFriend1 == isFriend2 {
                    // If both are friends or both are not friends, sort by username
                    return user1.username.lowercased() < user2.username.lowercased()
                }
                // Show friends first
                return isFriend1 && !isFriend2
            }
        } else {
            // Filter by search text and then sort by friend status
            let filteredBySearch = usersWithoutSelf.filter {
                $0.username.lowercased().contains(searchText.lowercased())
            }
            
            return filteredBySearch.sorted { (user1, user2) in
                let isFriend1 = isFriend(userId: user1.user_id)
                let isFriend2 = isFriend(userId: user2.user_id)
                
                if isFriend1 == isFriend2 {
                    return user1.username.lowercased() < user2.username.lowercased()
                }
                return isFriend1 && !isFriend2
            }
        }
    }
    
    func isFriend(userId: String) -> Bool {
        return friends.contains { $0.friend_id == userId }
    }
    
    func loadUsers(token: String) {
        isLoading = true
        
        guard let url = URL(string: "\(backendURL)/api/users") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Create a custom session configuration
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        
        // Create a session with this configuration
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                do {
                    let decodedUsers = try JSONDecoder().decode([UserProfile].self, from: data)
                    self.users = decodedUsers
                } catch {
                    self.errorMessage = "Failed to decode users: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func loadFriends(token: String) {
        isLoading = true
        
        guard let url = URL(string: "\(backendURL)/api/friends") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Create a custom session configuration
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        
        // Create a session with this configuration
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self.errorMessage = "No data received"
                    return
                }
                
                do {
                    let decodedFriends = try JSONDecoder().decode([Friend].self, from: data)
                    self.friends = decodedFriends
                } catch {
                    self.errorMessage = "Failed to decode friends: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    func addFriend(userId: String, token: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(backendURL)/api/friends") else {
            errorMessage = "Invalid URL"
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: String] = ["friend_id": userId]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            errorMessage = "Failed to encode request body: \(error.localizedDescription)"
            completion(false)
            return
        }
        
        // Create a custom session configuration
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        
        // Create a session with this configuration
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response"
                    completion(false)
                    return
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    // If successful, reload friends
                    self.loadFriends(token: token)
                    completion(true)
                } else {
                    self.errorMessage = "Failed to add friend. Status code: \(httpResponse.statusCode)"
                    completion(false)
                }
            }
        }.resume()
    }
    
    func removeFriend(userId: String, token: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(backendURL)/api/friends/\(userId)") else {
            errorMessage = "Invalid URL"
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        // Create a custom session configuration
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(token)"]
        
        // Create a session with this configuration
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response"
                    completion(false)
                    return
                }
                
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 204 {
                    // If successful, reload friends
                    self.loadFriends(token: token)
                    completion(true)
                } else {
                    self.errorMessage = "Failed to remove friend. Status code: \(httpResponse.statusCode)"
                    completion(false)
                }
            }
        }.resume()
    }
}

struct UserCardView: View {
    let user: UserProfile
    let isFriend: Bool
    let addFriendAction: () -> Void
    let removeFriendAction: () -> Void
    
    var body: some View {
        // Friend status indicator at the top of card if is a friend
        VStack(spacing: 0) {
        HStack {
            // Profile image
            if !user.profile_image.isEmpty {
                AsyncImage(url: URL(string: user.profile_image)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            // Username and email
            VStack(alignment: .leading) {
                Text(user.username)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Add friend button or friend status indicator
            if isFriend {
                Button(action: removeFriendAction) {
                    Image(systemName: "person.fill.checkmark")
                        .foregroundColor(.green)
                        .font(.title2)
                }
            } else {
                Button(action: addFriendAction) {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.blue)
                        .font(.title2)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 2, x: 0, y: 1)
        .navigationBarBackButtonHidden(true)
        }
    }
}

struct FriendView: View {
    @AppStorage("token") var token = ""
    @StateObject private var viewModel = FriendViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background color - applied to entire view
            Color(red: 0.98, green: 0.96, blue: 0.93)
                .edgesIgnoringSafeArea(.all)
            VStack() {
                // MARK: Header
                HeaderView(title: "Find Friends") {
                    presentationMode.wrappedValue.dismiss()
                }
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search users", text: $viewModel.searchText)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 2)
                
                ScrollView {
                    if viewModel.isLoading {
                        ProgressView()
                        .padding()
                    } else if !viewModel.errorMessage.isEmpty {
                        VStack {
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.red)
                            Text(viewModel.errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") {
                                viewModel.loadUsers(token: token)
                                viewModel.loadFriends(token: token)
                            }
                            .padding()
                        }
                        .padding()
                    } else if viewModel.filteredUsers.isEmpty {
                        VStack {
                            if viewModel.searchText.isEmpty {
                                Text("No users found")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            } else {
                                Text("No users matching '\(viewModel.searchText)'")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredUsers) { user in
                                    UserCardView(
                                        user: user,
                                        isFriend: viewModel.isFriend(userId: user.user_id),
                                        addFriendAction: {
                                            viewModel.addFriend(userId: user.user_id, token: token) { success in
                                                if success {
                                                    // You could add feedback here if needed
                                                }
                                            }
                                        },
                                        removeFriendAction: {
                                            viewModel.removeFriend(userId: user.user_id, token: token) { success in
                                                if success {
                                                    // You could add feedback here if needed
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
        }
            .onAppear {
                viewModel.loadUsers(token: token)
                viewModel.loadFriends(token: token)
            }
            .background(Color(red: 0.98, green: 0.96, blue: 0.93))
            .edgesIgnoringSafeArea(.bottom)
            .navigationBarBackButtonHidden(true)
    }
}
