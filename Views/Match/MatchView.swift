import SwiftUI

enum MatchType {
    case bestMatch
    case closeToYou
}

struct MatchView: View {
    @State private var matchType: MatchType = .bestMatch
    @State private var currentIndex = 0
    @State private var potentialMatches: [UserDefaultsManager.User] = []
    @State private var remainingLikes = 3
    @State private var showMatchAlert = false
    @State private var matchedUser: UserDefaultsManager.User?
    @State private var showMeetingSetup = false
    @State private var showProfileDetail = false
    @State private var selectedUser: UserDefaultsManager.User?
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemBackground).opacity(0.8), Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                ZStack {
                    LinearGradient(
                        colors: [.pink, .purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .ignoresSafeArea(edges: .top)
                    HStack {
                        Spacer()
                        Text(LanguageManager.shared.localizedString("Matches"))
                            .font(.title2)
                            .bold()
                            .foregroundStyle(Constants.Design.mainGradient)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .frame(height: 50)
                
                // Kalan beğeni hakkı
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                        Text("Kalan beğeni: \(remainingLikes)")
                            .font(.subheadline)
                            .foregroundColor(.pink)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(16)
                    .padding(.trailing, 16)
                }
                .padding(.top, 8)
                
                Spacer()
                
                if potentialMatches.isEmpty {
                    VStack {
                        Spacer()
                        Text(LanguageManager.shared.localizedString("no_more_matches"))
                            .font(.title)
                            .foregroundColor(.gray)
                        Spacer()
                    }
                } else {
                    if let currentMatch = potentialMatches.indices.contains(currentIndex) ? potentialMatches[currentIndex] : nil {
                        VStack(spacing: 20) {
                            // Profil Fotoğrafı
                            Button(action: {
                                selectedUser = currentMatch
                                showProfileDetail = true
                            }) {
                                if let photos = currentMatch.photos, !photos.isEmpty,
                                   let photoData = photos.first,
                                   let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 220, height: 300)
                                        .clipShape(RoundedRectangle(cornerRadius: 32))
                                        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
                                } else {
                                    RoundedRectangle(cornerRadius: 32)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 220, height: 300)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 60))
                                                .foregroundColor(.gray)
                                        )
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Bilgiler
                            VStack(spacing: 8) {
                                if let info = currentMatch.personalInfo {
                                    Text("\(info.firstName) \(info.lastName), \(calculateAge(from: info.birthDate))")
                                        .font(.title2)
                                        .bold()
                                        .foregroundStyle(Constants.Design.mainGradient)
                                    if let city = info.city {
                                        Text(city)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                if let bio = currentMatch.bio, !bio.isEmpty {
                                    Text(bio)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 16)
                                }
                                // Hobiler ve yemek tercihleri
                                if let preferences = currentMatch.appPreferences {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(preferences.hobbies + preferences.foodPreferences, id: \ .self) { interest in
                                                Text(interest)
                                                    .font(.caption)
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 6)
                                                    .background(Constants.Design.mainGradient)
                                                    .cornerRadius(16)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                    }
                                }
                            }
                            .padding(.top, 8)
                            
                            // Butonlar
                            HStack(spacing: 40) {
                                Button(action: handlePass) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.red)
                                        .padding()
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }
                                Button(action: handleLike) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 36, weight: .bold))
                                        .foregroundColor(.pink)
                                        .padding()
                                        .background(Color.white)
                                        .clipShape(Circle())
                                        .shadow(radius: 4)
                                }
                            }
                            .padding(.top, 16)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 32)
                                .fill(Color.white.opacity(0.85))
                                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        )
                        .padding(.horizontal, 24)
                        .transition(.asymmetric(insertion: .scale, removal: .opacity))
                    }
                }
                Spacer()
            }
            .sheet(isPresented: $showProfileDetail) {
                if let user = selectedUser {
                    ProfileDetailModal(user: user)
                }
            }
            .onAppear {
                loadPotentialMatches()
            }
            .overlay(
                ZStack {
                    if showMatchAlert, let user = matchedUser, let info = user.personalInfo {
                        Color.black.opacity(0.6)
                            .ignoresSafeArea()
                        VStack(spacing: 20) {
                            Text(LanguageManager.shared.localizedString("successful_match"))
                                .font(.title)
                                .bold()
                                .foregroundColor(.white)
                            Spacer()
                            if let photoData = user.photos?.first,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 150)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            } else {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: 150, height: 150)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            }
                            Text("\(info.firstName) \(info.lastName) ile eşleştiniz!")
                                .font(.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            Spacer()
                            HStack(spacing: 20) {
                                Button(action: {
                                    showMatchAlert = false
                                }) {
                                    Text(LanguageManager.shared.localizedString("later"))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.gray)
                                        .cornerRadius(12)
                                }
                                Button(action: {
                                    showMatchAlert = false
                                    showMeetingSetup = true
                                }) {
                                    Text(LanguageManager.shared.localizedString("schedule_meeting"))
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.pink)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                        .frame(width: 300, height: 400)
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(20)
                        .shadow(radius: 10)
                    }
                }
            )
            .sheet(isPresented: $showMeetingSetup) {
                if let matchedUser = matchedUser {
                    ScheduleMeetingView(otherUser: matchedUser)
                }
            }
        }
    }
    
    private func loadPotentialMatches() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            loadMatches()
            updateRemainingLikes()
        }
    }
    
    private func loadMatches() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            var matches = UserDefaultsManager.shared.getPotentialMatches(for: currentUser.username)
            let matchActions = UserDefaultsManager.shared.getMatchActions()
            let interactedUserIds = matchActions
                .filter { $0.fromUser == currentUser.username }
                .map { $0.toUser }
            matches = matches.filter { user in
                !interactedUserIds.contains(user.username)
            }
            if matchType == .closeToYou {
                if let userCity = currentUser.personalInfo?.city {
                    matches = matches.filter { $0.personalInfo?.city == userCity }
                }
            }
            potentialMatches = matches
            currentIndex = 0
        }
    }
    
    private func updateRemainingLikes() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            remainingLikes = UserDefaultsManager.shared.getRemainingDailyLikes(for: currentUser.username)
        }
    }
    
    private func handlePass() {
        guard let currentUser = UserDefaultsManager.shared.getCurrentUser(),
              potentialMatches.indices.contains(currentIndex) else { return }
        let match = potentialMatches[currentIndex]
        UserDefaultsManager.shared.addMatchAction(
            fromUser: currentUser.username,
            toUser: match.username,
            type: .pass
        )
        moveToNextMatch()
    }
    
    private func handleLike() {
        guard let currentUser = UserDefaultsManager.shared.getCurrentUser(),
              potentialMatches.indices.contains(currentIndex) else { return }
        let match = potentialMatches[currentIndex]
        // Karşı tarafa match isteği gönder
        UserDefaultsManager.shared.sendMatchRequest(fromUser: currentUser.username, toUser: match.username)
        UserDefaultsManager.shared.addMatchAction(
            fromUser: currentUser.username,
            toUser: match.username,
            type: .like
        )
        checkForMatch(currentUser: currentUser, potentialMatch: match)
        moveToNextMatch()
    }
    
    private func checkForMatch(currentUser: UserDefaultsManager.User, potentialMatch: UserDefaultsManager.User) {
        let matchActions = UserDefaultsManager.shared.getMatchActions()
        let isMatched = matchActions.contains { action in
            action.fromUser == potentialMatch.username &&
            action.toUser == currentUser.username &&
            (action.type == .like || action.type == .superLike)
        }
        if isMatched {
            matchedUser = potentialMatch
            showMatchAlert = true
            _ = UserDefaultsManager.shared.createMeeting(
                creatorId: currentUser.username,
                participantId: potentialMatch.username,
                restaurantName: "Daha sonra seçilecek",
                location: "Daha sonra seçilecek",
                date: Date()
            )
        }
    }
    
    private func moveToNextMatch() {
        withAnimation {
            currentIndex += 1
        }
    }
    
    private func calculateAge(from date: Date) -> Int {
        Calendar.current.dateComponents([.year], from: date, to: Date()).year ?? 0
    }
}

