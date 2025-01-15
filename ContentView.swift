//
//  ContentView.swift
//  FoodiesApp
//
//  Created by Ali Ayçiçek on 10.01.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Title
                Text("Foodies App")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .padding(.top, 50)
                
                Spacer()
                
                // Main Title and Subtitle
                VStack(spacing: 20) {
                    Text("Find Your Friends\nWith Us")
                        .font(.system(size: 32, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Join with us and socialize with\nmillions of people")
                        .font(.system(size: 16))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
                
                // Dots Indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.black)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 30)
                
                // Get Started Button
                NavigationLink(destination: SignInView()) {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    ContentView()
}
