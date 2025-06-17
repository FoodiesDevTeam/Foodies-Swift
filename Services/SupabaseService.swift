import Foundation
import Supabase
import Auth
import SwiftUI

enum SupabaseError: Error {
    case invalidURL
    case invalidConfiguration
    case clientError(String)
    case signUpFailed
    case signInFailed
    case signOutFailed
    case resetPasswordFailed
    case sessionError
    case userNotFound
    case userAlreadyExists
    case dataError
}

class SupabaseService {
    static let shared = SupabaseService()
    
    // Supabase client
    let client: SupabaseClient
    private let supabaseURL = "https://jysrmcnzqyjfsfcdzzuj.supabase.co"
    private let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp5c3JtY256cXlqZnNmY2R6enVqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM5ODYzODksImV4cCI6MjA1OTU2MjM4OX0.JsIXlVF7-uxsaanWkQvHETh371HWwI06ykGhvp4ISdM"
  

    
    private lazy var authService: AuthService = {
        return AuthService(client: client)
    }()
    
    private lazy var preferenceService: PreferenceService = {
        return PreferenceService(client: client)
    }()
    
    private lazy var recipeService: RecipeService = {
        return RecipeService(client: client)
    }()
    
    private lazy var colorService: ColorService = {
        return ColorService(client: client)
    }()
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    
    init() {
      
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL")
        }
        
        let supabaseClient = SupabaseClient(supabaseURL: url, supabaseKey: supabaseKey)
        self.client = supabaseClient
    }
    
    func signUp(email: String, password: String) async throws -> AppUser {
        return try await authService.signUp(email: email, password: password)
    }
    
    func signIn(email: String, password: String) async throws -> AppUser {
        return try await authService.signIn(email: email, password: password)
    }
    
    func signOut() async throws {
        try await authService.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await authService.resetPassword(email: email)
    }
    
    func getCurrentUser() async throws -> AppUser? {
        return try await authService.getCurrentUser()
    }
    
    func updateUserProfile(userId: UUID, username: String?, avatarURL: String?, bio: String?) async throws -> AppUser {
        return try await authService.updateUserProfile(userId: userId, username: username, avatarURL: avatarURL, bio: bio)
    }
    
    // MARK: - Recipe Delegations
    
    func getRecipes() async throws -> [Recipe] {
        return try await recipeService.getRecipes()
    }
    
    func getRecipeById(id: UUID) async throws -> Recipe {
        return try await recipeService.getRecipeById(id: id)
    }
    
    func createRecipe(recipe: Recipe) async throws -> Recipe {
        return try await recipeService.createRecipe(recipe: recipe)
    }
    
    func updateRecipe(recipe: Recipe) async throws -> Recipe {
        return try await recipeService.updateRecipe(recipe: recipe)
    }
    
    func deleteRecipe(id: UUID) async throws {
        try await recipeService.deleteRecipe(id: id)
    }
    
    func getCategories() async throws -> [Category] {
        return try await recipeService.getCategories()
    }
    
    // MARK: - Preference Delegations
    
    func getFoodPreferences() async throws -> [FoodPreferenceNew] {
        return try await preferenceService.getFoodPreferences()
    }
    
    func getHobbies() async throws -> [HobbyNew] {
        return try await preferenceService.getHobbies()
    }
    
    func getUserPreferences(userId: UUID) async throws -> UserPreferences {
        return try await preferenceService.getUserPreferences(userId: userId)
    }
    
    func getUserFoodPreferences(userPreferenceId: UUID) async throws -> [FoodPreferenceNew] {
        return try await preferenceService.getUserFoodPreferences(userPreferenceId: userPreferenceId)
    }
    
    func getUserHobbies(userPreferenceId: UUID) async throws -> [HobbyNew] {
        return try await preferenceService.getUserHobbies(userPreferenceId: userPreferenceId)
    }
    
    func saveUserPreferences(userId: UUID, foodPreferences: [UUID], hobbies: [UUID]) async throws {
        try await preferenceService.saveUserPreferences(userId: userId, foodPreferences: foodPreferences, hobbies: hobbies)
    }
    
    // MARK: - Color Delegations
    
    func getAppColors(isDarkMode: Bool) async throws -> [AppColor] {
        return try await colorService.getAppColors(isDarkMode: isDarkMode)
    }

    // MARK: - Chat Delegations (Removed for Firebase Migration)
    
    // func getOrCreateConversation(user1Id: UUID, user2Id: UUID) async throws -> Conversation {
    //     return try await chatService.getOrCreateConversation(user1Id: user1Id, user2Id: user2Id)
    // }
    // 
    // func getMessages(conversationId: UUID) async throws -> [Message] {
    //     return try await chatService.getMessages(conversationId: conversationId)
    // }
    // 
    // func sendMessage(conversationId: UUID, senderId: UUID, receiverId: UUID, content: String) async throws -> Message {
    //     return try await chatService.sendMessage(conversationId: conversationId, senderId: senderId, receiverId: receiverId, content: content)
    // }
    // 
    // func markMessageAsRead(messageId: UUID) async throws {
    //     try await chatService.markMessageAsRead(messageId: messageId)
    // }
    // 
    // func subscribeToMessages(conversationId: UUID, onMessageReceived: @escaping (Message) -> Void) {
    //     chatService.subscribeToMessages(conversationId: conversationId, onMessageReceived: onMessageReceived)
    // }
    // 
    // func unsubscribeFromMessages() {
    //     chatService.unsubscribeFromMessages()
    // }
}
