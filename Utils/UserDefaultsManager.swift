import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private let kUsers = "users"
    private let kCurrentUser = "currentUser"
    private let kMessages = "messages"
    private let kBlockedUsers = "blockedUsers"
    private let kMatchActions = "matchActions"
    private let kDailyLikes = "dailyLikes"
    private let kLikes = "likes"
    private let kLastLikeDate = "lastLikeDate"
    private let kReportedMessages = "reportedMessages"
    private let kUserSettings = "userSettings"
    
    private init() {}
    
    // MARK: - Models
    
    struct User: Codable {
        let username: String
        let email: String
        var password: String
        var personalInfo: PersonalInfo?
        var appPreferences: AppPreferences?
        var matchingPreferences: MatchingPreferences?
        var photos: [Data]?
        var bio: String?
        
        init(username: String, email: String, password: String) {
            self.username = username
            self.email = email
            self.password = password
            self.photos = []
        }
    }
    
    struct PersonalInfo: Codable {
        var firstName: String
        var lastName: String
        var birthDate: Date
        var gender: Gender
        var city: String?
        var occupation: String?
        var smokingStatus: SmokingStatus
        var drinkingStatus: DrinkingStatus
        var country: String?

        init(firstName: String, lastName: String, birthDate: Date, gender: Gender, city: String?, occupation: String?, smokingStatus: SmokingStatus, drinkingStatus: DrinkingStatus, country: String?) {
            self.firstName = firstName
            self.lastName = lastName
            self.birthDate = birthDate
            self.gender = gender
            self.city = city
            self.occupation = occupation
            self.smokingStatus = smokingStatus
            self.drinkingStatus = drinkingStatus
            self.country = country
        }
    }
    
    struct AppPreferences: Codable {
        var foodPreferences: [String]
        var hobbies: [String]
    }
    
    struct MatchingPreferences: Codable {
        var smokingPreference: PreferenceOption
        var drinkingPreference: PreferenceOption
        var purpose: MatchingPurpose
        var preferredGender: Gender
    }
    
    struct Message: Codable, Identifiable {
        let id: String
        let fromUser: String
        let text: String
        let photoData: Data?
        let timestamp: Date
        
        var senderName: String {
            if let user = UserDefaultsManager.shared.getUser(username: fromUser),
               let info = user.personalInfo {
                return "\(info.firstName) \(info.lastName)"
            }
            return fromUser
        }
        
        var senderPhotoData: Data? {
            if let user = UserDefaultsManager.shared.getUser(username: fromUser),
               let photos = user.photos,
               let firstPhoto = photos.first {
                return firstPhoto
            }
            return nil
        }
    }
    
    struct MessageFilter {
        var minAge: Int = 18
        var maxAge: Int = 99
        var maxDistance: Int = 50
        var gender: Gender = .any
    }
    
    struct MatchAction: Codable {
        let fromUser: String
        let toUser: String
        let type: MatchActionType
        let date: Date
    }
    
    enum Gender: String, Codable {
        case male = "Male"
        case female = "Female"
        case any = "Any"
    }
    
    enum SmokingStatus: String, Codable {
        case yes = "Yes"
        case no = "No"
        case occasionally = "Occasionally"
    }
    
    enum DrinkingStatus: String, Codable {
        case yes = "Yes"
        case no = "No"
        case socially = "Socially"
    }
    
    enum PreferenceOption: String, Codable {
        case yes = "Yes"
        case no = "No"
        case dontCare = "Don't Care"
    }
    
    enum MatchingPurpose: String, Codable {
        case dating = "Dating"
        case friendship = "Friendship"
        case diningCompanion = "Dining Companion"
        case business = "Business"
    }
    
    enum MatchActionType: String, Codable {
        case like
        case superLike
        case pass
    }
    
    enum ReportReason: String, CaseIterable {
        case inappropriate = "Inappropriate Content"
        case harassment = "Harassment"
        case spam = "Spam"
        case other = "Other"
    }
    
    struct Report: Codable {
        let id: String
        let messageId: String
        let reportedBy: String
        let reason: String
        let timestamp: Date
    }
    
    // MARK: - Settings Model
    struct UserSettings: Codable {
        var isVisible: Bool = true
        var notificationsEnabled: Bool = true
        var alertsEnabled: Bool = true
        var cloudSyncEnabled: Bool = false
        var statisticsEnabled: Bool = true
        var privacyEnabled: Bool = true
        var securityEnabled: Bool = true
        var twoFactorEnabled: Bool = false
        var lastPasswordChange: Date?
        var lastLoginDate: Date?
        var failedLoginAttempts: Int = 0
    }
    
    // MARK: - Match Management Methods
    
    func getPotentialMatches(for username: String) -> [User] {
        let allUsers = getAllUsers()
        let currentUser = allUsers.first { $0.username == username }
        
        guard let current = currentUser else { return [] }
        
        // Kullanıcının daha önce etkileşimde bulunduğu kullanıcıları filtrele
        let previousActions = getMatchActions(for: username)
        let interactedUsernames = previousActions.map { $0.toUser }
        
        // Potansiyel eşleşmeleri filtrele ve puanla
        return allUsers
            .filter { user in
                user.username != username && // Kendisi olmamalı
                !interactedUsernames.contains(user.username) && // Daha önce etkileşimde bulunulmamış olmalı
                matchesPreferences(current: current, potential: user) // Tercihlere uygun olmalı
            }
            .sorted { user1, user2 in
                // Eşleşme puanına göre sırala
                calculateMatchScore(current: current, potential: user1) >
                calculateMatchScore(current: current, potential: user2)
            }
    }
    
    private func matchesPreferences(current: User, potential: User) -> Bool {
        guard let currentPrefs = current.matchingPreferences,
              let potentialPrefs = potential.matchingPreferences,
              let currentInfo = current.personalInfo,
              let potentialInfo = potential.personalInfo else {
            return false
        }
        
        // Cinsiyet kontrolü
        if currentPrefs.preferredGender != .any &&
           currentPrefs.preferredGender != potentialInfo.gender {
            return false
        }
        
        // Sigara içme durumu kontrolü
        if currentPrefs.smokingPreference != .dontCare &&
           currentPrefs.smokingPreference.rawValue != potentialInfo.smokingStatus.rawValue {
            return false
        }
        
        // Alkol kullanma durumu kontrolü
        if currentPrefs.drinkingPreference != .dontCare &&
           currentPrefs.drinkingPreference.rawValue != potentialInfo.drinkingStatus.rawValue {
            return false
        }
        
        return true
    }
    
    private func calculateMatchScore(current: User, potential: User) -> Int {
        var score = 0
        
        // Ortak yemek tercihleri için puan
        if let currentPrefs = current.appPreferences,
           let potentialPrefs = potential.appPreferences {
            let commonFoodPreferences = Set(currentPrefs.foodPreferences)
                .intersection(Set(potentialPrefs.foodPreferences))
            score += commonFoodPreferences.count * 2
            
            // Ortak hobiler için puan
            let commonHobbies = Set(currentPrefs.hobbies)
                .intersection(Set(potentialPrefs.hobbies))
            score += commonHobbies.count * 2
        }
        
        // Aynı şehirde olma durumu için bonus puan
        if let currentInfo = current.personalInfo,
           let potentialInfo = potential.personalInfo,
           currentInfo.city == potentialInfo.city {
            score += 5
        }
        
        return score
    }
    
    func addMatchAction(fromUser: String, toUser: String, type: MatchActionType) {
        var actions = getMatchActions(for: fromUser)
        let newAction = MatchAction(
            fromUser: fromUser,
            toUser: toUser,
            type: type,
            date: Date()
        )
        actions.append(newAction)
        
        if let encoded = try? JSONEncoder().encode(actions) {
            defaults.set(encoded, forKey: "\(kMatchActions)_\(fromUser)")
        }
        
        // Super Like için günlük limit kontrolü
        if type == .superLike {
            updateDailyLikes(for: fromUser)
        }
    }
    
    func getMatchActions(for username: String) -> [MatchAction] {
        if let data = defaults.data(forKey: "\(kMatchActions)_\(username)"),
           let actions = try? JSONDecoder().decode([MatchAction].self, from: data) {
            return actions
        }
        return []
    }
    
    func getRemainingDailyLikes(for username: String) -> Int {
        let maxDailyLikes = 3
        let lastLikeDate = defaults.object(forKey: "\(kLastLikeDate)_\(username)") as? Date ?? Date.distantPast
        let dailyLikes = defaults.integer(forKey: "\(kDailyLikes)_\(username)")
        
        // Eğer son like tarihi bugün değilse, sayacı sıfırla
        if !Calendar.current.isDateInToday(lastLikeDate) {
            defaults.set(0, forKey: "\(kDailyLikes)_\(username)")
            return maxDailyLikes
        }
        
        return maxDailyLikes - dailyLikes
    }
    
    private func updateDailyLikes(for username: String) {
        let currentLikes = defaults.integer(forKey: "\(kDailyLikes)_\(username)")
        defaults.set(currentLikes + 1, forKey: "\(kDailyLikes)_\(username)")
        defaults.set(Date(), forKey: "\(kLastLikeDate)_\(username)")
    }
    
    // MARK: - Message Management Methods
    
    func saveMessage(_ message: Message) {
        var messages = getAllMessages()
        messages.append(message)
        
        if let encoded = try? JSONEncoder().encode(messages) {
            defaults.set(encoded, forKey: kMessages)
        }
    }
    
    func getAllMessages() -> [Message] {
        if let data = defaults.data(forKey: kMessages),
           let messages = try? JSONDecoder().decode([Message].self, from: data) {
            return messages
        }
        return []
    }
    
    func getMessages(filter: MessageFilter) -> [Message] {
        let messages = getAllMessages()
        return filterMessages(messages, with: filter)
    }
    
    private func filterMessages(_ messages: [Message], with filter: MessageFilter) -> [Message] {
        return messages.filter { message in
            guard let sender = getUser(username: message.fromUser),
                  let senderInfo = sender.personalInfo else {
                return false
            }
            
            let age = Calendar.current.dateComponents([.year], from: senderInfo.birthDate, to: Date()).year ?? 0
            
            // Filter by age
            if age < filter.minAge || age > filter.maxAge {
                return false
            }
            
            // Filter by gender
            if filter.gender != .any && senderInfo.gender != filter.gender {
                return false
            }
            
            // Filter by distance (if location is available)
            if let userCity = getCurrentUser()?.personalInfo?.city,
               let senderCity = senderInfo.city,
               userCity != senderCity {
                return false
            }
            
            return true
        }
    }
    
    func blockUser(_ username: String, blockedBy: String) {
        var blockedUsers = getBlockedUsers(for: blockedBy)
        blockedUsers.append(username)
        
        if let encoded = try? JSONEncoder().encode(blockedUsers) {
            defaults.set(encoded, forKey: "\(kBlockedUsers)_\(blockedBy)")
        }
    }
    
    func getBlockedUsers(for username: String) -> [String] {
        if let data = defaults.data(forKey: "\(kBlockedUsers)_\(username)"),
           let blockedUsers = try? JSONDecoder().decode([String].self, from: data) {
            return blockedUsers
        }
        return []
    }
    
    func reportMessage(messageId: String, reportedBy: String, reason: String) {
        let report = Report(
            id: UUID().uuidString,
            messageId: messageId,
            reportedBy: reportedBy,
            reason: reason,
            timestamp: Date()
        )
        
        var reports = getReportedMessages()
        reports.append(report)
        
        if let encoded = try? JSONEncoder().encode(reports) {
            defaults.set(encoded, forKey: kReportedMessages)
        }
    }
    
    func getReportedMessages() -> [Report] {
        if let data = defaults.data(forKey: kReportedMessages),
           let reports = try? JSONDecoder().decode([Report].self, from: data) {
            return reports
        }
        return []
    }
    
    // MARK: - Settings Methods
    
    func getUserSettings(for username: String) -> UserSettings {
        if let data = defaults.data(forKey: "\(kUserSettings)_\(username)"),
           let settings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            return settings
        }
        return UserSettings()
    }
    
    func updateUserSettings(_ settings: UserSettings, for username: String) {
        if let encoded = try? JSONEncoder().encode(settings) {
            defaults.set(encoded, forKey: "\(kUserSettings)_\(username)")
        }
    }
    
    func toggleVisibility(for username: String) {
        var settings = getUserSettings(for: username)
        settings.isVisible.toggle()
        updateUserSettings(settings, for: username)
    }
    
    func toggleNotifications(for username: String) {
        var settings = getUserSettings(for: username)
        settings.notificationsEnabled.toggle()
        updateUserSettings(settings, for: username)
    }
    
    func toggleAlerts(for username: String) {
        var settings = getUserSettings(for: username)
        settings.alertsEnabled.toggle()
        updateUserSettings(settings, for: username)
    }
    
    func toggleTwoFactor(for username: String) {
        var settings = getUserSettings(for: username)
        settings.twoFactorEnabled.toggle()
        updateUserSettings(settings, for: username)
    }
    
    func updatePassword(for username: String, newPassword: String) {
        if var user = getUser(username: username) {
            user.password = newPassword
            
            // Tüm kullanıcıları güncelle
            var users = getAllUsers()
            if let index = users.firstIndex(where: { $0.username == username }) {
                users[index] = user
                if let encoded = try? JSONEncoder().encode(users) {
                    defaults.set(encoded, forKey: kUsers)
                }
            }
            
            // Mevcut kullanıcıyı güncelle
            if getCurrentUser()?.username == username {
                if let encoded = try? JSONEncoder().encode(user) {
                    defaults.set(encoded, forKey: kCurrentUser)
                }
            }
            
            var settings = getUserSettings(for: username)
            settings.lastPasswordChange = Date()
            updateUserSettings(settings, for: username)
        }
    }
    
    func recordLoginAttempt(success: Bool, for username: String) {
        var settings = getUserSettings(for: username)
        if success {
            settings.lastLoginDate = Date()
            settings.failedLoginAttempts = 0
        } else {
            settings.failedLoginAttempts += 1
        }
        updateUserSettings(settings, for: username)
    }
    
    // MARK: - User Management Methods
    
    func saveUser(_ user: User) {
        var users = getAllUsers()
        users.append(user)
        if let encoded = try? JSONEncoder().encode(users) {
            defaults.set(encoded, forKey: kUsers)
        }
    }
    
    func getAllUsers() -> [User] {
        if let data = defaults.data(forKey: kUsers),
           let users = try? JSONDecoder().decode([User].self, from: data) {
            return users
        }
        return []
    }
    
    func authenticateUser(username: String, password: String) -> Bool {
        let users = getAllUsers()
        let authenticated = users.contains { user in
            user.username == username && user.password == password
        }
        if authenticated {
            setCurrentUser(username: username)
        }
        return authenticated
    }
    
    func userExists(username: String) -> Bool {
        let users = getAllUsers()
        return users.contains { $0.username == username }
    }
    
    func setCurrentUser(username: String) {
        defaults.set(username, forKey: kCurrentUser)
    }
    
    func getCurrentUser() -> User? {
        guard let username = defaults.string(forKey: kCurrentUser) else { return nil }
        let users = getAllUsers()
        return users.first { $0.username == username }
    }
    
    func updateUserPersonalInfo(username: String, personalInfo: PersonalInfo) {
        var users = getAllUsers()
        if let index = users.firstIndex(where: { $0.username == username }) {
            users[index].personalInfo = personalInfo
            if let encoded = try? JSONEncoder().encode(users) {
                defaults.set(encoded, forKey: kUsers)
            }
        }
    }
    
    func updateUserAppPreferences(username: String, appPreferences: AppPreferences) {
        var users = getAllUsers()
        if let index = users.firstIndex(where: { $0.username == username }) {
            users[index].appPreferences = appPreferences
            if let encoded = try? JSONEncoder().encode(users) {
                defaults.set(encoded, forKey: kUsers)
            }
        }
    }
    
    func updateUserMatchingPreferences(username: String, matchingPreferences: MatchingPreferences) {
        var users = getAllUsers()
        if let index = users.firstIndex(where: { $0.username == username }) {
            users[index].matchingPreferences = matchingPreferences
            if let encoded = try? JSONEncoder().encode(users) {
                defaults.set(encoded, forKey: kUsers)
            }
        }
    }
    
    func updateUserPhotosAndBio(username: String, photos: [Data], bio: String) {
        var users = getAllUsers()
        if let index = users.firstIndex(where: { $0.username == username }) {
            users[index].photos = photos
            users[index].bio = bio
            if let encoded = try? JSONEncoder().encode(users) {
                defaults.set(encoded, forKey: kUsers)
            }
        }
    }
    
    func logout() {
        defaults.removeObject(forKey: kCurrentUser)
    }
    
    func getUser(username: String) -> User? {
        let users = getAllUsers()
        return users.first { $0.username == username }
    }
    
    func updateUser(_ user: User) {
        var users = getAllUsers()
        if let index = users.firstIndex(where: { $0.username == user.username }) {
            users[index] = user
            if let encoded = try? JSONEncoder().encode(users) {
                defaults.set(encoded, forKey: kUsers)
            }
        }
    }
    
    func deleteUser(username: String) {
        var users = getAllUsers()
        if let index = users.firstIndex(where: { $0.username == username }) {
            users.remove(at: index)
            if let encoded = try? JSONEncoder().encode(users) {
                defaults.set(encoded, forKey: kUsers)
            }
        }
        // Remove current user if they are being deleted
        if getCurrentUser()?.username == username {
            defaults.removeObject(forKey: kCurrentUser)
        }
    }
    
    func updateCurrentUser(user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            defaults.set(encoded, forKey: kCurrentUser)
        }
    }
}
