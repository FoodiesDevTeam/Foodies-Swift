import SwiftUI

enum MatchType {
    case bestMatch
    case closeToYou
}

struct MatchView: View {
    let matchType: MatchType
    @State private var currentIndex = 0
    @State private var potentialMatches: [UserDefaultsManager.User] = []
    @State private var remainingLikes = 3
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                // Segment Control
                Picker("Match Type", selection: .constant(matchType == .bestMatch ? 0 : 1)) {
                    Text("Best Match").tag(0)
                    Text("Close To You").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
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
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 30))
                                    .foregroundColor(.yellow)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                            
                            Button(action: { handleLike() }) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 30))
                                    .foregroundColor(.green)
                                    .frame(width: 60, height: 60)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                        }
                        .padding(.vertical, 20)
                        .background(Color.black)
                    }
                }
            } else {
                Spacer()
                Text("No more matches")
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
    }
    
    private func loadMatches() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            potentialMatches = UserDefaultsManager.shared.getPotentialMatches(for: currentUser.username)
            if matchType == .closeToYou {
                if let userCity = currentUser.personalInfo?.city {
                    potentialMatches = potentialMatches.filter { $0.personalInfo?.city == userCity }
                }
            }
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
        moveToNextMatch()
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
