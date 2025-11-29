//
//  FirstTimeTutorial.swift
//  Poppy
//
//  Tutorial with spotlight cutout effect - Responsive to all device sizes
//

import SwiftUI

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
    
    var tutorialCompleted: Bool {
        get { bool(forKey: "poppy.tutorial.completed") }
        set { set(newValue, forKey: "poppy.tutorial.completed") }
    }
    
    var hasCompletedTutorial: Bool {
        hasCompletedFirstGame && hasChangedTheme &&
        hasChangedTime && hasOpenedMenu
    }
    
    var shouldUseFirstGameDuration: Bool {
        !hasCompletedFirstGame
    }
}

enum TutorialStep: CaseIterable {
    case tapStart
    case changeTheme
    case changeTime
    case openMenu
    
    var message: String {
        switch self {
        case .tapStart:
            return "Tap START to begin your first game!"
        case .changeTheme:
            return "Tap here to change colors!"
        case .changeTime:
            return "Try a longer game duration!"
        case .openMenu:
            return "Open menu for more options!"
        }
    }
}

// MARK: - Spotlight Cutout Shape

struct SpotlightCutout: Shape {
    let cutoutRect: CGRect
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        
        let spotlight = Path(
            roundedRect: cutoutRect,
            cornerRadius: cornerRadius
        )
        
        path = path.subtracting(spotlight)
        return path
    }
}

// MARK: - Tutorial Message (Arrow locked to cutout, message separate)

struct TutorialMessage: View {
    let theme: Theme
    let step: TutorialStep
    let cutoutRect: CGRect
    let screenSize: CGSize
    
    @State private var pulseScale: CGFloat = 1.0
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var messageFontSize: CGFloat {
        isIPad ? 24 : 20
    }
    
    private let arrowSize: CGFloat = 34
    private let arrowToMessageGap: CGFloat = 10
    
    // Different gaps for different steps AND devices
    private var arrowToCutoutGap: CGFloat {
        if step == .tapStart {
            return isIPad ? 30 : 60  // Space above START button
        } else {
            return isIPad ? -20 : -50  // Space below top bar elements
        }
    }
    
    var body: some View {
        ZStack {
            // Arrow - locked to cutout
            arrowView
                .position(x: arrowX, y: arrowY)
            
            // Message - positioned based on alignment
            messageBubble
                .position(x: messageX, y: messageY)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 0.9)
                .repeatForever(autoreverses: true)
            ) {
                pulseScale = 1.2
            }
        }
    }
    
    // MARK: - Arrow Position (locked to cutout)
    
    private var arrowX: CGFloat {
        cutoutRect.midX
    }
    
    private var arrowY: CGFloat {
        if step == .tapStart {
            // Arrow above cutout, pointing down
            return cutoutRect.minY - arrowToCutoutGap - arrowSize/2
        } else {
            // Arrow below cutout, pointing up
            return cutoutRect.maxY + arrowToCutoutGap + arrowSize/2
        }
    }
    
    // MARK: - Message Position
    
    private var messageX: CGFloat {
        switch step {
        case .tapStart, .changeTime:
            // Centered under/over arrow
            return cutoutRect.midX
        case .changeTheme:
            // Message's left edge aligns with arrow's left edge
            let arrowLeftEdge = cutoutRect.midX - arrowSize/2
            return arrowLeftEdge + estimatedMessageWidth/2
        case .openMenu:
            // Message's right edge aligns with arrow's right edge
            let arrowRightEdge = cutoutRect.midX + arrowSize/2
            return arrowRightEdge - estimatedMessageWidth/2
        }
    }
    
    private var messageY: CGFloat {
        if step == .tapStart {
            // Message above arrow
            return arrowY - arrowSize/2 - arrowToMessageGap - estimatedMessageHeight/2
        } else {
            // Message below arrow
            return arrowY + arrowSize/2 + arrowToMessageGap + estimatedMessageHeight/2
        }
    }
    
    private var estimatedMessageWidth: CGFloat {
        min(CGFloat(step.message.count) * (messageFontSize * 0.52) + 48, 340)
    }
    
    private var estimatedMessageHeight: CGFloat {
        messageFontSize + 32
    }
    
    // MARK: - Arrow View
    
    private var arrowView: some View {
        Image(systemName: step == .tapStart ? "arrowtriangle.down.fill" : "arrowtriangle.up.fill")
            .font(.system(size: arrowSize, weight: .bold))
            .foregroundStyle(theme.accent)
            .scaleEffect(pulseScale)
            .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
            .shadow(color: theme.accent.opacity(0.6), radius: 12, y: 0)
    }
    
    // MARK: - Message Bubble
    
    private var messageBubble: some View {
        Text(step.message)
            .font(.system(size: messageFontSize, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(theme.accent)
                    .shadow(color: .black.opacity(0.6), radius: 25, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.white.opacity(0.4), lineWidth: 2.5)
            )
    }
}

