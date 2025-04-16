import Foundation
import SwiftUI
import Supabase
import Auth
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isAuthenticated = false
    @Published var error: Error?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var shouldShowProfileSetup = false
    
    private let supabaseService = SupabaseService.shared
    
    init() {
        checkAuthStatus()
    }
    
    func checkAuthStatus() {
        Task {
            do {
                if let user = try await supabaseService.getCurrentUser() {
                    await MainActor.run {
                        self.currentUser = user
                        self.isAuthenticated = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = error
                }
            }
        }
    }
    
    func signUp(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await supabaseService.signUp(email: email, password: password)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
                self.errorMessage = nil // Başarılı kayıt durumunda hata mesajını temizle
            }
        } catch {
            await MainActor.run {
                self.error = error
                
                // Özel hata mesajları için hata tipini kontrol et
                if let supabaseError = error as? SupabaseError {
                    switch supabaseError {
                    case .userAlreadyExists:
                        self.errorMessage = "Bu e-posta adresi zaten kayıtlı. Lütfen giriş yapın veya başka bir e-posta adresi kullanın."
                    case .signUpFailed:
                        self.errorMessage = "Kayıt işlemi sırasında bir hata oluştu. Lütfen tekrar deneyin."
                    default:
                        self.errorMessage = "Bir hata oluştu: \(error.localizedDescription)"
                    }
                } else {
                    self.errorMessage = "Bir hata oluştu: \(error.localizedDescription)"
                }
            }
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let user = try await supabaseService.signIn(email: email, password: password)
            await MainActor.run {
                self.currentUser = user
                self.isAuthenticated = true
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabaseService.signOut()
            await MainActor.run {
                self.currentUser = nil
                self.isAuthenticated = false
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await supabaseService.resetPassword(email: email)
        } catch {
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
} 