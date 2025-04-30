import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [UserDefaultsManager.Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var currentUsername: String?
    private var partnerUsername: String?
    
    init() {
        print("ChatViewModel initialized (generic)")
    }
    
    init(currentUser: UserDefaultsManager.User, partner: UserDefaultsManager.User) {
        self.currentUsername = currentUser.username
        self.partnerUsername = partner.username
        print("ChatViewModel initialized for \(currentUser.username) <-> \(partner.username)")
        loadMessages()
    }
    
    func loadMessages() {
        guard let cu = currentUsername, let pu = partnerUsername else { return }
        print("Loading messages between \(cu) and \(pu)...")
        isLoading = true
        errorMessage = nil
        
        messages = UserDefaultsManager.shared.getConversation(between: cu, and: pu)
            .sorted { $0.timestamp < $1.timestamp }
        
        print("Loaded \(messages.count) messages.")
        isLoading = false
    }
    
    func sendMessage(senderId: String, receiverId: String, content: String) {
        guard !content.isEmpty else { return }
        print("Sending message from \(senderId) to \(receiverId)...")
        
        UserDefaultsManager.shared.sendMessage(
            senderId: senderId,
            receiverId: receiverId,
            content: content
        )
        
        loadMessages()
    }
    
    func markMessageAsRead(_ message: UserDefaultsManager.Message?) {
        guard let msg = message else { return }
        print("Marking message \(msg.id) as read...")
        
        var updatedMessage = msg
        updatedMessage.isRead = true
        
        // UserDefaultsManager'da mesajı güncelle
        // Not: Bu fonksiyon UserDefaultsManager'a eklenmeli
        // UserDefaultsManager.shared.updateMessage(updatedMessage)
        
        loadMessages()
    }
} 