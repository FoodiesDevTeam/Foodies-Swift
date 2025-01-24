import SwiftUI

struct ChatView: View {
    @State private var searchText = ""
    @State private var chats: [UserDefaultsManager.Message] = []
    
    var filteredChats: [UserDefaultsManager.Message] {
        if searchText.isEmpty {
            return chats
        }
        return chats.filter { chat in
            chat.senderName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                VStack(spacing: 16) {
                    HStack {
                        Button(action: {
                            // Back action
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                        
                        Text("Chats")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            // Search action
                        }) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        }
                    }
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                }
                .padding()
            }
            .frame(height: 120)
            
            // Recent Label
            HStack {
                Text("Recent")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
            }
            .padding()
            
            // Chat List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredChats) { chat in
                        NavigationLink(destination: ChatDetailView(chat: chat)) {
                            ChatRow(chat: chat)
                        }
                        Divider()
                            .padding(.leading)
                    }
                }
            }
        }
        .onAppear {
            loadChats()
        }
    }
    
    private func loadChats() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            chats = UserDefaultsManager.shared.getMessages(filter: UserDefaultsManager.MessageFilter())
                .filter { $0.fromUser != currentUser.username }
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
            }
            
            // Chat Info
            VStack(alignment: .leading, spacing: 4) {
                Text(chat.senderName)
                    .font(.headline)
                Text(chat.text)
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
                
                if Int.random(in: 0...1) == 1 { // Simulating unread messages
                    Circle()
                        .fill(Color.red)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Text("1")
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
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
                    }
                    
                    VStack(alignment: .leading) {
                        Text(chat.senderName)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        // More options
                    }) {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                }
                .padding()
            }
            .frame(height: 80)
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Message Input
            HStack(spacing: 12) {
                Button(action: {
                    // Add attachment
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                }
                
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(messageText.isEmpty ? .gray : .purple)
                }
            }
            .padding()
            .background(Color.white)
            .shadow(radius: 2)
        }
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            messages = UserDefaultsManager.shared.getMessages(filter: UserDefaultsManager.MessageFilter())
                .filter { $0.fromUser == chat.fromUser || $0.fromUser == currentUser.username }
                .sorted { $0.timestamp < $1.timestamp }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty,
              let currentUser = UserDefaultsManager.shared.getCurrentUser() else {
            return
        }
        
        let message = UserDefaultsManager.Message(
            id: UUID().uuidString,
            fromUser: currentUser.username,
            text: messageText,
            photoData: nil,
            timestamp: Date()
        )
        
        UserDefaultsManager.shared.saveMessage(message)
        messageText = ""
        loadMessages()
    }
}

struct MessageBubble: View {
    let message: UserDefaultsManager.Message
    
    var isCurrentUser: Bool {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            return message.fromUser == currentUser.username
        }
        return false
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(isCurrentUser ? Color.purple : Color.gray.opacity(0.2))
                    .foregroundColor(isCurrentUser ? .white : .black)
                    .cornerRadius(16)
                
                if let photoData = message.photoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200, maxHeight: 200)
                        .cornerRadius(12)
                }
                
                Text(formatDate(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
