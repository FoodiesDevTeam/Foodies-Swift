import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let username: String
    var avatarURL: String?
    var bio: String?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case avatarURL = "avatar_url"
        case bio
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
} 