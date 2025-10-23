//
//  SplashScreen.swift
//  Poppy
//
//  Splash screen displayed on app launch
//

import SwiftUI

struct SplashScreen: View {
    @Binding var isActive: Bool
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    let theme = Theme.daylight
    
    var body: some View {
        ZStack {
            // Background gradient
            theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Your Illustrator splash image
                // Replace "splash_logo" with your actual asset name
                Image("splash_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Optional: Loading indicator or tagline
                Text("Pop. Score. Repeat.")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.7))
                    .opacity(opacity)
            }
            .padding(40)
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    opacity = 0.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isActive = true
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var isActive = false
    SplashScreen(isActive: $isActive)
}