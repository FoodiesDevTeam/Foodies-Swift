import SwiftUI

struct ChatView: View {
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var pulsate = false
    @State private var activeMatches: [UserDefaultsManager.Match] = []
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.8), Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ChatHeaderView(isSearching: $isSearching)
                
                if activeMatches.isEmpty {
                    ChatEmptyStateView()
                } else {
                    ChatListView(activeMatches: activeMatches)
                }
            }
        }
        .onAppear {
            loadActiveMatches()
        }
    }
    
    private func loadActiveMatches() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            let matches = UserDefaultsManager.shared.getActiveMatches(for: currentUser.username)
            // Her partner için sadece bir eşleşme kutucuğu göster
            var uniquePartners = Set<String>()
            self.activeMatches = matches.filter { match in
                let partner = match.user1 == currentUser.username ? match.user2 : match.user1
                if uniquePartners.contains(partner) {
                    return false
                } else {
                    uniquePartners.insert(partner)
                    return true
                }
            }
        }
    }
}

private struct ChatHeaderView: View {
    @Binding var isSearching: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.pink, .purple, .blue],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea(edges: .top)
            HStack {
                Spacer()
                Text(LanguageManager.shared.localizedString("Messages"))
                    .font(.title2)
                    .bold()
                    .foregroundStyle(Constants.Design.mainGradient)
                Spacer()
                Button(action: {
                    withAnimation {
                        isSearching.toggle()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 50)
    }
}

private struct ChatEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Henüz aktif eşleşmeniz yok")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.7))
    }
}

private struct ChatListView: View {
    let activeMatches: [UserDefaultsManager.Match]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Text("Aktif Eşleşmeler")
                        .font(.headline)
                        .foregroundStyle(Constants.Design.mainGradient)
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.7))
                // Chat List
                ForEach(activeMatches) { match in
                    if let currentUser = UserDefaultsManager.shared.getCurrentUser(),
                       let partnerUser = UserDefaultsManager.shared.getUser(username: match.user1 == currentUser.username ? match.user2 : match.user1) {
                        
                        let chatPartnerUser = User(from: partnerUser)
                        let currentChatUser = User(from: currentUser)
                        
                        NavigationLink(
                            destination: MessagesView(viewModel: ChatViewModel(currentUser: currentChatUser, partner: chatPartnerUser)),
                            label: {
                                ChatRow(match: match, partnerUser: partnerUser)
                            }
                        )
                    }
                }
                .background(Color.white.opacity(0.7))
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }
}

struct ChatRow: View {
    let match: UserDefaultsManager.Match
    let partnerUser: UserDefaultsManager.User
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let photoData = partnerUser.photos?.first,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(partnerUser.personalInfo?.name.prefix(1) ?? partnerUser.username.prefix(1))
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }
            
            // Chat Info
            VStack(alignment: .leading, spacing: 4) {
                Text(partnerUser.personalInfo?.name ?? partnerUser.username)
                    .font(.headline)
                Text("Eşleşme tarihi: \(formatDate(match.timestamp))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Time
            Text(formatDate(match.timestamp))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
