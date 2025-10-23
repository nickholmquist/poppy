//
//  TutorialOverlay.swift
//  Poppy
//
//  Simple first-launch tutorial overlay
//

import SwiftUI

struct TutorialOverlay: View {
    let theme: Theme
    @Binding var isShowing: Bool
    
    @State private var currentPage = 0
    private let totalPages = 5
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Content area
                TabView(selection: $currentPage) {
                    // Page 1: Tap the dots
                    tutorialPage(
                        emoji: "🎯",
                        title: "Tap the Pink Dots",
                        description: "Hit Start to Begin. Watch for dots that light up and tap them as quickly as possible!"
                    )
                    .tag(0)
                    
                    // Page 2: Race the clock
                    tutorialPage(
                        emoji: "⚡",
                        title: "Race Against Time",
                        description: "You have limited time to tap as many dots as possible. How fast are you?"
                    )
                    .tag(1)
                    
                    // Page 3: Press POP
                    tutorialPage(
                        emoji: "🚀",
                        title: "Press POP Fast",
                        description: "When all dots are pressed, hit the big POP button to reset the board to continue popping before time is up!"
                    )
                    .tag(2)
                    
                    // Page 4: Customize your game
                    tutorialPage(
                        emoji: "🎨",
                        title: "Customize Your Game",
                        description: "Tap the theme dot in the top left to change colors. Tap the time to adjust how much time you have to play!"
                    )
                    .tag(3)
                    
                    // Page 5: Beat your high scores
                    tutorialPage(
                        emoji: "🏆",
                        title: "Can You Beat Your High Scores?",
                        description: "Track your best scores for each time limit. Challenge yourself to improve with every round you play!"
                    )
                    .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: 450)
                
                // Bottom buttons
                HStack(spacing: 16) {
                    if currentPage < totalPages - 1 {
                        Button("Skip") {
                            dismissTutorial()
                        }
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white.opacity(0.1))
                        )
                        
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(theme.accent)
                        )
                    } else {
                        Button("Let's Play!") {
                            dismissTutorial()
                        }
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(theme.accent)
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: 500)
        }
        .transition(.opacity)
    }
    
    @ViewBuilder
    private func tutorialPage(emoji: String, title: String, description: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text(emoji)
                .font(.system(size: 80))
                .padding(.bottom, 8)
            
            Text(title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Text(description)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private func dismissTutorial() {
        // Save that user has seen tutorial
        UserDefaults.standard.set(true, forKey: "hasSeenTutorial")
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Dismiss with animation
        withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
        }
    }
}

// Helper to check if tutorial should show
extension UserDefaults {
    var hasSeenTutorial: Bool {
        get { bool(forKey: "hasSeenTutorial") }
        set { set(newValue, forKey: "hasSeenTutorial") }
    }
}

#Preview {
    @Previewable @State var showing = true
    
    ZStack {
        Color.blue.ignoresSafeArea()
        
        if showing {
            TutorialOverlay(theme: .daylight, isShowing: $showing)
        }
    }
}
