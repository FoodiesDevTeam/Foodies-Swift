import Foundation
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var currentUser: User
    var partner: User
    private var conversationId: String? // UUID yerine String kullanacağız
    // private let chatService = FirebaseChatService() // KALDIRILDI
    
    init(currentUser: User, partner: User) {
        self.currentUser = currentUser
        self.partner = partner
        print("ChatViewModel initialized for \(self.currentUser.username) <-> \(self.partner.username)")
        
        Task {
            await setupConversationAndLoadMessages()
        }
    }
    
    private func setupConversationAndLoadMessages() async {
        let currentUserStringId = currentUser.id
        let partnerStringId = partner.id
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Firebase yerine UserDefaultsManager ile konuşma ve mesajları al
            self.conversationId = nil // Artık conversationId kullanılmıyor
            await loadMessages()
            // subscribeToMessages() // KALDIRILDI
        } catch {
            errorMessage = "Sohbet oluşturulurken/alınırken hata oluştu: \(error.localizedDescription)"
            print("Error setting up conversation: \(error)")
        }
        isLoading = false
    }
    
    @MainActor
    func loadMessages() async {
        let currentUserStringId = currentUser.id
        let partnerStringId = partner.id
        let userDefaultsMessages = UserDefaultsManager.shared.getConversation(between: currentUserStringId, and: partnerStringId)
        self.messages = userDefaultsMessages.map { msg in
            Message(
                id: msg.id,
                conversationId: "", // UserDefaultsManager.Message'da conversationId yoksa boş bırak
                senderId: msg.senderId,
                receiverId: msg.receiverId,
                content: msg.content,
                createdAt: msg.timestamp,
                isRead: msg.isRead
            )
        }
    }
    
    @MainActor
    func sendMessage(content: String) async {
        let currentUserStringId = currentUser.id
        let partnerStringId = partner.id
        // UserDefaultsManager ile mesaj gönder
        UserDefaultsManager.shared.sendMessage(senderId: currentUserStringId, receiverId: partnerStringId, content: content)
        await loadMessages()
    }
    
    func markMessageAsRead(_ message: Message?) async {
        guard let msg = message else { return }
        print("Marking message \(msg.id) as read...")
        UserDefaultsManager.shared.markMessageAsRead(messageId: msg.id)
        if let index = messages.firstIndex(where: { $0.id == msg.id }) {
            DispatchQueue.main.async {
                self.messages[index].isRead = true
            }
        }
    }
    
    deinit {
        print("ChatViewModel deinitialized.")
    }
} 
