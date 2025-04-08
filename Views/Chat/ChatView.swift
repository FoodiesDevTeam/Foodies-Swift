import SwiftUI

struct ChatView: View {
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var chats: [UserDefaultsManager.Message] = []
    @State private var pulsate = false
    
    var filteredChats: [UserDefaultsManager.Message] {
        if searchText.isEmpty {
            return chats
        }
        return chats.filter { chat in
            chat.senderName.localizedCaseInsensitiveContains(searchText) ||
            chat.content.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with animation
            ZStack {
                // Header background
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 120)
                
                VStack {
                    HStack {
                        Button(action: {
                            // Back action
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        
                        Spacer()
                        
                        Text("Mesajlar")
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
                    .padding(.top, 60)
                    
                    if isSearching {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField("Mesajlarda ara...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .autocapitalization(.none)
                        }
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
            .offset(y: pulsate ? -10 : 0)
            .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulsate)
            .onAppear {
                self.pulsate.toggle()
            }
            
            // Content
            ScrollView {
                VStack(spacing: 0) {
                    // Recent Label
                    HStack {
                        Text("Son Mesajlar")
                            .font(.headline)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    
                    // Chat List
                    LazyVStack(spacing: 0) {
                        ForEach(filteredChats) { chat in
                            NavigationLink(destination: ChatDetailView(chat: chat)) {
                                ChatRow(chat: chat)
                            }
                            Divider()
                                .padding(.leading)
                        }
                    }
                    .background(Color.white.opacity(0.7))
                }
            }
            .background(Color.white)
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            loadChats()
        }
    }
    
    private func loadChats() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            let filter = UserDefaultsManager.MessageFilter(userId: currentUser.username)
            chats = UserDefaultsManager.shared.getMessages(filter: filter)
                .sorted { $0.timestamp > $1.timestamp }
        }
    }
}

struct ChatRow: View {
    let chat: UserDefaultsManager.Message
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Image
            if let photoData = chat.senderPhotoData,
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
                        Text(chat.senderName.prefix(1))
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
            }
            
            // Chat Info
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.senderName)
                    .font(.headline)
                Text(chat.content)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Time and Unread Count
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(chat.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if !chat.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                }
            }
        }
        .padding()
        .background(Color.white)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ChatDetailView: View {
    let chat: UserDefaultsManager.Message
    @State private var messageText = ""
    @State private var messages: [UserDefaultsManager.Message] = []
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
                        if let photoData = chat.senderPhotoData,
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
                                    Text(chat.senderName.prefix(1))
                                        .font(.title3)
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        Text(chat.senderName)
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
                    ForEach(messages) { message in
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
            loadMessages()
        }
    }
    
    private func loadMessages() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            messages = UserDefaultsManager.shared.getConversation(between: currentUser.username, and: chat.senderId)
        }
    }
    
    private func sendMessage() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            UserDefaultsManager.shared.sendMessage(
                senderId: currentUser.username,
                receiverId: chat.senderId,
                content: messageText
            )
            messageText = ""
            loadMessages()
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
