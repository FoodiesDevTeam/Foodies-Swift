import SwiftUI

struct AppPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFoodPreferences: Set<String> = []
    @State private var selectedHobbies: Set<String> = []
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var foodPreferencesList: [String] = []
    @State private var hobbiesList: [String] = []
    
    let onboardingState: OnboardingState?
    var onSave: (() -> Void)?
    
    private let supabaseService = SupabaseService.shared
    
    var body: some View {
        VStack(spacing: Constants.Design.defaultSpacing) {
            progressSection
            preferencesScrollView
            saveButton
        }
        .padding(.top, Constants.Design.defaultPadding)
        .background(backgroundGradient)
        .alert("Uyarı", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .task {
            await loadPreferences()
        }
    }
    
    private var progressSection: some View {
        Group {
            if onboardingState != nil {
                ProgressView(value: onboardingState?.progress ?? 0)
                    .progressViewStyle(.linear)
                    .tint(Color.purple)
                    .padding(.horizontal)
                
                Text(onboardingState?.title ?? "")
                    .font(.system(size: Constants.FontSizes.title1, weight: .bold))
                    .foregroundStyle(Constants.Design.mainGradient)
            }
        }
    }
    
    private var preferencesScrollView: some View {
        ScrollView {
            VStack(spacing: Constants.Design.defaultSpacing) {
                foodPreferencesSection
                hobbiesSection
            }
            .padding(.horizontal)
        }
    }
    
    private var foodPreferencesSection: some View {
        VStack(alignment: .leading, spacing: Constants.Design.defaultPadding) {
            Text("Yemek Tercihleri")
                .font(.headline)
                .foregroundStyle(Constants.Design.mainGradient)
            
            CustomFlowLayout(
                items: foodPreferencesList,
                isSelected: { selectedFoodPreferences.contains($0) },
                onTap: { item in
                    if selectedFoodPreferences.contains(item) {
                        selectedFoodPreferences.remove(item)
                    } else {
                        selectedFoodPreferences.insert(item)
                    }
                },
                spacing: 8
            ) { item in
                PreferenceChip(
                    title: item,
                    isSelected: selectedFoodPreferences.contains(item),
                    action: {
                        if selectedFoodPreferences.contains(item) {
                            selectedFoodPreferences.remove(item)
                        } else {
                            selectedFoodPreferences.insert(item)
                        }
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var hobbiesSection: some View {
        VStack(alignment: .leading, spacing: Constants.Design.defaultPadding) {
            Text("Hobiler")
                .font(.headline)
                .foregroundStyle(Constants.Design.mainGradient)
            
            CustomFlowLayout(
                items: hobbiesList,
                isSelected: { selectedHobbies.contains($0) },
                onTap: { item in
                    if selectedHobbies.contains(item) {
                        selectedHobbies.remove(item)
                    } else {
                        selectedHobbies.insert(item)
                    }
                },
                spacing: 8
            ) { item in
                PreferenceChip(
                    title: item,
                    isSelected: selectedHobbies.contains(item),
                    action: {
                        if selectedHobbies.contains(item) {
                            selectedHobbies.remove(item)
                        } else {
                            selectedHobbies.insert(item)
                        }
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private var saveButton: some View {
        Button(action: validateAndSave) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(onboardingState != nil ? "İleri" : "Kaydet")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Constants.Design.cornerRadius)
                .fill(Constants.Design.mainGradient)
        )
        .padding(.horizontal)
        .disabled(isLoading || selectedFoodPreferences.isEmpty || selectedHobbies.isEmpty)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.8),
                Color.blue.opacity(0.1),
                Color.purple.opacity(0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private func loadPreferences() async {
        isLoading = true
        print("🔍 Tercihler yükleniyor...")
        
        do {
            let foodPreferences = try await supabaseService.getFoodPreferences()
            print("🍔 Yemek tercihleri yüklendi:", foodPreferences)
            
            let hobbies = try await supabaseService.getHobbies()
            print("🎯 Hobiler yüklendi:", hobbies)
            
            await MainActor.run {
                foodPreferencesList = foodPreferences.map { $0.name }
                hobbiesList = hobbies.map { $0.name }
                print("📝 Yemek listesi:", foodPreferencesList)
                print("📝 Hobi listesi:", hobbiesList)
                isLoading = false
            }
        } catch {
            print("❌ Hata oluştu:", error)
            await MainActor.run {
                alertMessage = "Veriler yüklenirken bir hata oluştu: \(error.localizedDescription)"
                showAlert = true
                isLoading = false
            }
        }
    }
    
    private func validateAndSave() {
        if selectedFoodPreferences.isEmpty {
            alertMessage = "Lütfen en az bir yemek tercihi seçin"
            showAlert = true
            return
        }
        
        if selectedHobbies.isEmpty {
            alertMessage = "Lütfen en az bir hobi seçin"
            showAlert = true
            return
        }
        
        isLoading = true
        
        if let username = UserDefaultsManager.shared.getCurrentUser()?.username {
            let preferences = UserDefaultsManager.AppPreferences(
                foodPreferences: Array(selectedFoodPreferences),
                hobbies: Array(selectedHobbies)
            )
            
            do {
                UserDefaultsManager.shared.updateUserAppPreferences(username: username, appPreferences: preferences)
                
                if onboardingState != nil {
                    onSave?()
                } else {
                    dismiss()
                }
            } catch {
                alertMessage = "Tercihler kaydedilirken bir hata oluştu: \(error.localizedDescription)"
                showAlert = true
            }
        } else {
            alertMessage = "Kullanıcı bilgisi bulunamadı"
            showAlert = true
        }
        
        isLoading = false
    }
}

struct PreferenceChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? AnyShapeStyle(Constants.Design.mainGradient) : AnyShapeStyle(Color(.systemGray6)))
                )
                .foregroundColor(isSelected ? .white : .primary)
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : Color(.systemGray4), lineWidth: 1)
                )
        }
    }
}

struct CustomFlowLayout<Data: RandomAccessCollection>: View where Data.Element: Hashable {
    let items: Data
    let isSelected: (Data.Element) -> Bool
    let onTap: (Data.Element) -> Void
    let spacing: CGFloat
    let content: (Data.Element) -> AnyView
    
    @State private var totalHeight: CGFloat = .zero
    
    init(
        items: Data,
        isSelected: @escaping (Data.Element) -> Bool,
        onTap: @escaping (Data.Element) -> Void,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Data.Element) -> some View
    ) {
        self.items = items
        self.isSelected = isSelected
        self.onTap = onTap
        self.spacing = spacing
        self.content = { AnyView(content($0)) }
    }
    
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        var lastX = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                content(item)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                    .background(
                        GeometryReader { geo -> Color in
                            DispatchQueue.main.async {
                                if geo.frame(in: .local).maxX > geometry.size.width {
                                    width = 0
                                    height += geo.size.height + spacing
                                }
                                
                                if index == 0 {
                                    width = 0
                                    height = 0
                                }
                                
                                width += geo.size.width + spacing
                                lastX = geo.frame(in: .local).maxX
                                
                                if index == items.count - 1 {
                                    totalHeight = height + geo.size.height
                                }
                            }
                            return Color.clear
                        }
                    )
                    .offset(x: width - (lastX + spacing), y: height)
                    .onTapGesture { onTap(item) }
            }
        }
    }
}

struct AppPreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        AppPreferencesView(onboardingState: .matchingPreferences)
    }
}
