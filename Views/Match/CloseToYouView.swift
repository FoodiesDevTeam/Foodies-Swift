import SwiftUI

struct CloseToYouView: View {
    @State private var messages: [UserDefaultsManager.Message] = []
    @State private var showFilterSheet = false
    @State private var filter = UserDefaultsManager.MessageFilter()
    @State private var showReportSheet = false
    @State private var selectedMessageId: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ZStack {
                LinearGradient(
                    colors: [.pink, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                HStack {
                    Text("Close To You")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showFilterSheet = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    }
                }
                .padding()
            }
            .frame(height: 60)
            
            // Messages List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(messages) { message in
                        MessageView(message: message) {
                            selectedMessageId = message.id
                            showReportSheet = true
                        }
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterView(filter: $filter)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showReportSheet) {
            if let messageId = selectedMessageId {
                ReportView(messageId: messageId)
                    .presentationDetents([.medium])
            }
        }
        .onAppear {
            loadMessages()
        }
    }
    
    private func loadMessages() {
        messages = UserDefaultsManager.shared.getMessages(filter: filter)
    }
}

struct MessageView: View {
    let message: UserDefaultsManager.Message
    let onReport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Info
            HStack {
                if let photoData = message.senderPhotoData,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 40)
                }
                
                VStack(alignment: .leading) {
                    Text(message.senderName)
                        .font(.headline)
                    Text("\(Int.random(in: 20...40)) min ago")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: onReport) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
            }
            
            // Message Content
            Text(message.text)
                .font(.body)
            
            // Message Photo if exists
            if let photoData = message.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct FilterView: View {
    @Binding var filter: UserDefaultsManager.MessageFilter
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Age Range")) {
                    HStack {
                        Text("Min Age: \(filter.minAge)")
                        Slider(value: Binding(
                            get: { Double(filter.minAge) },
                            set: { filter.minAge = Int($0) }
                        ), in: 18...Double(filter.maxAge))
                    }
                    
                    HStack {
                        Text("Max Age: \(filter.maxAge)")
                        Slider(value: Binding(
                            get: { Double(filter.maxAge) },
                            set: { filter.maxAge = Int($0) }
                        ), in: Double(filter.minAge)...99)
                    }
                }
                
                Section(header: Text("Distance")) {
                    HStack {
                        Text("Max Distance: \(filter.maxDistance)km")
                        Slider(value: Binding(
                            get: { Double(filter.maxDistance) },
                            set: { filter.maxDistance = Int($0) }
                        ), in: 1...100)
                    }
                }
                
                Section(header: Text("Gender")) {
                    Picker("Gender", selection: $filter.gender) {
                        Text("All").tag(UserDefaultsManager.Gender.any)
                        Text("Male").tag(UserDefaultsManager.Gender.male)
                        Text("Female").tag(UserDefaultsManager.Gender.female)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Filters")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

struct ReportView: View {
    let messageId: String
    @Environment(\.dismiss) var dismiss
    @State private var selectedReason: UserDefaultsManager.ReportReason?
    
    var body: some View {
        NavigationView {
            List(UserDefaultsManager.ReportReason.allCases, id: \.self) { reason in
                Button(action: {
                    selectedReason = reason
                    reportMessage()
                    dismiss()
                }) {
                    HStack {
                        Text(reason.rawValue)
                        Spacer()
                        if selectedReason == reason {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Report Message")
            .navigationBarItems(
                trailing: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
    
    private func reportMessage() {
        if let reason = selectedReason,
           let currentUser = UserDefaultsManager.shared.getCurrentUser() {
            UserDefaultsManager.shared.reportMessage(
                messageId: messageId,
                reportedBy: currentUser.username,
                reason: reason.rawValue
            )
        }
    }
}
