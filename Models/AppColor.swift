import SwiftUI

struct AppColor: Identifiable, Codable {
    let id: UUID
    let name: String
    let hexCode: String
    let rgbValues: [String: Int]?
    let category: String
    let isDarkMode: Bool
    
    // CodingKeys ekleyelim
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case hexCode = "hex_code"
        case rgbValues = "rgb_values"
        case category
        case isDarkMode = "is_dark_mode"
    }
    
    // Color nesnesine dönüştürme yardımcı fonksiyonu
    func toColor() -> Color {
        if let rgbValues = rgbValues,
           let r = rgbValues["r"],
           let g = rgbValues["g"],
           let b = rgbValues["b"] {
            return Color(red: Double(r) / 255.0, green: Double(g) / 255.0, blue: Double(b) / 255.0)
        }
        // Hex değerini manuel olarak dönüştür
        let hex = hexCode.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        
        switch hex.count {
        case 3: // RGB (12-bit)
            r = Double((int >> 8) * 17) / 255.0
            g = Double((int >> 4 & 0xF) * 17) / 255.0
            b = Double((int & 0xF) * 17) / 255.0
        case 6: // RGB (24-bit)
            r = Double(int >> 16) / 255.0
            g = Double(int >> 8 & 0xFF) / 255.0
            b = Double(int & 0xFF) / 255.0
        default:
            r = 0
            g = 0
            b = 0
        }
        
        return Color(red: r, green: g, blue: b)
    }
    
    // Renk adından SwiftUI Color'a dönüştürme
    static func colorFromName(_ name: String, colors: [AppColor], isDarkMode: Bool) -> Color {
        let targetName = isDarkMode ? name + "_dark" : name
        if let color = colors.first(where: { $0.name == targetName }) {
            return color.toColor()
        }
        // Varsayılan renk
        return isDarkMode ? .white : .black
    }
    
    // Varsayılan renk oluşturucu
    static func defaultColor(name: String, hexCode: String, category: String, isDarkMode: Bool) -> AppColor {
        let rgbValues = hexToRGB(hex: hexCode)
        return AppColor(
            id: UUID(),
            name: name,
            hexCode: hexCode,
            rgbValues: rgbValues,
            category: category,
            isDarkMode: isDarkMode
        )
    }
    
    // Hex kodundan RGB değerlerini hesaplama
    private static func hexToRGB(hex: String) -> [String: Int]? {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        switch hex.count {
        case 3: // RGB (12-bit)
            return [
                "r": Int((int >> 8) * 17),
                "g": Int((int >> 4 & 0xF) * 17),
                "b": Int((int & 0xF) * 17)
            ]
        case 6: // RGB (24-bit)
            return [
                "r": Int(int >> 16),
                "g": Int(int >> 8 & 0xFF),
                "b": Int(int & 0xFF)
            ]
        case 8: // ARGB (32-bit)
            return [
                "r": Int(int >> 16 & 0xFF),
                "g": Int(int >> 8 & 0xFF),
                "b": Int(int & 0xFF)
            ]
        default:
            return nil
        }
    }
}


