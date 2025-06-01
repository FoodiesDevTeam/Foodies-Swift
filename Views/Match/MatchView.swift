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
    @State private var translation: CGSize = .zero
    @State private var rotationAngle: Angle = .zero
    @State private var showLikeOverlay = false
    @State private var showPassOverlay = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                // Header background
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 100)
                .edgesIgnoringSafeArea(.top)
                
                // Header Content
                VStack {
                    HStack {
                        Spacer()
                        
                        Text(LanguageManager.shared.localizedString("Matches"))
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 40)
            }
            
            // Content
            if potentialMatches.isEmpty {
                VStack {
                    Spacer()
                    Text(LanguageManager.shared.localizedString("no_more_matches"))
                        .font(.title)
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Photo
                        if let currentMatch = potentialMatches.indices.contains(currentIndex) ? potentialMatches[currentIndex] : nil {
                            if let photos = currentMatch.photos, !photos.isEmpty,
                               let photoData = photos.first,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 450)
                                    .clipped()
                            }
                        }
                        
                        // User Info with Purple Background
                        VStack(alignment: .leading, spacing: 12) {
                            if let currentMatch = potentialMatches.indices.contains(currentIndex) ? potentialMatches[currentIndex] : nil {
                                if let info = currentMatch.personalInfo {
                                    // Name and Age
                                    Text("\(info.firstName) \(info.lastName), \(calculateAge(from: info.birthDate))")
                                        .font(.title)
                                        .bold()
                                        .foregroundColor(.white)
                                    
                                    // Bio
                                    if let bio = currentMatch.bio, !bio.isEmpty {
                                        Text(bio)
                                            .foregroundColor(.white.opacity(0.9))
                                            .font(.body)
                                    }
                                    
                                    // Interests
                                    if let preferences = currentMatch.appPreferences {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 8) {
                                                ForEach(preferences.hobbies + preferences.foodPreferences, id: \.self) { interest in
                                                    Text(interest)
                                                        .font(.subheadline)
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 16)
                                                        .padding(.vertical, 8)
                                                        .background(Color.white.opacity(0.2))
                                                        .cornerRadius(20)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.purple)
                    }
                    .offset(x: translation.width, y: 0)
                    .rotationEffect(rotationAngle, anchor: .bottom)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                translation = value.translation
                                rotationAngle = Angle(degrees: Double(translation.width / 20.0))
                                
                                if translation.width > 50 {
                                    showLikeOverlay = true
                                    showPassOverlay = false
                                } else if translation.width < -50 {
                                    showPassOverlay = true
                                    showLikeOverlay = false
                                } else {
                                    showLikeOverlay = false
                                    showPassOverlay = false
                                }
                            }
                            .onEnded { value in
                                let dragThreshold: CGFloat = 100
                                if abs(value.translation.width) > dragThreshold {
                                    if value.translation.width > dragThreshold {
                                        handleLike()
                                    } else {
                                        handlePass()
                                    }
                                    resetCardPosition()
                                } else {
                                    withAnimation(.spring()) {
                                        resetCardPosition()
                                    }
                                }
                                showLikeOverlay = false
                                showPassOverlay = false
                            }
                    )
                    .overlay(
                        ZStack {
                            if showLikeOverlay {
                                Text("LIKE")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                    .padding()
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(10)
                            }
                            if showPassOverlay {
                                Text("NOPE")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .padding()
                                    .background(Color.white.opacity(0.7))
                                    .cornerRadius(10)
                            }
                        }
                    )
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            loadPotentialMatches()
        }
        .sheet(isPresented: $showMeetingSetup) {
            if let matchedUser = matchedUser {
                ScheduleMeetingView(otherUser: matchedUser)
            }
        }
        .overlay(
            ZStack {
                if showMatchAlert, let user = matchedUser, let info = user.personalInfo {
                    // Match Alert Overlay
                    Color.black.opacity(0.6)
                        .edgesIgnoringSafeArea(.all)
                    
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
    
    private func handleSuperLike() {
        guard remainingLikes > 0,
              let currentUser = UserDefaultsManager.shared.getCurrentUser(),
              potentialMatches.indices.contains(currentIndex) else { return }
        let match = potentialMatches[currentIndex]
        UserDefaultsManager.shared.addMatchAction(
            fromUser: currentUser.username,
            toUser: match.username,
            type: .superLike
        )
        
        // Eşleşme kontrolü
        checkForMatch(currentUser: currentUser, potentialMatch: match)
        
        updateRemainingLikes()
        moveToNextMatch()
    }
    
    private func handleLike() {
        guard let currentUser = UserDefaultsManager.shared.getCurrentUser(),
              potentialMatches.indices.contains(currentIndex) else { return }
        let match = potentialMatches[currentIndex]
        UserDefaultsManager.shared.addMatchAction(
            fromUser: currentUser.username,
            toUser: match.username,
            type: .like
        )
        
        // Eşleşme kontrolü
        checkForMatch(currentUser: currentUser, potentialMatch: match)
        
        moveToNextMatch()
    }
    
    private func checkForMatch(currentUser: UserDefaultsManager.User, potentialMatch: UserDefaultsManager.User) {
        // Karşı taraf da bizi beğenmiş mi kontrol et
        let matchActions = UserDefaultsManager.shared.getMatchActions()
        let isMatched = matchActions.contains { action in
            action.fromUser == potentialMatch.username &&
            action.toUser == currentUser.username &&
            (action.type == .like || action.type == .superLike)
        }
        
        if isMatched {
            // Eşleşme başarılı
            matchedUser = potentialMatch
            showMatchAlert = true
            
            // Otomatik olarak bir buluşma oluştur
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
    
    private func resetCardPosition() {
        translation = .zero
        rotationAngle = .zero
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
        
        meetingCreated = true
    }
}

struct MatchsView_Previews: PreviewProvider {
    static var previews: some View {
        MatchView()
    }
}
