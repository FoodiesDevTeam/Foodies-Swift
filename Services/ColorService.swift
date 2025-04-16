import Foundation
import Supabase
import SwiftUI

class ColorService: BaseSupabaseService {
    
    // MARK: - App Colors Methods
    
    func getAppColors(isDarkMode: Bool) async throws -> [AppColor] {
        do {
            let query = client
                .database
                .from("app_colors")
                .select()
                .eq("is_dark_mode", value: isDarkMode)
            
            let response = try await query.execute()
            
            if let responseData = response.data as? [[String: Any]] {
                let jsonData = try JSONSerialization.data(withJSONObject: responseData)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                return try decoder.decode([AppColor].self, from: jsonData)
            } else if let stringData = response.data as? String, !stringData.isEmpty {
                guard let jsonData = stringData.data(using: .utf8) else {
                    throw SupabaseError.dataError
                }
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                return try decoder.decode([AppColor].self, from: jsonData)
            } else {
                // Varsayılan renkler
                return createDefaultColors(isDarkMode: isDarkMode)
            }
        } catch {
            print("🚫 Get app colors failed: \(error)")
            
            // Hata durumunda varsayılan renkleri döndür
            return createDefaultColors(isDarkMode: isDarkMode)
        }
    }
    
    private func createDefaultColors(isDarkMode: Bool) -> [AppColor] {
        if isDarkMode {
            return [
                AppColor(id: UUID(), name: "primaryColor", hexCode: "#FF6B6B", rgbValues: ["r": 255, "g": 107, "b": 107], category: "main", isDarkMode: true),
                AppColor(id: UUID(), name: "secondaryColor", hexCode: "#4ECDC4", rgbValues: ["r": 78, "g": 205, "b": 196], category: "main", isDarkMode: true),
                AppColor(id: UUID(), name: "backgroundColor", hexCode: "#121212", rgbValues: ["r": 18, "g": 18, "b": 18], category: "background", isDarkMode: true),
                AppColor(id: UUID(), name: "textColor", hexCode: "#F7F7F7", rgbValues: ["r": 247, "g": 247, "b": 247], category: "text", isDarkMode: true),
                AppColor(id: UUID(), name: "accentColor", hexCode: "#FFE66D", rgbValues: ["r": 255, "g": 230, "b": 109], category: "accent", isDarkMode: true)
            ]
        } else {
            return [
                AppColor(id: UUID(), name: "primaryColor", hexCode: "#FF6B6B", rgbValues: ["r": 255, "g": 107, "b": 107], category: "main", isDarkMode: false),
                AppColor(id: UUID(), name: "secondaryColor", hexCode: "#4ECDC4", rgbValues: ["r": 78, "g": 205, "b": 196], category: "main", isDarkMode: false),
                AppColor(id: UUID(), name: "backgroundColor", hexCode: "#F7F7F7", rgbValues: ["r": 247, "g": 247, "b": 247], category: "background", isDarkMode: false),
                AppColor(id: UUID(), name: "textColor", hexCode: "#333333", rgbValues: ["r": 51, "g": 51, "b": 51], category: "text", isDarkMode: false),
                AppColor(id: UUID(), name: "accentColor", hexCode: "#FFE66D", rgbValues: ["r": 255, "g": 230, "b": 109], category: "accent", isDarkMode: false)
            ]
        }
    }
}
