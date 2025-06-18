import SwiftUI

struct MatchRequest: Identifiable, Codable {
    let id: String
    let fromUser: String
    let toUser: String
    let timestamp: Date
    var status: MatchRequestStatus
}

enum MatchRequestStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

struct MatchRequestsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var requests: [MatchRequest] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if requests.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Bekleyen match isteğiniz yok")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(requests) { request in
                        MatchRequestRow(request: request) { updatedRequest in
                            requests.removeAll { $0.id == updatedRequest.id }
                        }
                    }
                }
            }
            .navigationTitle("Match İstekleri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadRequests()
        }
        .alert("Hata", isPresented: .constant(errorMessage != nil)) {
            Button("Tamam") {
                errorMessage = nil
            }
        } message: {
            if let error = errorMessage {
                Text(error)
            }
        }
    }
    
    private func loadRequests() {
        isLoading = true
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            requests = UserDefaultsManager.shared.getPendingMatchRequests(for: currentUser.username)
        }
        isLoading = false
    }
}

struct MatchRequestRow: View {
    let request: MatchRequest
    let onUpdate: (MatchRequest) -> Void
    @State private var showingProfile = false
    @State private var navigateToChat = false
    @State private var requestingUser: UserDefaultsManager.User?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let user = requestingUser {
                    if let photos = user.photos, let photoData = photos.first, let image = UIImage(data: photoData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.personalInfo?.name ?? user.username)
                            .font(.headline)
                        Text("Seni beğendi")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        if let foodPreferences = user.appPreferences?.foodPreferences, !foodPreferences.isEmpty {
                            Text("Yemek Zevkleri: \(foodPreferences.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if let hobbies = user.appPreferences?.hobbies, !hobbies.isEmpty {
                            Text("Hobiler: \(hobbies.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                        VStack(alignment: .leading) {
                            Text("Yükleniyor...")
                                .font(.headline)
                            Text("...")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                    .redacted(reason: .placeholder)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        var updatedRequest = request
                        updatedRequest.status = .rejected
                        UserDefaultsManager.shared.rejectMatchRequest(updatedRequest)
                        onUpdate(updatedRequest)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 30))
                    }
                    
                    Button(action: {
                        var updatedRequest = request
                        updatedRequest.status = .accepted
                        UserDefaultsManager.shared.acceptMatchRequest(updatedRequest)
                        onUpdate(updatedRequest)
                        if let currentUser = UserDefaultsManager.shared.getCurrentUser(),
                           let partnerUser = requestingUser {
                            Task {
                                UserDefaultsManager.shared.sendMessage(senderId: currentUser.id, receiverId: partnerUser.id, content: "Merhaba! Eşleştiğimize sevindim!")
                                print("Otomatik 'Merhaba' mesajı gönderildi.")
                                await MainActor.run {
                                    navigateToChat = true
                                }
                            }
                        } else {
                            Task {
                                while requestingUser == nil {
                                    try? await Task.sleep(nanoseconds: 100_000_000)
                                }
                                if let currentUser = UserDefaultsManager.shared.getCurrentUser(),
                                   let partnerUser = requestingUser {
                                    UserDefaultsManager.shared.sendMessage(senderId: currentUser.id, receiverId: partnerUser.id, content: "Merhaba! Eşleştiğimize sevindim!")
                                    print("Otomatik 'Merhaba' mesajı gönderildi.")
                                    await MainActor.run {
                                        navigateToChat = true
                                    }
                                }
                            }
                        }
                    }) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 30))
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .onTapGesture {
            if requestingUser != nil {
                showingProfile = true
            }
        }
        .sheet(isPresented: $showingProfile) {
            if let user = requestingUser {
                ProfileView(userToDisplay: user, isCurrentUser: false)
            }
        }
        .background(
            NavigationLink(destination: navigateToChatDetailView(), isActive: $navigateToChat) { EmptyView() }
        )
        .task {
            await loadRequestingUser()
        }
    }
    
    @ViewBuilder
    private func navigateToChatDetailView() -> some View {
        if let user = requestingUser,
           let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            let chatUser = User(from: user)
            let currentChatUser = User(from: currentUser)
            MessagesView(viewModel: ChatViewModel(currentUser: currentChatUser, partner: chatUser))
        } else {
            ProgressView()
        }
    }
    
    private func loadRequestingUser() async {
        guard requestingUser == nil else { return }
        
        let user = UserDefaultsManager.shared.getUser(username: request.fromUser)
        
        await MainActor.run {
            self.requestingUser = user
        }
    }
} 
struct MatchRequestsView_Previews: PreviewProvider {
    static var previews: some View {
        MatchRequestsView()
    }
}
