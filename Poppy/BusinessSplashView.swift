//
//  BusinessSplashView.swift
//  Poppy
//
//  Island Twig Studios splash screen
//

import SwiftUI

struct BusinessSplashView: View {
    var onComplete: () -> Void
    
    @State private var backgroundOpacity: Double = 0
    @State private var logoOpacity: Double = 0
    @State private var logoScale: CGFloat = 0.85
    
    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
            
            // Optional: Add grain texture overlay if you have it
            // GrainOverlay(opacity: 0.08)
            //     .ignoresSafeArea()
            //     .opacity(backgroundOpacity)
            
            // Logo image - you'll need to add "islandtwig_logo" to Assets
            Image("islandtwig_logo")
                .resizable()
                .scaledToFit()
                .frame(width: logoSize.width, height: logoSize.height)
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
        }
        .onAppear {
            animateIn()
            
            // Total duration: 2.3s (animate in 0.7s + hold 1.2s + fade out 0.4s)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.3) {
                animateOut()
            }
        }
    }
    
    // Device-specific logo sizing
    private var logoSize: CGSize {
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        if isIPad {
            return CGSize(width: 280, height: 360)
        } else {
            return CGSize(width: 200, height: 260)
        }
    }
    
    private func animateIn() {
        // Background fades in quickly
        withAnimation(.easeOut(duration: 0.4)) {
            backgroundOpacity = 1.0
        }
        
        // Logo animates in after slight delay with scale + fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                logoOpacity = 1.0
                logoScale = 1.0
            }
        }
    }
    
    private func animateOut() {
        withAnimation(.easeOut(duration: 0.5)) {
            backgroundOpacity = 0
            logoOpacity = 0
        }
        
        // Call completion after fade completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
    }
}

#Preview {
    BusinessSplashView(onComplete: {
        print("Preview completed")
    })
}