import SwiftUI
import Combine

class ColorManager: ObservableObject {
    @Published var colors: [AppColor] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Önbellek için kullanılacak değişkenler
    private var cachedLightColors: [AppColor] = []
    private var cachedDarkColors: [AppColor] = []
    private var lastFetchTime: [Bool: Date] = [:]
    private let cacheDuration: TimeInterval = 3600 // 1 saat
    
    // Singleton örneği
    static let shared = ColorManager()
    
    private init() {
        // ColorScheme değişikliklerini dinle
        NotificationCenter.default.publisher(for: .init("AppleInterfaceThemeChangedNotification"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    let isDark = UITraitCollection.current.userInterfaceStyle == .dark
                    await self?.loadColors(isDarkMode: isDark)
                }
            }
            .store(in: &cancellables)
    }
    
    // Renkleri yükle
    @MainActor
    func loadColors(isDarkMode: Bool) async {
        guard !isLoading else { return }
        
        // Önbellekten kontrol et
        if shouldUseCachedColors(isDarkMode: isDarkMode) {
            self.colors = isDarkMode ? cachedDarkColors : cachedLightColors
            print("🗂️ Önbellekten \(colors.count) renk yüklendi")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            colors = try await supabaseService.getAppColors(isDarkMode: isDarkMode)
            print("✅ \(colors.count) renk yüklendi")
            
            // Önbelleğe kaydet
            if isDarkMode {
                cachedDarkColors = colors
            } else {
                cachedLightColors = colors
            }
            lastFetchTime[isDarkMode] = Date()
        } catch {
            errorMessage = "Renk şeması yüklenirken bir hata oluştu: \(error.localizedDescription)"
            print("❌ Renk şeması yüklenirken hata: \(error)")
        }
        
        isLoading = false
    }
    
    // Önbellek kontrolü
    private func shouldUseCachedColors(isDarkMode: Bool) -> Bool {
        let cachedColors = isDarkMode ? cachedDarkColors : cachedLightColors
        guard !cachedColors.isEmpty else { return false }
        
        if let lastFetch = lastFetchTime[isDarkMode] {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            return timeSinceLastFetch < cacheDuration
        }
        
        return false
    }
    
    // Önbelleği temizle
    func clearCache() {
        cachedLightColors = []
        cachedDarkColors = []
        lastFetchTime = [:]
    }
    
    // Renk adına göre renk döndür
    func color(for name: String, isDarkMode: Bool) -> Color {
        if let foundColor = colors.first(where: { $0.name == name && $0.isDarkMode == isDarkMode }) {
            return foundColor.toColor()
        }
        // Varsayılan renk
        return isDarkMode ? Color.white : Color.black
    }
    
    // Kategori bazında renkleri getir
    func colors(for category: String, isDarkMode: Bool) -> [AppColor] {
        return colors.filter { $0.category == category && $0.isDarkMode == isDarkMode }
    }
    
    // Tema değişikliğini manuel olarak tetikle
    func refreshColors(isDarkMode: Bool) async {
        await loadColors(isDarkMode: isDarkMode)
    }
}
