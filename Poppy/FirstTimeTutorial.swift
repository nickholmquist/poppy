//
//  FirstTimeTutorial.swift
//  Poppy
//
//  Learn-by-doing tutorial with contextual pointer overlays
//

import SwiftUI

// MARK: - Tutorial Progress Tracking

extension UserDefaults {
    var hasCompletedFirstGame: Bool {
        get { bool(forKey: "poppy.tutorial.firstGame") }
        set { set(newValue, forKey: "poppy.tutorial.firstGame") }
    }
    
    var hasChangedTheme: Bool {
        get { bool(forKey: "poppy.tutorial.theme") }
        set { set(newValue, forKey: "poppy.tutorial.theme") }
    }
    
    var hasChangedTime: Bool {
        get { bool(forKey: "poppy.tutorial.time") }
        set { set(newValue, forKey: "poppy.tutorial.time") }
    }
    
    var hasOpenedMenu: Bool {
        get { bool(forKey: "poppy.tutorial.menu") }
        set { set(newValue, forKey: "poppy.tutorial.menu") }
    }
    
    var hasCompletedTutorial: Bool {
        hasCompletedFirstGame && hasChangedTheme &&
        hasChangedTime && hasOpenedMenu
    }
    
    // For first game, we want to default to 10s
    var shouldUseFirstGameDuration: Bool {
        !hasCompletedFirstGame
    }
}

// MARK: - Tutorial Step Enum

enum TutorialStep: CaseIterable {
    case tapStart
    case changeTheme
    case changeTime
    case openMenu
    
    var message: String {
        switch self {
        case .tapStart:
            return "👆 Tap START to begin!"
        case .changeTheme:
            return "✨ Tap to change colors!"
        case .changeTime:
            return "⏱️ Try a longer game!"
        case .openMenu:
            return "⚙️ More options here!"
        }
    }
    
    var arrowDirection: ArrowDirection {
        switch self {
        case .tapStart:
            return .down
        case .changeTheme:
            return .bottomRight
        case .changeTime:
            return .down
        case .openMenu:
            return .bottomLeft
        }
    }
}

enum ArrowDirection {
    case down
    case up
    case left
    case right
    case bottomLeft
    case bottomRight
    case topLeft
    case topRight
    
    var rotation: Angle {
        switch self {
        case .down: return .degrees(0)
        case .up: return .degrees(180)
        case .left: return .degrees(90)
        case .right: return .degrees(-90)
        case .bottomLeft: return .degrees(45)
        case .bottomRight: return .degrees(-45)
        case .topLeft: return .degrees(135)
        case .topRight: return .degrees(-135)
        }
    }
}

// MARK: - Tutorial Overlay

struct TutorialPointerOverlay: View {
    let theme: Theme
    let step: TutorialStep
    let targetFrame: CGRect  // Frame of the element to point to
    @Binding var isShowing: Bool
    
    @State private var pulseScale: CGFloat = 1.0
    @State private var arrowOpacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // Dimmed background - tap to dismiss
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Optional: allow skipping
                    // dismissOverlay()
                }
            
            // Pointer card positioned relative to target
            VStack(spacing: 12) {
                // Arrow pointing to target
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(theme.accent)
                    .rotationEffect(step.arrowDirection.rotation)
                    .opacity(arrowOpacity)
                    .scaleEffect(pulseScale)
                
                // Message card
                Text(step.message)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textDark)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.bgTop)
                            .shadow(color: .black.opacity(0.3), radius: 15, y: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(theme.accent.opacity(0.3), lineWidth: 2)
                    )
            }
            .position(pointerPosition)
        }
        .transition(.opacity)
        .onAppear {
            startPulseAnimation()
        }
    }
    
    // Calculate where to position the pointer based on target frame
    private var pointerPosition: CGPoint {
        switch step {
        case .tapStart:
            // Position above START button
            return CGPoint(
                x: targetFrame.midX,
                y: targetFrame.minY - 80
            )
        case .changeTheme:
            // Position to the right of theme dot
            return CGPoint(
                x: targetFrame.maxX + 80,
                y: targetFrame.midY + 40
            )
        case .changeTime:
            // Position above time button
            return CGPoint(
                x: targetFrame.midX,
                y: targetFrame.minY - 80
            )
        case .openMenu:
            // Position to the left of menu button
            return CGPoint(
                x: targetFrame.minX - 80,
                y: targetFrame.midY + 40
            )
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: 1.0)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.15
            arrowOpacity = 1.0
        }
    }
    
    private func dismissOverlay() {
        HapticsManager.shared.light()
        withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
        }
    }
}

// MARK: - Tutorial Manager View

/// Wrapper view that manages tutorial state and shows appropriate overlays
struct TutorialManager: View {
    let theme: Theme
    let startButtonFrame: CGRect
    let themeButtonFrame: CGRect
    let timeButtonFrame: CGRect
    let menuButtonFrame: CGRect
    
    @State private var currentStep: TutorialStep? = nil
    @State private var showOverlay = false
    
    var body: some View {
        Group {
            if let step = currentStep, showOverlay {
                TutorialPointerOverlay(
                    theme: theme,
                    step: step,
                    targetFrame: frameForStep(step),
                    isShowing: $showOverlay
                )
            }
        }
        .onAppear {
            checkTutorialProgress()
        }
        .onChange(of: UserDefaults.standard.hasCompletedFirstGame) { _, completed in
            if completed {
                advanceToNextStep()
            }
        }
        .onChange(of: UserDefaults.standard.hasChangedTheme) { _, changed in
            if changed {
                advanceToNextStep()
            }
        }
        .onChange(of: UserDefaults.standard.hasChangedTime) { _, changed in
            if changed {
                advanceToNextStep()
            }
        }
        .onChange(of: UserDefaults.standard.hasOpenedMenu) { _, opened in
            if opened {
                advanceToNextStep()
            }
        }
    }
    
    private func frameForStep(_ step: TutorialStep) -> CGRect {
        switch step {
        case .tapStart: return startButtonFrame
        case .changeTheme: return themeButtonFrame
        case .changeTime: return timeButtonFrame
        case .openMenu: return menuButtonFrame
        }
    }
    
    private func checkTutorialProgress() {
        // Determine which step to show based on completion
        if !UserDefaults.standard.hasCompletedFirstGame {
            currentStep = .tapStart
            showOverlay = true
        } else if !UserDefaults.standard.hasChangedTheme {
            // Show theme overlay after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentStep = .changeTheme
                showOverlay = true
            }
        } else if !UserDefaults.standard.hasChangedTime {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentStep = .changeTime
                showOverlay = true
            }
        } else if !UserDefaults.standard.hasOpenedMenu {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentStep = .openMenu
                showOverlay = true
            }
        }
    }
    
    private func advanceToNextStep() {
        // Hide current overlay
        showOverlay = false
        
        // After brief delay, show next overlay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkTutorialProgress()
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var showing = true
    
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()
        
        TutorialPointerOverlay(
            theme: .daylight,
            step: .tapStart,
            targetFrame: CGRect(x: 100, y: 600, width: 200, height: 80),
            isShowing: $showing
        )
    }
}
