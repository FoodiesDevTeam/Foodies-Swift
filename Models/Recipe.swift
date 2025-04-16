import Foundation

struct Recipe: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let ingredients: [String]
    let instructions: [String]
    let cookTime: Int
    let prepTime: Int
    let servings: Int
    let difficulty: String
    let imageURL: String?
    let categoryId: UUID?
    let userId: UUID
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case ingredients
        case instructions
        case cookTime = "cook_time"
        case prepTime = "prep_time"
        case servings
        case difficulty
        case imageURL = "image_url"
        case categoryId = "category_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        ingredients = try container.decode([String].self, forKey: .ingredients)
        instructions = try container.decode([String].self, forKey: .instructions)
        cookTime = try container.decode(Int.self, forKey: .cookTime)
        prepTime = try container.decode(Int.self, forKey: .prepTime)
        servings = try container.decode(Int.self, forKey: .servings)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        categoryId = try container.decodeIfPresent(UUID.self, forKey: .categoryId)
        userId = try container.decode(UUID.self, forKey: .userId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(ingredients, forKey: .ingredients)
        try container.encode(instructions, forKey: .instructions)
        try container.encode(cookTime, forKey: .cookTime)
        try container.encode(prepTime, forKey: .prepTime)
        try container.encode(servings, forKey: .servings)
        try container.encode(difficulty, forKey: .difficulty)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encode(userId, forKey: .userId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
} 