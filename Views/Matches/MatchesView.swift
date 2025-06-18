import SwiftUI

struct MatchesView: View {
    @State private var matches: [Match] = []
    @State private var showQRScanner = false
    @State private var showMyQRCode = false
    @State private var pulsate = false
    @State private var selectedMeeting: UserDefaultsManager.Meeting?
    @State private var showQROptions = false
    @State private var showMatchRequests = false
    @State private var pendingRequests: [MatchRequest] = []
    @StateObject private var languageManager = LanguageManager.shared
    @State private var showChatDetail = false
    @State private var selectedUser: UserDefaultsManager.User?
    
    // Fonksiyon burada, body'nin dışında!
    private func getUniqueMatches() -> [Match] {
        var uniqueUsernames = Set<String>()
        var uniqueMatches: [Match] = []
        for match in matches {
            if !uniqueUsernames.contains(match.username) {
                uniqueUsernames.insert(match.username)
                uniqueMatches.append(match)
            }
        }
        return uniqueMatches
    }
    
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
                        Text(LanguageManager.shared.localizedString("matches"))
                            .font(.title2)
                            .bold()
                            .foregroundStyle(Constants.Design.mainGradient)
                        Spacer()
                        HStack(spacing: 20) {
                            Button(action: {
                                loadPendingRequests()
                                showMatchRequests = true
                            }) {
                                ZStack {
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20))
                                    if !pendingRequests.isEmpty {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 6, y: -6)
                                    }
                                }
                            }
                            Button(action: {
                                showQROptions = true
                            }) {
                                Image(systemName: "qrcode")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 50)
                
                // Content
                if matches.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(getUniqueMatches()) { match in
                                if let user = UserDefaultsManager.shared.getUser(username: match.username) {
                                    HStack(spacing: 8) {
                                        Button(action: {
                                            selectedUser = user
                                            showChatDetail = true
                                        }) {
                                            ChatBoxCard(user: user)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        Button(action: {
                                            // QR doğrulama ekranını aç
                                            showQROptions = true
                                        }) {
                                            Image(systemName: "qrcode.viewfinder")
                                                .foregroundColor(.purple)
                                                .font(.system(size: 28))
                                                .padding(8)
                                                .background(Color.white)
                                                .clipShape(Circle())
                                                .shadow(radius: 2)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerView(onScan: handleScannedQRCode)
        }
        .sheet(isPresented: $showMyQRCode) {
            MyQRCodeView(currentUser: UserDefaultsManager.shared.getCurrentUser())
        }
        .sheet(isPresented: $showMatchRequests) {
            MatchRequestsView()
        }
        .sheet(isPresented: $showChatDetail) {
            if let user = selectedUser, let currentUser = UserDefaultsManager.shared.getCurrentUser() {
                let chatUser = User(from: user)
                let currentChatUser = User(from: currentUser)
                MessagesView(viewModel: ChatViewModel(currentUser: currentChatUser, partner: chatUser))
            }
        }
        .actionSheet(isPresented: $showQROptions) {
            ActionSheet(
                title: Text(LanguageManager.shared.localizedString("qr_operations")),
                message: Text(LanguageManager.shared.localizedString("qr_verification_message")),
                buttons: [
                    .default(Text(LanguageManager.shared.localizedString("create_qr"))) {
                        showMyQRCode = true
                    },
                    .default(Text(LanguageManager.shared.localizedString("scan_qr"))) {
                        showQRScanner = true
                    },
                    .cancel(Text(LanguageManager.shared.localizedString("match_rating_cancel")))
                ]
            )
        }
        .onAppear {
            loadMatches()
            loadPendingRequests()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageDidChange"))) { _ in
            loadMatches()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 100))
                .foregroundColor(.gray.opacity(0.7))
                .padding()
                .background(
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 180, height: 180)
                )
            
            Text(LanguageManager.shared.localizedString("no_matches"))
                .font(.title2)
                .fontWeight(.bold)
            
            Text(LanguageManager.shared.localizedString("explore_message"))
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .foregroundColor(.gray)
            
            Button(action: {
                // Navigating to match screen
            }) {
                Text(LanguageManager.shared.localizedString("explore"))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.pink, .purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    private func loadMatches() {
        guard let currentUser = UserDefaultsManager.shared.getCurrentUser() else { return }
        
        // UserDefaultsManager'dan buluşmaları yükle
        let meetings = UserDefaultsManager.shared.getMeetingsForUser(userId: currentUser.username)
        
        var loadedMatches: [Match] = []
        
        // Her buluşma için bir Match oluştur
        for meeting in meetings {
            // Buluşmadaki diğer kullanıcıyı bul
            let otherUsername = meeting.creatorId == currentUser.username ? meeting.participantId : meeting.creatorId
            
            if let otherUser = UserDefaultsManager.shared.getUser(username: otherUsername),
               let otherUserInfo = otherUser.personalInfo {
                
                // Buluşma için derecelendirmeleri al
                let meetingRatings = UserDefaultsManager.shared.getRatingsForMeeting(meetingId: meeting.id)
                    .filter { $0.type == .punctuality || $0.type == .experience }
                
                // Match oluştur
                let match = Match(
                    id: meeting.id,
                    username: otherUsername,
                    name: "\(otherUserInfo.name) \(otherUserInfo.surname)",
                    meetingDate: meeting.date,
                    isVerified: meeting.isVerified,
                    profileImage: otherUser.photos?.first,
                    ratings: meetingRatings
                )
                
                loadedMatches.append(match)
            }
        }
        
        // Tarihe göre sırala (en yeniden en eskiye)
        matches = loadedMatches.sorted(by: { $0.meetingDate > $1.meetingDate })
    }
    
    private func loadPendingRequests() {
        if let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            pendingRequests = UserDefaultsManager.shared.getPendingMatchRequests(for: currentUser.username)
        }
    }
    
    private func handleScannedQRCode(_ code: String) {
        // QR kod işleme mantığı
    }
    
    private func rateMatch(match: Match, rating: Rating) {
        // Derecelendirme işleme mantığı
    }
}

struct ChatBoxCard: View {
    let user: UserDefaultsManager.User
    var body: some View {
        HStack(spacing: 16) {
            if let photoData = user.photos?.first, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.gray)
                    )
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(user.personalInfo?.name ?? user.username)
                    .font(.headline)
                if let city = user.personalInfo?.city {
                    Text(city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.07), radius: 4, x: 0, y: 2)
    }
}

