import Foundation
import FirebaseDatabase
import FirebaseCore

class FirebaseChatService {
    private let databaseRef: DatabaseReference
    private var messagesHandle: DatabaseHandle?
    
    init() {
        // Firebase'in zaten başlatılmış olduğunu varsayıyoruz (örneğin AppDelegate'de)
        self.databaseRef = Database.database().reference()
    }
    
    // MARK: - Conversations
    
    // İki kullanıcı arasındaki sohbeti alır veya oluşturur
    func getOrCreateConversation(user1Id: String, user2Id: String) async throws -> Conversation {
        // Firebase'de conversation_id oluşturmak için kullanıcı ID'lerini sıralıyoruz
        let orderedUserIds = [user1Id, user2Id].sorted()
        let conversationKey = orderedUserIds.joined(separator: "_")
        
        let conversationsRef = databaseRef.child("conversations")
        let conversationRef = conversationsRef.child(conversationKey)
        
        return try await withCheckedThrowingContinuation { continuation in
            conversationRef.getData(completion: { error, snapshot in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                if let value = snapshot?.value as? [String: Any] {
                    // Sohbet zaten varsa
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: value)
                        let conversation = try JSONDecoder().decode(Conversation.self, from: jsonData)
                        continuation.resume(returning: conversation)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    // Sohbet yoksa yeni bir tane oluştur
                    let newConversation = Conversation(
                        id: conversationKey,
                        user1Id: orderedUserIds[0],
                        user2Id: orderedUserIds[1],
                        createdAt: Date(),
                        lastMessageContent: nil,
                        lastMessageSentAt: nil
                    )
                    
                    do {
                        let encodedData = try JSONEncoder().encode(newConversation)
                        let json = try JSONSerialization.jsonObject(with: encodedData, options: .allowFragments) as? [String: Any]
                        
                        conversationRef.setValue(json) { error, _ in
                            if let error = error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume(returning: newConversation)
                            }
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            })
        }
    }
    
    // MARK: - Messages
    
    // Bir sohbetteki mesajları alır
    func getMessages(conversationId: String) async throws -> [Message] {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        
        return try await withCheckedThrowingContinuation { continuation in
            messagesRef.observeSingleEvent(of: .value) { snapshot in
                guard let messagesDict = snapshot.value as? [String: Any] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var messages: [Message] = []
                for (_, messageValue) in messagesDict {
                    if let messageData = messageValue as? [String: Any] {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: messageData)
                            let message = try JSONDecoder().decode(Message.self, from: jsonData)
                            messages.append(message)
                        } catch {
                            print("Error decoding message: \(error)")
                        }
                    }
                }
                continuation.resume(returning: messages.sorted { $0.createdAt < $1.createdAt })
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }
    
    // Mesaj gönderir
    func sendMessage(conversationId: String, senderId: String, receiverId: String, content: String) async throws -> Message {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        let newMessageRef = messagesRef.childByAutoId() // Firebase otomatik ID oluşturur
        
        let newMessage = Message(
            id: newMessageRef.key ?? UUID().uuidString,
            conversationId: conversationId,
            senderId: senderId,
            receiverId: receiverId,
            content: content,
            createdAt: Date(),
            isRead: false
        )
        
        let encodedData = try JSONEncoder().encode(newMessage)
        let json = try JSONSerialization.jsonObject(with: encodedData, options: .allowFragments) as? [String: Any]
        
        return try await withCheckedThrowingContinuation { continuation in
            newMessageRef.setValue(json) { error, _ in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    Task { // `Task` içinde async olarak güncelle
                        await updateLastMessageInConversation(conversationId: conversationId, content: content, sentAt: newMessage.createdAt)
                    }
                    continuation.resume(returning: newMessage)
                }
            }
        }
    }
    
    // Sohbetin son mesaj bilgilerini günceller
    private func updateLastMessageInConversation(conversationId: String, content: String, sentAt: Date) async {
        let conversationRef = databaseRef.child("conversations").child(conversationId)
        do {
            _ = try await conversationRef.updateChildValues([
                "lastMessageContent": content,
                "lastMessageSentAt": sentAt.timeIntervalSince1970 // Date'i Unix timestamp olarak kaydet
            ])
        } catch {
            print("Sohbet son mesaj güncellenirken hata: \(error)")
        }
    }
    
    func markMessageAsRead(conversationId: String, messageId: String) async throws {
        let messageRef = databaseRef.child("conversations").child(conversationId).child("messages").child(messageId)
        try await messageRef.updateChildValues(["isRead": true])
    }
    
    // MARK: - Realtime Subscription
    
    func subscribeToMessages(conversationId: String, onMessageReceived: @escaping (Message) -> Void) {
        let messagesRef = databaseRef.child("conversations").child(conversationId).child("messages")
        
        // Yeni mesajları dinle
        messagesHandle = messagesRef.observe(.childAdded) { snapshot in
            guard let value = snapshot.value as? [String: Any] else { return }
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: value)
                let message = try JSONDecoder().decode(Message.self, from: jsonData)
                onMessageReceived(message)
            } catch {
                print("Firebase Realtime: Mesaj çözümlenirken hata: \(error)")
            }
        }
    }
    
    func unsubscribeFromMessages() {
        if let handle = messagesHandle {
            databaseRef.removeAllObservers()
            messagesHandle = nil
        }
    }
} 