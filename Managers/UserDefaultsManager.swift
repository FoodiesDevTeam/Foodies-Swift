import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard
    
    private let usersKey = "users"
    private let messagesKey = "messages"
    private let meetingsKey = "meetings"
    private let ratingsKey = "ratings"
    private let passwordsKey = "passwords"
    private let matchesKey = "matches"
    
    private init() {}
    
    struct User: Codable {
        let id: String
        let username: String
        let email: String
        var personalInfo: PersonalInfo?
        var photos: [Data]?
        var appPreferences: AppPreferences?
        var matchingPreferences: MatchingPreferences?
        var bio: String?
        var ratings: [Rating]
        var punctualityScore: Double
        
        init(username: String, email: String = "") {
            self.id = UUID().uuidString
            self.username = username
            self.email = email
            self.personalInfo = nil
            self.photos = []
            self.appPreferences = nil
            self.matchingPreferences = nil
            self.bio = nil
            self.ratings = []
            self.punctualityScore = 5.0
        }
    }
    
    struct PersonalInfo: Codable {
        var name: String
        var surname: String
        var birthDate: Date
        var phoneNumber: String
        var countryCode: String
        var smokingStatus: SmokingStatus
        var drinkingStatus: DrinkingStatus
        var city: String?
        var occupation: String?
        var email: String?
        var gender: Gender
        
        var firstName: String { name }
        var lastName: String { surname }
    }
    
    enum SmokingStatus: String, Codable {
        case yes, no, occasionally
    }
    
    enum DrinkingStatus: String, Codable {
        case yes, no, socially
    }
    
    struct Rating: Codable {
        let type: RatingType
        let score: Double
        let comment: String?
        let date: Date
        
        init(type: RatingType, score: Double, comment: String?) {
            self.type = type
            self.score = score
            self.comment = comment
            self.date = Date()
        }
    }
    
    enum RatingType: String, Codable {
        case punctuality
        case profile
        case experience
    }
    
    struct AppPreferences: Codable {
        let foodPreferences: [String]
        let hobbies: [String]
    }
    
    struct MatchingPreferences: Codable {
        let smokingPreference: PreferenceOption
        let drinkingPreference: PreferenceOption
        let purpose: MatchingPurpose
        let preferredGender: Gender
    }
    
    // MARK: - Message Model
    struct Message: Codable, Identifiable {
        let id: String
        let senderId: String
        let receiverId: String
        let content: String
        let timestamp: Date
        var isRead: Bool
        var senderPhotoData: Data?
        
        var senderName: String {
            if let user = UserDefaultsManager.shared.getUser(username: senderId) {
                return "\(user.personalInfo?.name ?? "") \(user.personalInfo?.surname ?? "")"
            }
            return senderId
        }
        
        var text: String {
            content
        }
        
        init(senderId: String, receiverId: String, content: String, senderPhotoData: Data? = nil) {
            self.id = UUID().uuidString
            self.senderId = senderId
            self.receiverId = receiverId
            self.content = content
            self.timestamp = Date()
            self.isRead = false
            self.senderPhotoData = senderPhotoData
        }
    }
    
    struct MessageFilter {
        var userId: String?
        var isRead: Bool?
        var startDate: Date?
        var endDate: Date?
    }
    
    // MARK: - Meeting Model
    struct Meeting: Codable {
        let id: String
        var status: MeetingStatus
        let date: Date
        let location: String
        let creatorId: String
        let participantId: String
        let restaurantName: String
        let verificationCode: String?
        var isVerified: Bool
        
        init(creatorId: String, participantId: String, restaurantName: String, location: String, date: Date) {
            self.id = UUID().uuidString
            self.creatorId = creatorId
            self.participantId = participantId
            self.restaurantName = restaurantName
            self.location = location
            self.date = date
            self.status = .pending
            self.verificationCode = nil
            self.isVerified = false
        }
    }
    
    enum MeetingStatus: String, Codable {
        case pending, accepted, rejected, cancelled, completed
    }
    
    enum PreferenceOption: String, Codable {
        case yes, no, dontCare
    }
    
    enum MatchingPurpose: String, Codable {
        case dating, friendship, diningCompanion, business
    }
    
    enum Gender: String, Codable {
        case male, female, any
    }
    
    // MARK: - User Management
    private func getUsers() -> [User] {
        if let data = defaults.data(forKey: usersKey),
           let users = try? JSONDecoder().decode([User].self, from: data) {
            return users
        }
        return []
    }
    
    private func saveUsers(_ users: [User]) {
        if let data = try? JSONEncoder().encode(users) {
            defaults.set(data, forKey: usersKey)
        }
    }
    
    func getUser(username: String) -> User? {
        return getUsers().first { $0.username == username }
    }
    
    private func updateUser(_ updatedUser: User) {
        var users = getUsers()
        if let index = users.firstIndex(where: { $0.username == updatedUser.username }) {
            users[index] = updatedUser
            saveUsers(users)
        }
    }
    
    func createUser(username: String) -> User {
        let newUser = User(username: username)
        var users = getUsers()
        users.append(newUser)
        saveUsers(users)
        return newUser
    }
    
    // MARK: - Current User Management
    private let currentUserKey = "currentUser"
    
    func getCurrentUser() -> User? {
        if let username = defaults.string(forKey: currentUserKey) {
            return getUser(username: username)
        }
        return nil
    }
    
    func setCurrentUser(username: String?) {
        defaults.set(username, forKey: currentUserKey)
    }
    
    // MARK: - Message Management
    
    // Private helper: Mesajları UserDefaults'tan ASIL okuyan fonksiyon
    private func getAllMessagesFromDefaults() -> [Message] {
        if let data = defaults.data(forKey: messagesKey),
           let messages = try? JSONDecoder().decode([Message].self, from: data) {
            return messages
        }
        return []
    }
    
    // Public function: Mesajları alır ve filtreler
    func getMessages(filter: MessageFilter? = nil) -> [Message] {
        // Önce TÜM mesajları UserDefaults'tan okuyalım
        var messages = getAllMessagesFromDefaults()
        
        if let filter = filter {
            if let userId = filter.userId {
                messages = messages.filter { $0.senderId == userId || $0.receiverId == userId }
            }
            
            if let isRead = filter.isRead {
                messages = messages.filter { $0.isRead == isRead }
            }
            
            if let startDate = filter.startDate {
                messages = messages.filter { $0.timestamp >= startDate }
            }
            
            if let endDate = filter.endDate {
                messages = messages.filter { $0.timestamp <= endDate }
            }
        }
        
        return messages
    }
    
    func getConversation(between user1: String, and user2: String) -> [Message] {
        return getAllMessagesFromDefaults().filter { msg in
            (msg.senderId == user1 && msg.receiverId == user2) ||
            (msg.senderId == user2 && msg.receiverId == user1)
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    private func saveMessages(_ messages: [Message]) {
        if let data = try? JSONEncoder().encode(messages) {
            defaults.set(data, forKey: messagesKey)
        }
    }
    
    func sendMessage(senderId: String, receiverId: String, content: String) {
        let senderPhoto = getUser(username: senderId)?.photos?.first 
        let message = Message(senderId: senderId, receiverId: receiverId, content: content, senderPhotoData: senderPhoto)
        
        var messages = getAllMessagesFromDefaults()
        messages.append(message)
        saveMessages(messages)
    }
    
    // MARK: - Meeting Management
    func getMeetings() -> [Meeting] {
        if let data = defaults.data(forKey: meetingsKey),
           let meetings = try? JSONDecoder().decode([Meeting].self, from: data) {
            return meetings
        }
        return []
    }
    
    func saveMeetings(_ meetings: [Meeting]) {
        if let data = try? JSONEncoder().encode(meetings) {
            defaults.set(data, forKey: meetingsKey)
        }
    }
    
    func createMeeting(creatorId: String, participantId: String, restaurantName: String, location: String, date: Date) -> Meeting {
        let meeting = Meeting(
            creatorId: creatorId,
            participantId: participantId,
            restaurantName: restaurantName,
            location: location,
            date: date
        )
        
        var meetings = getMeetings()
        meetings.append(meeting)
        saveMeetings(meetings)
        
        return meeting
    }
    
    func getMeetingsForUser(userId: String) -> [Meeting] {
        return getMeetings().filter { meeting in
            meeting.creatorId == userId || meeting.participantId == userId
        }.sorted { $0.date < $1.date }
    }
    
    func updateMeetingStatus(meetingId: String, status: MeetingStatus) {
        var meetings = getMeetings()
        if let index = meetings.firstIndex(where: { $0.id == meetingId }) {
            meetings[index].status = status
            saveMeetings(meetings)
        }
    }
    
    func verifyMeeting(verificationCode: String) -> Meeting? {
        var meetings = getMeetings()
        if let index = meetings.firstIndex(where: { $0.verificationCode == verificationCode }) {
            meetings[index].isVerified = true
            meetings[index].status = .completed
            saveMeetings(meetings)
            return meetings[index]
        }
        return nil
    }
    
    func getRatingsForMeeting(meetingId: String) -> [Rating] {
        let users = getUsers()
        var ratings: [Rating] = []
        
        for user in users {
            ratings.append(contentsOf: user.ratings.filter { rating in
                // Burada rating ile meeting ID'sini ilişkilendirme mantığı eklenebilir
                // Şimdilik tüm ratingleri döndürüyoruz
                true
            })
        }
        
        return ratings
    }
    
    // MARK: - User Data Updates
    func updateUserPersonalInfo(username: String, personalInfo: PersonalInfo) {
        if var user = getUser(username: username) {
            user.personalInfo = personalInfo
            updateUser(user)
        }
    }
    
    func updateUserAppPreferences(username: String, appPreferences: AppPreferences) {
        if var user = getUser(username: username) {
            user.appPreferences = appPreferences
            updateUser(user)
        }
    }
    
    func updateUserMatchingPreferences(username: String, matchingPreferences: MatchingPreferences) {
        if var user = getUser(username: username) {
            user.matchingPreferences = matchingPreferences
            updateUser(user)
        }
    }
    
    func updateUserPhotosAndBio(username: String, photos: [Data], bio: String) {
        if var user = getUser(username: username) {
            user.photos = photos
            user.bio = bio
            updateUser(user)
        }
    }
    
    // MARK: - Rating Management
    func getRatingsForUser(username: String) -> [Rating] {
        let users = getUsers()
        guard let user = users.first(where: { $0.username == username }) else { return [] }
        return user.ratings
    }
    
    func addRating(to username: String, type: RatingType, score: Double, comment: String?) {
        var users = getUsers()
        if let index = users.firstIndex(where: { $0.username == username }) {
            let rating = Rating(type: type, score: score, comment: comment)
            users[index].ratings.append(rating)
            updateUserScore(for: &users[index], with: rating)
            saveUsers(users)
        }
    }
    
    private func updateUserScore(for user: inout User, with rating: Rating) {
        let ratings = user.ratings.filter { $0.type == rating.type }
        let averageScore = ratings.reduce(0.0) { $0 + $1.score } / Double(ratings.count)
        
        switch rating.type {
        case .punctuality:
            user.punctualityScore = averageScore
        case .profile, .experience:
            // Bu puanlar için gerekirse özel işlemler eklenebilir
            break
        }
    }
    
    // MARK: - User Settings
    struct UserSettings: Codable {
        var notificationsEnabled: Bool
        var locationEnabled: Bool
        var darkModeEnabled: Bool
        var language: Language
        var privacySettings: PrivacySettings
        var twoFactorEnabled: Bool
        
        init() {
            self.notificationsEnabled = true
            self.locationEnabled = true
            self.darkModeEnabled = false
            self.language = .turkish
            self.privacySettings = PrivacySettings()
            self.twoFactorEnabled = false
        }
    }
    
    struct PrivacySettings: Codable {
        var showOnlineStatus: Bool
        var showLastSeen: Bool
        var showProfilePhoto: Bool
        var showBio: Bool
        
        init() {
            self.showOnlineStatus = true
            self.showLastSeen = true
            self.showProfilePhoto = true
            self.showBio = true
        }
    }
    
    enum Language: String, Codable {
        case turkish = "tr"
        case english = "en"
    }
    
    private let userSettingsKey = "userSettings_"
    
    func getUserSettings(for username: String) -> UserSettings {
        let key = userSettingsKey + username
        if let data = defaults.data(forKey: key),
           let settings = try? JSONDecoder().decode(UserSettings.self, from: data) {
            return settings
        }
        return UserSettings()
    }
    
    func updateUserSettings(_ settings: UserSettings, for username: String) {
        let key = userSettingsKey + username
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
    
    func updatePrivacySettings(_ privacySettings: PrivacySettings, for username: String) {
        var settings = getUserSettings(for: username)
        settings.privacySettings = privacySettings
        updateUserSettings(settings, for: username)
    }
    
    func toggleNotifications(for username: String) {
        var settings = getUserSettings(for: username)
        settings.notificationsEnabled.toggle()
        updateUserSettings(settings, for: username)
    }
    
    func toggleLocationServices(for username: String) {
        var settings = getUserSettings(for: username)
        settings.locationEnabled.toggle()
        updateUserSettings(settings, for: username)
    }
    
    func toggleDarkMode(for username: String) {
        var settings = getUserSettings(for: username)
        settings.darkModeEnabled.toggle()
        updateUserSettings(settings, for: username)
    }
    
    func updateLanguage(_ language: Language, for username: String) {
        var settings = getUserSettings(for: username)
        settings.language = language
        updateUserSettings(settings, for: username)
    }
    
    func toggleTwoFactor(for username: String) {
        var settings = getUserSettings(for: username)
        settings.twoFactorEnabled.toggle()
        updateUserSettings(settings, for: username)
    }
    
    func removeUser(username: String) {
        var users = getUsers()
        users.removeAll { $0.username == username }
        saveUsers(users)
        if getCurrentUser()?.username == username {
            setCurrentUser(username: nil)
        }
    }
    
    func updateUserPhotos(username: String, photos: [Data]) {
        if var user = getUser(username: username) {
            user.photos = photos
            updateUser(user)
        }
    }
    
    // MARK: - Match Management
    func getPotentialMatches(for username: String) -> [User] {
        let users = getUsers()
        guard let currentUser = getUser(username: username) else { return [] }
        
        return users.filter { user in
            // Kendisi hariç ve tercihlere uygun kullanıcıları filtrele
            user.username != username &&
            matchesPreferences(user: user, preferences: currentUser.matchingPreferences)
        }
    }
    
    private func matchesPreferences(user: User, preferences: MatchingPreferences?) -> Bool {
        guard let prefs = preferences else { return true }
        guard let userInfo = user.personalInfo else { return false }
        
        // Cinsiyet kontrolü
        if prefs.preferredGender != .any && userInfo.gender != prefs.preferredGender {
            return false
        }
        
        // Sigara içme durumu kontrolü
        switch prefs.smokingPreference {
        case .yes:
            if userInfo.smokingStatus == .no { return false }
        case .no:
            if userInfo.smokingStatus != .no { return false }
        case .dontCare:
            break
        }
        
        // Alkol kullanımı kontrolü
        switch prefs.drinkingPreference {
        case .yes:
            if userInfo.drinkingStatus == .no { return false }
        case .no:
            if userInfo.drinkingStatus != .no { return false }
        case .dontCare:
            break
        }
        
        return true
    }
    
    // MARK: - Match Actions
    enum MatchActionType: String, Codable {
        case like, superLike, pass
    }
    
    struct MatchAction: Codable {
        let fromUser: String
        let toUser: String
        let type: MatchActionType
        let timestamp: Date
    }
    
    private let matchActionsKey = "matchActions"
    
    func addMatchAction(fromUser: String, toUser: String, type: MatchActionType) {
        var actions = getMatchActions()
        let newAction = MatchAction(fromUser: fromUser, toUser: toUser, type: type, timestamp: Date())
        actions.append(newAction)
        if let data = try? JSONEncoder().encode(actions) {
            defaults.set(data, forKey: matchActionsKey)
        }
    }
    
    func getMatchActions() -> [MatchAction] {
        if let data = defaults.data(forKey: matchActionsKey),
           let actions = try? JSONDecoder().decode([MatchAction].self, from: data) {
            return actions
        }
        return []
    }
    
    private let dailyLikesKey = "dailyLikes"
    
    func getRemainingDailyLikes(for username: String) -> Int {
        let key = "\(dailyLikesKey)_\(username)_\(Calendar.current.startOfDay(for: Date()))"
        let value = defaults.integer(forKey: key)
        return value == 0 ? 10 : value
    }
    
    private func resetDailyLikes(for username: String) {
        let key = "\(dailyLikesKey)_\(username)_\(Calendar.current.startOfDay(for: Date()))"
        defaults.set(10, forKey: key) // Varsayılan günlük 10 like hakkı
    }
    
    func updateUserBio(username: String, bio: String) {
        if var user = getUser(username: username) {
            user.bio = bio
            updateUser(user)
        }
    }
    
    private func saveUser(_ user: User) {
        var users = getUsers()
        if let index = users.firstIndex(where: { $0.username == user.username }) {
            users[index] = user
            saveUsers(users)
        }
    }
    
    // MARK: - Password Management
    private func getPasswords() -> [String: String] {
        if let data = defaults.data(forKey: passwordsKey),
           let passwords = try? JSONDecoder().decode([String: String].self, from: data) {
            return passwords
        }
        return [:]
    }
    
    private func savePasswords(_ passwords: [String: String]) {
        if let data = try? JSONEncoder().encode(passwords) {
            defaults.set(data, forKey: passwordsKey)
        }
    }
    
    func validatePassword(username: String, password: String) -> Bool {
        let passwords = getPasswords()
        return passwords[username] == password
    }
    
    func updatePassword(username: String, newPassword: String) {
        var passwords = getPasswords()
        passwords[username] = newPassword
        savePasswords(passwords)
    }
    
    func createUserWithPassword(username: String, password: String) -> User {
        let newUser = createUser(username: username)
        var passwords = getPasswords()
        passwords[username] = password
        savePasswords(passwords)
        return newUser
    }
    
    private let matchRequestsKey = "matchRequests"
    
    func getMatchRequests(for username: String) -> [MatchRequest] {
        if let data = defaults.data(forKey: matchRequestsKey),
           let requests = try? JSONDecoder().decode([MatchRequest].self, from: data) {
            return requests.filter { $0.toUser == username }
        }
        return []
    }
    
    func getPendingMatchRequests(for username: String) -> [MatchRequest] {
        return getMatchRequests(for: username).filter { $0.status == .pending }
    }
    
    func acceptMatchRequest(_ request: MatchRequest) {
        var requests = getAllMatchRequests()
        if let index = requests.firstIndex(where: { $0.id == request.id }) {
            requests[index].status = .accepted
            
            // Eşleşme oluştur
            let match = createMatch(between: request.fromUser, and: request.toUser)
            
            // İlk mesajı gönder
            sendMessage(
                senderId: request.fromUser,
                receiverId: request.toUser,
                content: "Merhaba! Eşleşmemiz başarılı oldu. Nasılsın?"
            )
            
            saveMatchRequests(requests)
        }
    }
    
    func rejectMatchRequest(_ request: MatchRequest) {
        var requests = getAllMatchRequests()
        if let index = requests.firstIndex(where: { $0.id == request.id }) {
            requests[index].status = .rejected
            saveMatchRequests(requests)
        }
    }
    
    private func getAllMatchRequests() -> [MatchRequest] {
        if let data = defaults.data(forKey: matchRequestsKey),
           let requests = try? JSONDecoder().decode([MatchRequest].self, from: data) {
            return requests
        }
        return []
    }
    
    private func saveMatchRequests(_ requests: [MatchRequest]) {
        if let data = try? JSONEncoder().encode(requests) {
            defaults.set(data, forKey: matchRequestsKey)
        }
    }
    
    // MARK: - Match Management
    struct Match: Codable, Identifiable {
        let id: String
        let user1: String
        let user2: String
        let timestamp: Date
        var isActive: Bool
    }
    
    func createMatch(between user1: String, and user2: String) -> Match {
        let match = Match(
            id: UUID().uuidString,
            user1: user1,
            user2: user2,
            timestamp: Date(),
            isActive: true
        )
        
        var matches = getAllMatches()
        matches.append(match)
        saveMatches(matches)
        
        return match
    }
    
    func getAllMatches() -> [Match] {
        if let data = defaults.data(forKey: matchesKey),
           let matches = try? JSONDecoder().decode([Match].self, from: data) {
            return matches
        }
        return []
    }
    
    func getActiveMatches(for username: String) -> [Match] {
        return getAllMatches().filter { match in
            (match.user1 == username || match.user2 == username) && match.isActive
        }
    }
    
    func getMatchPartner(for username: String, in match: Match) -> String? {
        if match.user1 == username {
            return match.user2
        } else if match.user2 == username {
            return match.user1
        }
        return nil
    }
    
    private func saveMatches(_ matches: [Match]) {
        if let data = try? JSONEncoder().encode(matches) {
            defaults.set(data, forKey: matchesKey)
        }
    }
    
    func sendMatchRequest(fromUser: String, toUser: String) {
        var requests = getAllMatchRequests()
        // Aynı kullanıcıya daha önce istek atılmışsa tekrar ekleme
        let alreadyExists = requests.contains { $0.fromUser == fromUser && $0.toUser == toUser && $0.status == .pending }
        if alreadyExists { return }
        let newRequest = MatchRequest(
            id: UUID().uuidString,
            fromUser: fromUser,
            toUser: toUser,
            timestamp: Date(),
            status: .pending
        )
        requests.append(newRequest)
        saveMatchRequests(requests)
    }
    
    // MARK: - Mesajı Okundu Olarak İşaretle
    func markMessageAsRead(messageId: String) {
        var messages = getAllMessagesFromDefaults()
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index].isRead = true
            saveMessages(messages)
        }
    }
} 
