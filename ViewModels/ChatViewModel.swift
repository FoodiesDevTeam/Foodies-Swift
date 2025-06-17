import Foundation
import SwiftUI
import FirebaseDatabase

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var currentUser: User
    var partner: User
    private var conversationId: String? // UUID yerine String kullanacağız
    private let chatService = FirebaseChatService()
    
    init(currentUser: User, partner: User) {
        self.currentUser = currentUser
        self.partner = partner
        print("ChatViewModel initialized for \(self.currentUser.username) <-> \(self.partner.username)")
        
        Task {
            await setupConversationAndLoadMessages()
        }
    }
    
    private func setupConversationAndLoadMessages() async {
        guard let currentUserStringId = currentUser.id, // String olarak alıyoruz
              let partnerStringId = partner.id else {
            errorMessage = "Geçersiz kullanıcı ID'leri."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let conversation = try await chatService.getOrCreateConversation(user1Id: currentUserStringId, user2Id: partnerStringId)
            self.conversationId = conversation.id
            await loadMessages()
            subscribeToMessages()
        } catch {
            errorMessage = "Sohbet oluşturulurken/alınırken hata oluştu: \(error.localizedDescription)"
            print("Error setting up conversation: \(error)")
        }
        isLoading = false
    }
    
    func loadMessages() async {
        guard let conversationId = conversationId else { return }
        print("Loading messages for conversation \(conversationId)...")
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedMessages = try await chatService.getMessages(conversationId: conversationId)
            DispatchQueue.main.async {
                self.messages = fetchedMessages
            }
            print("Loaded \(fetchedMessages.count) messages.")
        } catch {
            errorMessage = "Mesajlar yüklenirken hata oluştu: \(error.localizedDescription)"
            print("Error loading messages: \(error)")
        }
        isLoading = false
    }
    
    func sendMessage(content: String) async {
        guard let conversationId = conversationId,
              let currentUserStringId = currentUser.id,
              let partnerStringId = partner.id else { return }
        
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        print("Sending message from \(currentUser.username) to \(partner.username)...")
        
        do {
            _ = try await chatService.sendMessage(
                conversationId: conversationId,
                senderId: currentUserStringId,
                receiverId: partnerStringId,
                content: trimmed
            )
        } catch {
            errorMessage = "Mesaj gönderilirken hata oluştu: \(error.localizedDescription)"
            print("Error sending message: \(error)")
        }
    }
    
    func markMessageAsRead(_ message: Message?) async {
        guard let msg = message, let conversationId = conversationId else { return }
        print("Marking message \(msg.id) as read...")
        
        do {
            try await chatService.markMessageAsRead(conversationId: conversationId, messageId: msg.id)
            // UI'da mesajın okundu olarak güncellenmesi için messages dizisini güncelle
            if let index = messages.firstIndex(where: { $0.id == msg.id }) {
                DispatchQueue.main.async {
                    self.messages[index].isRead = true
                }
            }
        } catch {
            errorMessage = "Mesaj okundu olarak işaretlenirken hata oluştu: \(error.localizedDescription)"
            print("Error marking message as read: \(error)")
        }
    }
    
    // MARK: - Realtime Subscription
    
    private func subscribeToMessages() {
        guard let conversationId = conversationId else { return }
        print("Subscribing to messages for conversation \(conversationId)...")
        chatService.subscribeToMessages(conversationId: conversationId) { [weak self] newMessage in
            DispatchQueue.main.async {
                if !(self?.messages.contains(where: { $0.id == newMessage.id }) ?? true) {
                    self?.messages.append(newMessage)
                }
            }
        }
    }
    
    deinit {
        print("ChatViewModel deinitialized. Unsubscribing from messages.")
        chatService.unsubscribeFromMessages()
    }
} 