struct ProfileDetailModal: View {
    let user: UserDefaultsManager.User
    var body: some View {
        VStack(spacing: 16) {
            if let photos = user.photos, let photoData = photos.first, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
            }
            if let info = user.personalInfo {
                Text("\(info.firstName) \(info.lastName), \(Calendar.current.dateComponents([.year], from: info.birthDate, to: Date()).year ?? 0)")
                    .font(.title2)
                    .bold()
                if let city = info.city {
                    Text(city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            if let bio = user.bio, !bio.isEmpty {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            if let preferences = user.appPreferences {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hobiler ve Tercihler:")
                        .font(.headline)
                    WrapHStack(items: preferences.hobbies + preferences.foodPreferences) { interest in
                        Text(interest)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Constants.Design.mainGradient)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 8)
            }
            Spacer()
        }
        .padding()
    }
}

struct WrapHStack<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let items: Data
    let content: (Data.Element) -> Content
    @State private var totalHeight = CGFloat.zero
    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: totalHeight)
    }
    private func generateContent(in g: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items), id: \ .self) { item in
                content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if abs(width - d.width) > g.size.width {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0 // last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if item == items.last {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }
    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ViewHeightKey.self, value: geometry.size.height)
        }
        .onPreferenceChange(ViewHeightKey.self) { value in
            binding.wrappedValue = value
        }
    }
}
private struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ScheduleMeetingView: View {
    let otherUser: UserDefaultsManager.User
    @State private var meetingDate = Date()
    @State private var meetingCreated = false
    @Environment(\.presentationMode) var presentationMode
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Buluşma Tarihi Seçin")) {
                    DatePicker("Buluşma tarihi", selection: $meetingDate, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(GraphicalDatePickerStyle())
                }
                Section {
                    if let info = otherUser.personalInfo {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                            Text("\(info.firstName) \(info.lastName)")
                        }
                    }
                    Button(action: createMeeting) {
                        Text("Buluşma Oluştur")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
            }
            .navigationBarTitle("Buluşma Ayarla", displayMode: .inline)
            .navigationBarItems(trailing: Button("Kapat") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $meetingCreated) {
                Alert(
                    title: Text("Buluşma Oluşturuldu"),
                    message: Text("Buluşmanız başarıyla oluşturuldu. Buluşma tarihinde QR kod ile doğrulama yapmayı unutmayın."),
                    dismissButton: .default(Text("Tamam")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    private func createMeeting() {
        guard let currentUser = UserDefaultsManager.shared.getCurrentUser() else { return }
        // Buluşma oluştur
        _ = UserDefaultsManager.shared.createMeeting(
            creatorId: currentUser.username,
            participantId: otherUser.username,
            restaurantName: "Daha sonra seçilecek",
            location: "Daha sonra seçilecek",
            date: meetingDate
        )
        // Eşleşme (match) de oluştur
        _ = UserDefaultsManager.shared.createMatch(between: currentUser.username, and: otherUser.username)
        meetingCreated = true
    }
}

struct MatchsView_Previews: PreviewProvider {
    static var previews: some View {
        MatchView()
    }
}
