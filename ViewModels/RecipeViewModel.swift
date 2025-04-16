import Foundation
import SwiftUI

@MainActor
class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var error: Error?
    
    private let supabaseService = SupabaseService.shared
    
    func fetchRecipes() async {
        do {
            recipes = try await supabaseService.getRecipes()
        } catch {
            self.error = error
        }
    }
    
    func fetchRecipe(id: UUID) async -> Recipe? {
        do {
            return try await supabaseService.getRecipeById(id: id)
        } catch {
            self.error = error
            return nil
        }
    }
    
    func createRecipe(_ recipe: Recipe) async {
        do {
            let newRecipe = try await supabaseService.createRecipe(recipe: recipe)
            recipes.append(newRecipe)
        } catch {
            self.error = error
        }
    }
    
    func updateRecipe(_ recipe: Recipe) async {
        do {
            let updatedRecipe = try await supabaseService.updateRecipe(recipe: recipe)
            if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
                recipes[index] = updatedRecipe
            }
        } catch {
            self.error = error
        }
    }
    
    func deleteRecipe(id: UUID) async {
        do {
            try await supabaseService.deleteRecipe(id: id)
            recipes.removeAll { $0.id == id }
        } catch {
            self.error = error
        }
    }
} 