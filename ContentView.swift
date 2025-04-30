//
//  ContentView.swift
//  FoodiesApp
//
//  Created by Ali Ayçiçek on 10.01.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if isAuthenticated {
                MainTabView()
            } else {
                NavigationView {
                    VStack(spacing: Constants.Design.defaultSpacing) {
                        Text("Foodies App")
                            .font(.system(size: Constants.FontSizes.title1, weight: .bold))
                            .foregroundStyle(Constants.Design.mainGradient)
                            .padding(.top, 50)
                        
                        Spacer()
                        
                        VStack(spacing: Constants.Design.defaultPadding) {
                            Text("Yemek Arkadaşını\nBul")
                                .font(.system(size: Constants.FontSizes.title2, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Text("Bize katıl ve milyonlarca\ninsanla sosyalleş")
                                .font(.system(size: Constants.FontSizes.body))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                        }

                        NavigationLink(destination: SignInView()) {
                            Text("Başla")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Constants.Design.mainGradient)
                                .cornerRadius(Constants.Design.cornerRadius)
                        }
                        .padding(.horizontal, Constants.Design.defaultPadding)
                        .padding(.vertical, 50)
                    }
                }
                .navigationBarHidden(true)
            }
        }
        .onAppear {
            checkAuthStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: Constants.NotificationNames.userDidLogout)) { _ in
            isAuthenticated = false
        }
    }
    
    private func checkAuthStatus() {
        Task {
            if let _ = try? await SupabaseService.shared.getCurrentUser() {
                isAuthenticated = true
            } else {
                isAuthenticated = false
            }
        }
    }
}

#Preview {
    ContentView()
}
