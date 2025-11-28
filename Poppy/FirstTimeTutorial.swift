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

// MARK: - Tutorial Message (Positioned Relative to Cutout)

struct TutorialMessage: View {
    let theme: Theme
    let step: TutorialStep
    let cutoutRect: CGRect  // The cutout rect we're pointing at
    let screenSize: CGSize
    
    @State private var pulseScale: CGFloat = 1.0
    
    // Determine if message should appear above or below cutout
    private var showAboveTarget: Bool {
        cutoutRect.midY > screenSize.height / 2
    }
    
    private var messageFontSize: CGFloat {
        UIDevice.current.userInterfaceIdiom == .pad ? 24 : 20
    }
    
    var body: some View {
        VStack(spacing: 6) {
            if showAboveTarget {
                // Message first, then arrow pointing down
                messageBubble
                
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(theme.accent)
                    .scaleEffect(pulseScale)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                    .shadow(color: theme.accent.opacity(0.6), radius: 12, y: 0)
            } else {
                // Arrow pointing up first, then message
                // Arrow should be positioned over the cutout
                HStack {
                    if step == .openMenu {
                        Spacer()
                    }
                    
                    Image(systemName: "arrowtriangle.up.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(theme.accent)
                        .scaleEffect(pulseScale)
                        .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                        .shadow(color: theme.accent.opacity(0.6), radius: 12, y: 0)
                    
                    if step == .changeTheme {
                        Spacer()
                    }
                }
                .frame(width: messageWidth)
                
                messageBubble
            }
        }
        .fixedSize()  // Let VStack size to its content
        .position(x: xPosition, y: yPosition)
    }
    
    // Estimated message width for arrow alignment
    private var messageWidth: CGFloat {
        return min(CGFloat(step.message.count) * (messageFontSize * 0.55) + 48, 380)
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
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.9)
                    .repeatForever(autoreverses: true)
                ) {
                    pulseScale = 1.2
                }
            }
    }
    
    // MARK: - Positioning
    
    private var xPosition: CGFloat {
        switch step {
        case .tapStart:
            // Centered on screen
            return screenSize.width / 2
        case .changeTheme:
            // Message aligned LEFT - arrow will be on left side pointing at theme button
            // Position so left edge of message is near left edge with padding
            return messageWidth / 2 + 20
        case .changeTime:
            // Centered on screen (Set Time is in center)
            return screenSize.width / 2
        case .openMenu:
            // Message aligned RIGHT - arrow will be on right side pointing at menu button
            // Position so right edge of message is near right edge with padding
            return screenSize.width - messageWidth / 2 - 20
        }
    }
    
    private var yPosition: CGFloat {
        // VStack height estimate - tuned to position arrow tip just above/below cutout
        let vstackHeight: CGFloat = 130
        
        if showAboveTarget {
            // Position CENTER of VStack so that BOTTOM is at cutout top - 4pt gap
            return cutoutRect.minY - 4 - vstackHeight / 2
        } else {
            // Position CENTER of VStack so that TOP is at cutout bottom + 4pt gap
            return cutoutRect.maxY + 4 + vstackHeight / 2
        }
    }
}

// Preference key to measure VStack size (for debugging)
struct VStackSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - Tutorial Manager

struct TutorialManager: View {
    let theme: Theme
    let layout: LayoutController  // NEW: Pass layout for actual dimensions
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
            let actualButtonWidth = layout.startButtonWidth * 0.75  // This matches StartButton.swift
            let actualButtonHeight = layout.startButtonHeight
            let layerOffset = layout.startButtonLayerOffset  // The 3D base below the button
            
            // Total visual height includes the 3D base
            let totalVisualHeight = actualButtonHeight + layerOffset
            
            // Padding around the button
            let padding: CGFloat = 12
            
            // Center horizontally on the frame's center
            let centerX = frame.midX
            let cutoutWidth = actualButtonWidth + (padding * 2)
            let cutoutX = centerX - (cutoutWidth / 2)
            
            // The frame starts at the top of the button area
            // We need the cutout to start ABOVE frame.minY to have padding at top
            // and extend down to include the 3D base
            let cutoutHeight = totalVisualHeight + (padding * 2)
            let cutoutY = frame.minY - padding - layerOffset  // Shift UP by layerOffset
            
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
        case .tapStart: return 28  // Larger corner radius for bigger button
        case .changeTheme: return 50  // Circle
        case .changeTime: return 24  // Pill shape
        case .openMenu: return 50    // Circle
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
