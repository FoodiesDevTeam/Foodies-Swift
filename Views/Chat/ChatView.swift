import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var pulsate = false
    @State private var activeMatches: [UserDefaultsManager.Match] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                // Header background
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 100)
                .edgesIgnoringSafeArea(.top)
                
                // Header Content
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        
                        Text(LanguageManager.shared.localizedString("Messages"))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
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
                    .padding(.top, 50)
                }
            }
            
            // Content
            if activeMatches.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "message.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Henüz aktif eşleşmeniz yok")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Recent Label
                        HStack {
                            Text("Aktif Eşleşmeler")
                                .font(.headline)
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.7))
                        
                        // Chat List
                        LazyVStack(spacing: 0) {
                            ForEach(activeMatches) { match in
                                if let currentUser = UserDefaultsManager.shared.getCurrentUser(),
                                   let partnerUsername = UserDefaultsManager.shared.getMatchPartner(for: currentUser.username, in: match),
                                   let partnerUser = UserDefaultsManager.shared.getUser(username: partnerUsername) {
                                    NavigationLink(destination: ChatDetailView(matchedUser: partnerUser, viewModel: viewModel)) {
                                        ChatRow(match: match, partnerUser: partnerUser)
                                    }
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        .background(Color.white.opacity(0.7))
                    }
                }
                .background(Color.white)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            loadActiveMatches()
        }
    }
    
    private func loadActiveMatches() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            activeMatches = UserDefaultsManager.shared.getActiveMatches(for: currentUser.username)
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

struct ChatDetailView: View {
    let matchedUser: UserDefaultsManager.User
    @ObservedObject var viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var pulsate = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    colors: [.purple, .blue, .pink],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 100)
                
                VStack {
                    HStack {
                        // Profile Image
                        if let photoData = matchedUser.photos?.first,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(matchedUser.personalInfo?.name.prefix(1) ?? matchedUser.username.prefix(1))
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        Text(matchedUser.personalInfo?.name ?? matchedUser.username)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 50)
                }
            }
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Message Input
            HStack(spacing: 12) {
                TextField("Mesajınızı yazın...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(messageText.isEmpty ? Color.gray : Color.blue)
                        .clipShape(Circle())
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
            .background(Color.white)
            .shadow(radius: 2)
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            // Mesajı okundu olarak işaretle
            viewModel.markMessageAsRead(viewModel.messages.last!)
        }
    }
    
    private func sendMessage() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            viewModel.sendMessage(
                senderId: currentUser.username,
                receiverId: matchedUser.username,
                content: messageText
            )
            messageText = ""
        }
    }
}

struct MessageBubble: View {
    let message: UserDefaultsManager.Message
    
    var isCurrentUser: Bool {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            return message.senderId == currentUser.username
        }
        return false
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            Text(message.content)
                .padding()
                .background(isCurrentUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isCurrentUser ? .white : .black)
                .cornerRadius(20)
            
            if !isCurrentUser { Spacer() }
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
