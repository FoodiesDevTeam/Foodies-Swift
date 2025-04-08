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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                // Segment Control
                Picker("Match Type", selection: $matchType) {
                    Text("Best Match").tag(MatchType.bestMatch)
                    Text("Close To You").tag(MatchType.closeToYou)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .onChange(of: matchType) { _ in
                    loadMatches()
                }
            }
            .background(
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            if let currentMatch = potentialMatches.indices.contains(currentIndex) ? potentialMatches[currentIndex] : nil {
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Photo
                        if let photos = currentMatch.photos, !photos.isEmpty,
                           let photoData = photos.first,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 450)
                                .clipped()
                        }
                        
                        // User Info with Purple Background
                        VStack(alignment: .leading, spacing: 12) {
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
                        .padding()
                        .background(Color.purple)
                        
                        // Action Buttons
                        HStack(spacing: 40) {
                            Button(action: { handlePass() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 30))
                                    .foregroundColor(.red)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            
                            Button(action: { handleSuperLike() }) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.yellow)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            
                            Button(action: { handleLike() }) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.green)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                        }
                        .padding(.vertical, 20)
                        .background(Color.white)
                    }
                }
            } else {
                Spacer()
                Text("Daha fazla eşleşme yok")
                    .font(.title)
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            loadMatches()
            updateRemainingLikes()
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
                        Text("Başarılı Eşleşme!")
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
                                Text("Sonra")
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
                                Text("Buluşma Ayarla")
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
    
    private func loadMatches() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            potentialMatches = UserDefaultsManager.shared.getPotentialMatches(for: currentUser.username)
            if matchType == .closeToYou {
                if let userCity = currentUser.personalInfo?.city {
                    potentialMatches = potentialMatches.filter { $0.personalInfo?.city == userCity }
                }
            }
            // Reset current index when switching match types
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
