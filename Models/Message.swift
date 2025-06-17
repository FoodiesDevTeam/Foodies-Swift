import Foundation

struct Message: Codable, Identifiable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    let receiverId: String
    let content: String
    let createdAt: Date
    var isRead: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case content
        case createdAt = "created_at"
        case isRead = "is_read"
    }
} 