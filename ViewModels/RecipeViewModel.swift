import Foundation
import SwiftUI

@MainActor
class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var error: Error?
    
    private let supabaseService = SupabaseService.shared
    
    func fetchRecipes() async {
        do {
            recipes = try await supabaseService.fetchRecipes()
        } catch {
            self.error = error
        }
    }
    
    func fetchRecipe(id: String) async -> Recipe? {
        do {
            return try await supabaseService.fetchRecipe(id: id)
        } catch {
            self.error = error
            return nil
        }
    }
    
    func createRecipe(_ recipe: Recipe) async {
        do {
            let newRecipe = try await supabaseService.createRecipe(recipe)
            recipes.append(newRecipe)
        } catch {
            self.error = error
        }
    }
    
    func updateRecipe(_ recipe: Recipe) async {
        do {
            let updatedRecipe = try await supabaseService.updateRecipe(recipe)
            if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
                recipes[index] = updatedRecipe
            }
        } catch {
            self.error = error
        }
    }
    
    func deleteRecipe(id: String) async {
        do {
            try await supabaseService.deleteRecipe(id: id)
            recipes.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }
} 