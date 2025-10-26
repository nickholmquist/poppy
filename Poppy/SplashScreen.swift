//
//  SplashScreen.swift
//  Poppy
//
//  Splash screen displayed on app launch
//

import SwiftUI

struct SplashScreen: View {
    @Binding var isActive: Bool
    @State private var scale: CGFloat = 1.0  // Start at full size
    @State private var opacity: Double = 1.0  // Start at full opacity
    
    let theme = Theme.daylight
    
    var body: some View {
        ZStack {
            // Your full splash image with background and texture already included
            Image("splash_logo")
                .resizable()
                .scaledToFill()  // Fill entire screen edge-to-edge
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            // No fade-in animation - splash is immediately visible!
            
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
