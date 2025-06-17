import Foundation

struct Conversation: Codable, Identifiable, Hashable {
    let id: String
    let user1Id: String
    let user2Id: String
    let createdAt: Date
    var lastMessageContent: String?
    var lastMessageSentAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case user1Id = "user1_id"
        case user2Id = "user2_id"
        case createdAt = "created_at"
        case lastMessageContent = "last_message_content"
        case lastMessageSentAt = "last_message_sent_at"
    }
} 