struct MatchCard: View {
    let match: Match
    let onRateMatch: (Rating) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Match başlık ve bilgiler
            HStack {
                Group {
                    if let profileImage = match.profileImage,
                       let uiImage = UIImage(data: profileImage) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .frame(width: 70, height: 70)
                            .background(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                    }
                }
                .shadow(radius: 2)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(match.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if match.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                        }
                    }
                    
                    Text(LanguageManager.shared.localizedString("meeting_date") + ": \(formattedDate(match.meetingDate))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            
            Divider()
                .padding(.horizontal, 16)
            
            // Değerlendirme bölümü
            if match.isVerified {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Değerlendirmeleriniz")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    // Değerlendirme seçenekleri
                    VStack(spacing: 12) {
                        // İlk satır - Dakiklik ve Profil Uygunluğu
                        HStack(spacing: 8) {
                            RatingButton(
                                type: .punctuality,
                                isPositive: true,
                                isSelected: isRatingSelected(.punctuality, isPositive: true),
                                disableOpposites: isRatingSelected(.punctuality, isPositive: false),
                                onTap: onRateMatch
                            )
                            
                            RatingButton(
                                type: .punctuality,
                                isPositive: false,
                                isSelected: isRatingSelected(.punctuality, isPositive: false),
                                disableOpposites: isRatingSelected(.punctuality, isPositive: true),
                                onTap: onRateMatch
                            )
                            
                            Spacer()
                            
                            RatingButton(
                                type: .profile,
                                isPositive: true,
                                isSelected: isRatingSelected(.profile, isPositive: true),
                                disableOpposites: isRatingSelected(.profile, isPositive: false),
                                onTap: onRateMatch
                            )
                            
                            RatingButton(
                                type: .profile,
                                isPositive: false,
                                isSelected: isRatingSelected(.profile, isPositive: false),
                                disableOpposites: isRatingSelected(.profile, isPositive: true),
                                onTap: onRateMatch
                            )
                        }
                        .padding(.horizontal, 16)
                        
                        // İkinci satır - Genel Deneyim
                        HStack(spacing: 8) {
                            RatingButton(
                                type: .experience,
                                isPositive: true,
                                isSelected: isRatingSelected(.experience, isPositive: true),
                                disableOpposites: isRatingSelected(.experience, isPositive: false),
                                onTap: onRateMatch
                            )
                            
                            RatingButton(
                                type: .experience,
                                isPositive: false,
                                isSelected: isRatingSelected(.experience, isPositive: false),
                                disableOpposites: isRatingSelected(.experience, isPositive: true),
                                onTap: onRateMatch
                            )
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
            } else {
                HStack {
                    Text("Buluşmayı doğrulamak için QR kod okutun")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Image(systemName: "qrcode.viewfinder")
                        .foregroundColor(.blue)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 2)
    }
    
    private func isRatingSelected(_ type: UserDefaultsManager.RatingType, isPositive: Bool) -> Bool {
        return match.ratings.contains { rating in
            rating.type == type && (isPositive ? rating.score >= 4.0 : rating.score < 4.0)
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct RatingButton: View {
    let type: UserDefaultsManager.RatingType
    let isPositive: Bool
    let isSelected: Bool
    let disableOpposites: Bool
    let onTap: (Rating) -> Void
    
    var body: some View {
        Button(action: {
            onTap(Rating(type: type, isPositive: isPositive))
        }) {
            VStack(spacing: 6) {
                Image(systemName: ratingIcon)
                    .font(.system(size: 20))
                
                Text(ratingLabel)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 65)
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? .white : ratingColor)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? ratingColor : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ratingColor, lineWidth: 1)
            )
        }
        .disabled(disableOpposites && !isSelected)
        .opacity(disableOpposites && !isSelected ? 0.4 : 1)
    }
    
    private var ratingColor: Color {
        return isPositive ? .green : .red
    }
    
    private var ratingIcon: String {
        switch type {
        case .punctuality:
            return isPositive ? "clock.fill" : "clock.badge.exclamationmark.fill"
        case .profile:
            return isPositive ? "person.fill.checkmark" : "person.fill.xmark"
        case .experience:
            return isPositive ? "hand.thumbsup.fill" : "hand.thumbsdown.fill"
        }
    }
    
    private var ratingLabel: String {
        switch type {
        case .punctuality:
            return isPositive ? "Dakik" : "Dakik Değil"
        case .profile:
            return isPositive ? "Profil Doğru" : "Profil Yanlış"
        case .experience:
            return isPositive ? "İyi Deneyim" : "Kötü Deneyim"
        }
    }
}

struct QRScannerView: View {
    let onScan: (String) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = false
    @State private var scanSuccess = false
    @State private var animateScanLine = false
    @State private var scanLineOffset: CGFloat = -130
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 60)
                
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                            .padding(10)
                            .background(Color.black.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    Text("QR Kod Tarayıcı")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Boşluk için görünmez buton
                    Color.clear
                        .frame(width: 40, height: 40)
                        .padding(.trailing)
                }
            }
            
            // Content
            VStack(spacing: 25) {
                Text("Buluşmanızı doğrulamak için karşı tarafın QR kodunu tarayın")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 30)
                
                // Kamera görünümü - Gerçek uygulamada kamera olacak
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.1))
                    
                    // QR kod görünümü
                    Image(systemName: "qrcode.viewfinder")
                        .font(.system(size: 150))
                        .foregroundColor(scanSuccess ? .green.opacity(0.8) : .blue.opacity(0.6))
                        .scaleEffect(scanSuccess ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: scanSuccess)
                    
                    // Tarama çizgisi animasyonu
                    if !scanSuccess {
                        Rectangle()
                            .fill(Color.red.opacity(0.5))
                            .frame(height: 2)
                            .offset(y: scanLineOffset)
                            .shadow(color: .red, radius: 5)
                    }
                    
                    // Başarılı tarama animasyonu
                    if scanSuccess {
                        ZStack {
                            Circle()
                                .stroke(Color.green, lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(width: 280, height: 280)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(scanSuccess ? Color.green : Color.white, lineWidth: 2)
                )
                .padding(.vertical, 20)
                
                // Tarama durumu metni
                Text(scanSuccess ? "Doğrulama Başarılı!" : isScanning ? "Taranıyor..." : "Taramayı Başlat")
                    .font(.headline)
                    .foregroundColor(scanSuccess ? .green : isScanning ? .blue : .gray)
                
                // Test için butonlar (gerçek uygulamada gerekli olmaz)
                if !scanSuccess {
                    Button(action: {
                        startScanning()
                    }) {
                        HStack {
                            Image(systemName: isScanning ? "stop.fill" : "qrcode.viewfinder")
                            Text(isScanning ? "Taramayı Durdur" : "Taramayı Başlat")
                        }
                        .padding()
                        .frame(width: 220)
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Kapat")
                            .padding()
                            .frame(width: 220)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .transition(.scale)
                }
                
                // Test için ekstra buton - sadece geliştirme amaçlı
                if !scanSuccess && !isScanning {
                    Button("Test: QR Kod Tara") {
                        startScanning()
                        
                        // Test için 2 saniye sonra taramayı tamamla
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            handleSuccessfulScan("FOODIES_MEETING:1:1629400000")
                        }
                    }
                    .font(.footnote)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.white)
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            // Otomatik taramayı başlat
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                startScanning()
            }
        }
    }
    
    private func startScanning() {
        isScanning.toggle()
        
        if isScanning {
            // Tarama çizgisi animasyonunu başlat
            withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: true)) {
                scanLineOffset = 130
            }
        } else {
            // Animasyonu durdur
            scanLineOffset = -130
        }
    }
    
    private func handleSuccessfulScan(_ code: String) {
        // Taramayı durdur
        isScanning = false
        
        // Başarılı animasyonunu göster
        withAnimation {
            scanSuccess = true
        }
        
        // Kodu işle
        onScan(code)
        
        // 2 saniye sonra ekranı kapat
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct MyQRCodeView: View {
    @Environment(\.presentationMode) var presentationMode
    let currentUser: UserDefaultsManager.User?
    @State private var qrCodeImage: UIImage?
    @State private var isGenerating = true
    @State private var remainingTime = 900 // 15 dakika = 900 saniye
    @State private var qrCodeSize: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 60)
                
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .medium))
                            .padding(10)
                            .background(Color.black.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    Text("Buluşma QR Kodunuz")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Boşluk için görünmez buton
                    Color.clear
                        .frame(width: 40, height: 40)
                        .padding(.trailing)
                }
            }
            
            ScrollView {
                VStack(spacing: 25) {
                    if let currentUser = currentUser, let info = currentUser.personalInfo {
                        // Kullanıcı bilgisi
                        VStack(spacing: 6) {
                            // Profil resmi
                            if let photoData = currentUser.photos?.first,
                               let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                    .frame(width: 80, height: 80)
                                    .background(
                                        LinearGradient(
                                            colors: [.pink, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Circle())
                            }
                            
                            Text("\(info.firstName) \(info.lastName)")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .padding(.top, 8)
                        }
                        .padding(.top, 30)
                    }
                    
                    Text("Bu QR kodu karşınızdaki kişiye okutarak buluşmanızı doğrulayın")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // QR Code
                    ZStack {
                        if let qrCodeImage = qrCodeImage {
                            Image(uiImage: qrCodeImage)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .padding(16)
                                .background(Color.white)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.1), radius: 5)
                                .scaleEffect(qrCodeSize)
                                .onAppear {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                                        qrCodeSize = 1.0
                                    }
                                }
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray, style: StrokeStyle(lineWidth: 1, dash: [5]))
                                .frame(width: 250, height: 250)
                                .overlay(
                                    VStack {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                            .scaleEffect(1.5)
                                        
                                        Text("QR Kod Oluşturuluyor...")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                            .padding(.top, 12)
                                    }
                                )
                        }
                    }
                    .frame(width: 280, height: 280)
                    .padding(.vertical)
                    
                    // Geri sayım gösterimi
                    if qrCodeImage != nil {
                        VStack(spacing: 2) {
                            Text("Kalan Süre")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(timeString(from: remainingTime))
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(remainingTime < 60 ? .red : .blue)
                                .frame(width: 120)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        }
                        .onAppear {
                            // Her saniye geri sayım
                            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                                if remainingTime > 0 {
                                    remainingTime -= 1
                                } else {
                                    timer.invalidate()
                                }
                            }
                        }
                    }
                    
                    // Yenileme butonu
                    if qrCodeImage != nil {
                        Button(action: {
                            withAnimation {
                                qrCodeImage = nil
                                qrCodeSize = 0
                                isGenerating = true
                                remainingTime = 900
                            }
                            // Yeni QR kod oluştur
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                generateQRCode()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("QR Kodu Yenile")
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.top, 5)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color.white)
        }
        .edgesIgnoringSafeArea(.top)
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        guard let currentUser = currentUser else { return }
        
        // Gerçek uygulamada, sunucudan bir meeting kodu alınır
        // Bu örnekte basit bir kod oluşturuyoruz
        let meetingCode = "FOODIES_MEETING:\(currentUser.username):\(Int(Date().timeIntervalSince1970))"
        
        if let qrCodeData = meetingCode.data(using: .utf8),
           let qrFilter = CIFilter(name: "CIQRCodeGenerator") {
            qrFilter.setValue(qrCodeData, forKey: "inputMessage")
            
            if let qrImage = qrFilter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledQrImage = qrImage.transformed(by: transform)
                let context = CIContext()
                
                if let cgImage = context.createCGImage(scaledQrImage, from: scaledQrImage.extent) {
                    // 1 saniye sonra QR kodu göster (animasyon için yapay bir gecikme)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            self.qrCodeImage = UIImage(cgImage: cgImage)
                            self.isGenerating = false
                        }
                    }
                }
            }
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// Match veri modeli
struct Match: Identifiable {
    let id: String
    let username: String
    let name: String
    let meetingDate: Date
    var isVerified: Bool
    let profileImage: Data?
    var ratings: [UserDefaultsManager.Rating]
}

// Değerlendirme veri modeli
struct Rating {
    let type: UserDefaultsManager.RatingType
    let isPositive: Bool
    
    var score: Double {
        isPositive ? 5.0 : 1.0
    }
    
    init(type: UserDefaultsManager.RatingType, isPositive: Bool) {
        self.type = type
        self.isPositive = isPositive
    }
    
    init(type: UserDefaultsManager.RatingType, score: Double) {
        self.type = type
        self.isPositive = score >= 4.0
    }
}

struct MatchesView_Previews: PreviewProvider {
    static var previews: some View {
        MatchesView()
    }
} 
