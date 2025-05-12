import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            TabView(selection: $selectedTab) {
                FeedView()
                    .tag(0)
                
                JournalView()
                    .tag(1)
                
                ProfileView()
                    .tag(2)
            }
            .background(Color.white)
            
            // Custom Tab Bar
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    tabBarItem(imageName: "house.fill", title: "Feed", tag: 0)
                    tabBarItem(imageName: "pencil", title: "Journal", tag: 1)
                    tabBarItem(imageName: "person", title: "Profile", tag: 2)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 22)
                .background(Color.white)
                .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: -2)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    func tabBarItem(imageName: String, title: String, tag: Int) -> some View {
        VStack(spacing: 5) {
            Image(systemName: imageName)
                .foregroundColor(selectedTab == tag ? .orange : .gray)
            
            Text(title)
                .font(.caption)
                .foregroundColor(selectedTab == tag ? .orange : .gray)
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            withAnimation {
                selectedTab = tag
            }
        }
    }
}

#Preview("Main Tab View") {
    MainTabView()
}

#Preview("Dark Mode") {
    MainTabView()
        .preferredColorScheme(.dark)
}