// MARK: - Tutorial Manager

struct TutorialManager: View {
    let theme: Theme
    let layout: LayoutController
    let startButtonFrame: CGRect
    let themeButtonFrame: CGRect
    let timeButtonFrame: CGRect
    let menuButtonFrame: CGRect
    
    @Binding var hasCompletedFirstGame: Bool
    @Binding var hasCompletedFirstRound: Bool
    @Binding var hasChangedTheme: Bool
    @Binding var hasChangedTime: Bool
    @Binding var hasOpenedMenu: Bool
    @Binding var showTimePicker: Bool
    @Binding var showMenu: Bool
    
    @State private var currentStep: TutorialStep? = nil
    @State private var showOverlay = false
    @State private var isInitialized = false
    @State private var hasAdvancedFromTime = false
    @State private var hasAdvancedFromMenu = false
    @State private var overlayOpacity: Double = 1.0
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Show overlay when we have an active step
                if let step = currentStep, isInitialized {
                    // Layer 1: Dimmed overlay with spotlight cutout
                    SpotlightCutout(
                        cutoutRect: cutoutRect(for: step),
                        cornerRadius: cornerRadiusForStep(step)
                    )
                    .fill(Color.black.opacity(0.7 * overlayOpacity))
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(1)
                    .transition(.opacity)
                    
                    // Layer 2: Tutorial message
                    TutorialMessage(
                        theme: theme,
                        step: step,
                        cutoutRect: cutoutRect(for: step),
                        screenSize: geo.size
                    )
                    .opacity(overlayOpacity)
                    .zIndex(2)
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                initializeTutorial()
            }
        }
        .onChange(of: showTimePicker) { oldVal, newVal in
            if !oldVal && newVal {
                // Time picker opening - fade out tutorial smoothly
                withAnimation(.easeOut(duration: 0.3)) {
                    overlayOpacity = 0.0
                }
            } else if oldVal && !newVal {
                // Time picker closing
                if hasChangedTime && currentStep == .changeTime && !hasAdvancedFromTime {
                    hasAdvancedFromTime = true
                    
                    AnalyticsManager.shared.trackTutorialStep(
                        step: "change_time",
                        completed: true
                    )
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentStep = .openMenu
                            overlayOpacity = 1.0
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeIn(duration: 0.3)) {
                            overlayOpacity = 1.0
                        }
                    }
                }
            }
        }
        .onChange(of: showMenu) { oldVal, newVal in
            if !oldVal && newVal {
                withAnimation(.easeOut(duration: 0.3)) {
                    overlayOpacity = 0.0
                }
            } else if oldVal && !newVal {
                if hasOpenedMenu && currentStep == .openMenu && !hasAdvancedFromMenu {
                    hasAdvancedFromMenu = true
                    
                    AnalyticsManager.shared.trackTutorialStep(
                        step: "open_menu",
                        completed: true
                    )
                    
                    AnalyticsManager.shared.trackTutorialCompleted()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.6)) {
                            overlayOpacity = 0.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            currentStep = nil
                            UserDefaults.standard.tutorialCompleted = true
                        }
                    }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeIn(duration: 0.3)) {
                            overlayOpacity = 1.0
                        }
                    }
                }
            }
        }
        .onChange(of: hasCompletedFirstGame) { _, completed in
            guard isInitialized else { return }
            if completed && currentStep == .tapStart {
                AnalyticsManager.shared.trackTutorialStep(
                    step: "first_game",
                    completed: true
                )
                
                withAnimation(.easeOut(duration: 0.6)) {
                    overlayOpacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    currentStep = nil
                }
            }
        }
        .onChange(of: hasCompletedFirstRound) { _, completed in
            guard isInitialized else { return }
            if completed && !hasChangedTheme {
                withAnimation(.easeIn(duration: 0.5)) {
                    currentStep = .changeTheme
                    overlayOpacity = 1.0
                }
            }
        }
        .onChange(of: hasChangedTheme) { _, changed in
            guard isInitialized else { return }
            if changed && currentStep == .changeTheme {
                AnalyticsManager.shared.trackTutorialStep(
                    step: "change_theme",
                    completed: true
                )
                
                withAnimation(.easeInOut(duration: 0.4)) {
                    currentStep = .changeTime
                }
            }
        }
    }
    
    private func initializeTutorial() {
        if UserDefaults.standard.tutorialCompleted {
            isInitialized = true
            return
        }
        
        let tutorialComplete = hasCompletedFirstGame && hasCompletedFirstRound &&
                              hasChangedTheme && hasChangedTime && hasOpenedMenu
        
        if !tutorialComplete {
            if !hasCompletedFirstGame {
                currentStep = .tapStart
                overlayOpacity = 0.0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeIn(duration: 0.5)) {
                        overlayOpacity = 1.0
                    }
                }
            }
            else if hasCompletedFirstRound {
                if !hasChangedTheme {
                    currentStep = .changeTheme
                    overlayOpacity = 0.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeIn(duration: 0.5)) {
                            overlayOpacity = 1.0
                        }
                    }
                } else if !hasChangedTime {
                    currentStep = .changeTime
                    overlayOpacity = 0.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeIn(duration: 0.5)) {
                            overlayOpacity = 1.0
                        }
                    }
                } else if !hasOpenedMenu {
                    currentStep = .openMenu
                    overlayOpacity = 0.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeIn(duration: 0.5)) {
                            overlayOpacity = 1.0
                        }
                    }
                }
            }
        } else {
            UserDefaults.standard.tutorialCompleted = true
        }
        
        isInitialized = true
    }
    
    private func frameForStep(_ step: TutorialStep) -> CGRect {
        switch step {
        case .tapStart: return startButtonFrame
        case .changeTheme: return themeButtonFrame
        case .changeTime: return timeButtonFrame
        case .openMenu: return menuButtonFrame
        }
    }
    
    // Calculate cutout rect with appropriate padding for each step
    private func cutoutRect(for step: TutorialStep) -> CGRect {
        let frame = frameForStep(step)
        
        switch step {
        case .tapStart:
            // Use actual button dimensions from layout
            let actualButtonWidth = layout.startButtonWidth * 0.75
            let actualButtonHeight = layout.startButtonHeight
            let layerOffset = layout.startButtonLayerOffset
            
            // Total visual height includes the 3D base
            let totalVisualHeight = actualButtonHeight + layerOffset
            
            // Padding around the button
            let padding: CGFloat = 12
            
            // Center horizontally on the frame's center
            let centerX = frame.midX
            let cutoutWidth = actualButtonWidth + (padding * 2)
            let cutoutX = centerX - (cutoutWidth / 2)
            
            let cutoutHeight = totalVisualHeight + (padding * 2)
            let cutoutY = frame.minY - padding - layerOffset
            
            return CGRect(
                x: cutoutX,
                y: cutoutY,
                width: cutoutWidth,
                height: cutoutHeight
            )
            
        case .changeTheme, .openMenu:
            // Circle buttons - add small padding
            let padding: CGFloat = 8
            return CGRect(
                x: frame.minX - padding,
                y: frame.minY - padding,
                width: frame.width + (padding * 2),
                height: frame.height + (padding * 2)
            )
            
        case .changeTime:
            // Pill button - small padding
            let padding: CGFloat = 6
            return CGRect(
                x: frame.minX - padding,
                y: frame.minY - padding,
                width: frame.width + (padding * 2),
                height: frame.height + (padding * 2)
            )
        }
    }
    
    private func cornerRadiusForStep(_ step: TutorialStep) -> CGFloat {
        switch step {
        case .tapStart: return 28
        case .changeTheme: return 50  // Circle
        case .changeTime: return 24   // Pill shape
        case .openMenu: return 50     // Circle
        }
    }
}

#Preview {
    @Previewable @State var showing = true
    
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()
        
        // Mock button frame
        let cutoutRect = CGRect(x: 140, y: 570, width: 120, height: 55)
        
        SpotlightCutout(
            cutoutRect: cutoutRect,
            cornerRadius: 12
        )
        .fill(Color.black.opacity(0.7))
        .ignoresSafeArea()
        
        TutorialMessage(
            theme: .daylight,
            step: .tapStart,
            cutoutRect: cutoutRect,
            screenSize: CGSize(width: 393, height: 800)
        )
    }
}
