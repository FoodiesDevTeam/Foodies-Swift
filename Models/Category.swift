import Foundation

struct Category: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let imageURL: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case imageURL = "image_url"
        case createdAt = "created_at"
    }
} 