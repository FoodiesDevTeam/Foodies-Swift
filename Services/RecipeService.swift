import Foundation
import Supabase


class RecipeService: BaseSupabaseService {
    
    // MARK: - Recipe Methods
    
    func getRecipes() async throws -> [Recipe] {
        do {
            let response = try await client
                .database
                .from("recipes")
                .select()
                .execute()
            
            if let responseData = response.data as? [[String: Any]] {
                let jsonData = try JSONSerialization.data(withJSONObject: responseData)
                return try Recipe.decoder.decode([Recipe].self, from: jsonData)
            } else if let stringData = response.data as? String, !stringData.isEmpty {
                guard let jsonData = stringData.data(using: .utf8) else {
                    throw SupabaseError.dataError
                }
                
                return try Recipe.decoder.decode([Recipe].self, from: jsonData)
            } else {
                return []
            }
        } catch {
            print("🚫 Get recipes failed: \(error)")
            throw SupabaseError.clientError("Tarifler yüklenirken bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func getRecipeById(id: UUID) async throws -> Recipe {
        do {
            let response = try await client
                .database
                .from("recipes")
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
            
            if let responseData = response.data as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: responseData)
                return try Recipe.decoder.decode(Recipe.self, from: jsonData)
            } else if let stringData = response.data as? String, !stringData.isEmpty {
                guard let jsonData = stringData.data(using: .utf8) else {
                    throw SupabaseError.dataError
                }
                
                return try Recipe.decoder.decode(Recipe.self, from: jsonData)
            } else {
                throw SupabaseError.dataError
            }
        } catch {
            print("🚫 Get recipe by id failed: \(error)")
            throw SupabaseError.clientError("Tarif yüklenirken bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func createRecipe(recipe: Recipe) async throws -> Recipe {
        do {
            // Oturum durumunu kontrol et
            guard let session = try? await client.auth.session else {
                throw SupabaseError.sessionError
            }
            
            // Recipe verilerini hazırla
            // Encodable uyumlu bir struct oluştur
            struct RecipeInsertData: Encodable {
                let title: String
                let description: String
                let ingredients: [String]
                let instructions: [String]
                let cook_time: Int
                let prep_time: Int
                let servings: Int
                let difficulty: String
                let user_id: String
                let image_url: String?
                let category_id: String?
                
                init(recipe: Recipe, userId: String) {
                    self.title = recipe.title
                    self.description = recipe.description
                    self.ingredients = recipe.ingredients
                    self.instructions = recipe.instructions
                    self.cook_time = recipe.cookTime
                    self.prep_time = recipe.prepTime
                    self.servings = recipe.servings
                    self.difficulty = recipe.difficulty
                    self.user_id = userId
                    self.image_url = recipe.imageURL
                    self.category_id = recipe.categoryId?.uuidString
                }
            }
            
            // Encodable veri yapısı oluştur
            let recipeData = RecipeInsertData(recipe: recipe, userId: session.user.id.uuidString)
            
            let response = try await client
                .database
                .from("recipes")
                .insert(recipeData)
                .single()
                .execute()
            
            if let responseData = response.data as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: responseData)
                return try Recipe.decoder.decode(Recipe.self, from: jsonData)
            } else {
                throw SupabaseError.dataError
            }
        } catch {
            print("🚫 Create recipe failed: \(error)")
            throw SupabaseError.clientError("Tarif oluşturulurken bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func updateRecipe(recipe: Recipe) async throws -> Recipe {
        do {
            // Oturum durumunu kontrol et
            guard let session = try? await client.auth.session else {
                throw SupabaseError.sessionError
            }
            
            // Recipe verilerini hazırla
            // Encodable uyumlu bir struct oluştur
            struct RecipeUpdateData: Encodable {
                let title: String
                let description: String
                let ingredients: [String]
                let instructions: [String]
                let cook_time: Int
                let prep_time: Int
                let servings: Int
                let difficulty: String
                let image_url: String?
                let category_id: String?
                
                init(recipe: Recipe) {
                    self.title = recipe.title
                    self.description = recipe.description
                    self.ingredients = recipe.ingredients
                    self.instructions = recipe.instructions
                    self.cook_time = recipe.cookTime
                    self.prep_time = recipe.prepTime
                    self.servings = recipe.servings
                    self.difficulty = recipe.difficulty
                    self.image_url = recipe.imageURL
                    self.category_id = recipe.categoryId?.uuidString
                }
            }
            
            // Encodable veri yapısı oluştur
            let recipeData = RecipeUpdateData(recipe: recipe)
            
            let response = try await client
                .database
                .from("recipes")
                .update(recipeData)
                .eq("id", value: recipe.id.uuidString)
                .eq("user_id", value: session.user.id.uuidString)  // RLS politikası için kullanıcı kontrolü
                .single()
                .execute()
            
            if let responseData = response.data as? [String: Any] {
                let jsonData = try JSONSerialization.data(withJSONObject: responseData)
                return try Recipe.decoder.decode(Recipe.self, from: jsonData)
            } else {
                throw SupabaseError.dataError
            }
        } catch {
            print("🚫 Update recipe failed: \(error)")
            throw SupabaseError.clientError("Tarif güncellenirken bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    func deleteRecipe(id: UUID) async throws {
        do {
            // Oturum durumunu kontrol et
            guard let session = try? await client.auth.session else {
                throw SupabaseError.sessionError
            }
            
            _ = try await client
                .database
                .from("recipes")
                .delete()
                .eq("id", value: id.uuidString)
                .eq("user_id", value: session.user.id.uuidString)  // RLS politikası için kullanıcı kontrolü
                .execute()
            
        } catch {
            print("🚫 Delete recipe failed: \(error)")
            throw SupabaseError.clientError("Tarif silinirken bir hata oluştu: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Categories Methods
    
    func getCategories() async throws -> [Category] {
        do {
            let response = try await client
                .database
                .from("categories")
                .select()
                .execute()
            
            if let responseData = response.data as? [[String: Any]] {
                let jsonData = try JSONSerialization.data(withJSONObject: responseData)
                return try Category.decoder.decode([Category].self, from: jsonData)
            } else if let stringData = response.data as? String, !stringData.isEmpty {
                guard let jsonData = stringData.data(using: .utf8) else {
                    throw SupabaseError.dataError
                }
                
                return try Category.decoder.decode([Category].self, from: jsonData)
            } else {
                return []
            }
        } catch {
            print("🚫 Get categories failed: \(error)")
            throw SupabaseError.clientError("Kategoriler yüklenirken bir hata oluştu: \(error.localizedDescription)")
        }
    }
}
