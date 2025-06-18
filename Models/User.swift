import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let username: String
    var avatarURL: String?
    var bio: String?
    let createdAt: Date
    var updatedAt: Date
    
    init(from userDefaultsUser: UserDefaultsManager.User) {
        self.id = userDefaultsUser.id
        self.email = userDefaultsUser.email
        self.username = userDefaultsUser.username
        self.bio = userDefaultsUser.bio
        self.avatarURL = nil 
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
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
