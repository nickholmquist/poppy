//
//  ContentView.swift
//  Poppy
//
//  Clean version - tutorial shows above dimmed overlay
//

import SwiftUI
import UIKit

extension ProcessInfo {
    var isPreview: Bool { environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }
}

struct ContentView: View {
    @EnvironmentObject private var highs: HighscoreStore
    @EnvironmentObject private var store: ThemeStore
    @StateObject private var engine = GameEngine()

    @State private var showTimePicker = false
    @State private var isNewHigh = false
    @State private var showConfetti = false
    @State private var selectedTime: Int? = nil
    @State private var showMenu = false
    @State private var scoreboardExpanded = UserDefaults.standard.bool(forKey: "poppy.tutorial.firstGame")
    @State private var userPreferredScoreboardState = true
    @State private var celebratingNewHigh = false
    @State private var setTimeButtonFrame: CGRect = .zero
    
    @State private var startButtonFrame: CGRect = .zero
    @State private var themeButtonFrame: CGRect = .zero
    @State private var menuButtonFrame: CGRect = .zero
    
    @State private var isTransitioning = false
    @State private var transitionOldTheme: Theme? = nil
    @State private var isThemeChangeLocked = false
    
    @Namespace private var statsNamespace
    
    @AppStorage("poppy.tutorial.resetCount") private var tutorialResetCount = 0
    @AppStorage("poppy.tutorial.firstGame") private var hasCompletedFirstGame = false
    @AppStorage("poppy.tutorial.firstRound") private var hasCompletedFirstRound = false
    @AppStorage("poppy.tutorial.theme") private var hasChangedTheme = false
    @AppStorage("poppy.tutorial.time") private var hasChangedTime = false
    @AppStorage("poppy.tutorial.menu") private var hasOpenedMenu = false
    
    var theme: Theme { store.current }

    var body: some View {
        GeometryReader { geo in
            let layout = LayoutController(geo)

            ZStack {
                // Base layer - OLD theme (or current if not transitioning)
                let baseTheme = isTransitioning ? (transitionOldTheme ?? theme) : theme
                gameUIView(layout: layout, theme: baseTheme)
                
                // Overlay layer - NEW theme (only during transition)
                if isTransitioning {
                    gameUIView(layout: layout, theme: theme)
                        .mask {
                            ThemeTransitionMask(isAnimating: $isTransitioning)
                        }
                }
                
                // Tutorial overlay system (always on top)
                TutorialOverlaySystem(
                    theme: theme,
                    layout: layout,
                    startButtonFrame: startButtonFrame,
                    themeButtonFrame: themeButtonFrame,
                    timeButtonFrame: setTimeButtonFrame,
                    menuButtonFrame: menuButtonFrame,
                    hasCompletedFirstGame: $hasCompletedFirstGame,
                    hasCompletedFirstRound: $hasCompletedFirstRound,
                    hasChangedTheme: $hasChangedTheme,
                    hasChangedTime: $hasChangedTime,
                    hasOpenedMenu: $hasOpenedMenu,
                    showTimePicker: $showTimePicker,
                    showMenu: $showMenu
                )
            }
        }
        .onChange(of: engine.isRunning) { _, running in
            if !running && !engine.gameOver {
                let mode = engine.roundLength
                let prev = highs.best[mode] ?? 0
                highs.register(score: engine.score, for: mode)
                isNewHigh = engine.score > prev

                if isNewHigh {
                    // Play celebration sound with confetti
                    SoundManager.shared.play(.newHighEnd)
                    
                    if !ProcessInfo.processInfo.isPreview {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                    
                    // Expand scoreboard WITH animation to trigger sequential reveal
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            scoreboardExpanded = true
                        }
                    }
                    
                    // THEN trigger celebration
                    celebratingNewHigh = true
                    
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.7)) {
                        showConfetti = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        // Turn off celebration OUTSIDE animation to prevent button fade
                        celebratingNewHigh = false
                        
                        withAnimation(.easeOut(duration: 0.3)) {
                            showConfetti = false
                        }
                        
                        // Return to user's preferred scoreboard state AFTER celebration
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.51, dampingFraction: 0.75)) {
                                scoreboardExpanded = userPreferredScoreboardState
                            }
                        }
                        
                        if !hasCompletedFirstRound {
                            hasCompletedFirstRound = true
                        }
                    }
                } else {
                    if !hasCompletedFirstRound {
                        hasCompletedFirstRound = true
                    }
                }
            }
        }
        .onAppear {
            engine.setHighscoreStore(highs)
            
            // Load the user's last selected time (default to 10s)
            let savedTime = UserDefaults.standard.integer(forKey: "poppy.roundLength")
            let timeToUse = (savedTime > 0) ? savedTime : 10
            
            if !hasCompletedFirstGame {
                engine.roundLength = 10
                engine.remaining = 10.0
                scoreboardExpanded = false
                userPreferredScoreboardState = false
            } else {
                engine.roundLength = timeToUse
                engine.remaining = Double(timeToUse)
                scoreboardExpanded = true
                userPreferredScoreboardState = true
            }
        }
        .onChange(of: scoreboardExpanded) { _, expanded in
            // Track user's preference, but only if not currently celebrating
            if !celebratingNewHigh {
                userPreferredScoreboardState = expanded
            }
        }
    }
    
    @ViewBuilder
    private func gameUIView(layout: LayoutController, theme: Theme) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                TopBar(
                    theme: theme,
                    layout: layout,
                    isPlaying: engine.isRunning,
                    isThemeLocked: isThemeChangeLocked,
                    onThemeTap: {
                        guard !isThemeChangeLocked else { return }
                        
                        isThemeChangeLocked = true
                        
                        SoundManager.shared.play(.themeChange)
                        store.cycleNext()
                        
                        // Track theme change
                        let themeName = store.names[store.themes.firstIndex(where: {
                            $0.accent == store.current.accent
                        }) ?? 0]
                        AnalyticsManager.shared.trackThemeChange(themeName: themeName)
                        
                        triggerThemeTransition()
                        engine.triggerThemeWave()
                        
                        if !hasChangedTheme {
                            hasChangedTheme = true
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            isThemeChangeLocked = false
                        }
                    },
                    onMenuTap: {
                        // Track menu open
                        AnalyticsManager.shared.trackMenuOpened()
                        
                        showMenu = true
                        
                        if !hasOpenedMenu {
                            hasOpenedMenu = true
                        }
                    },
                    onTimeTap: {
                        selectedTime = engine.roundLength
                        showTimePicker = true
                    },
                    onButtonFrameChange: { frame in
                        setTimeButtonFrame = frame
                    },
                    onThemeButtonFrameChange: { frame in
                        themeButtonFrame = frame
                    },
                    onMenuButtonFrameChange: { frame in
                        menuButtonFrame = frame
                    }
                )

                HighScoreBoard(
                    theme: theme,
                    layout: layout,
                    highs: highs,
                    isRunning: engine.isRunning,
                    isExpanded: $scoreboardExpanded,
                    celebratingMode: celebratingNewHigh ? engine.roundLength : nil
                )
                .padding(.top, layout.scoreboardTopPadding)

                Spacer().frame(height: layout.statsTopPadding)
                
                // --- RESTORED ORIGINAL MANUAL ZSTACK ---
                ZStack(alignment: .center) {
                    MorphingTimerDisplay(
                        theme: theme,
                        layout: layout,
                        progress: engine.timeProgress,
                        isExpanded: scoreboardExpanded,
                        isUrgent: engine.isUrgent
                    )
                    .frame(maxWidth: .infinity)
                    .offset(y: scoreboardExpanded ? 25 : 0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.75), value: scoreboardExpanded)
                    
                    ZStack {
                        Text("Score")
                            .font(.system(
                                size: scoreboardExpanded ? layout.expandedScoreLabelSize : layout.statsLabelSize,
                                weight: .medium,
                                design: .rounded
                            ))
                            .foregroundStyle(theme.textDark.opacity(0.9))
                            .offset(
                                x: scoreboardExpanded ? -layout.expandedSideOffsetX : 0,
                                y: scoreboardExpanded ? layout.expandedLabelOffsetY : layout.collapsedScoreLabelOffsetY
                            )
                        
                        Text("\(engine.score)")
                            .font(.system(
                                size: scoreboardExpanded ? layout.expandedScoreValueSize : layout.statsScoreSize * 2.2,
                                weight: .heavy,
                                design: .rounded
                            ))
                            .foregroundStyle(engine.highScoreFlash ? Color(hex: "#FFD700") : theme.textDark)
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .scaleEffect(engine.scoreBump ? 1.06 : 1.0, anchor: .center)
                            .animation(.spring(response: 0.22, dampingFraction: 0.6), value: engine.scoreBump)
                            .shadow(
                                color: engine.highScoreFlash ? Color(hex: "#FFD700").opacity(0.6) : .clear,
                                radius: engine.highScoreFlash ? 12 : 0
                            )
                            .shadow(
                                color: engine.highScoreFlash ? Color(hex: "#FFA500").opacity(0.4) : .clear,
                                radius: engine.highScoreFlash ? 20 : 0
                            )
                            .offset(
                                x: scoreboardExpanded ? -layout.expandedSideOffsetX : 0,
                                y: scoreboardExpanded ? layout.expandedValueOffsetY : layout.collapsedScoreValueOffsetY
                            )
                        
                        Text("Time")
                            .font(.system(
                                size: scoreboardExpanded ? layout.expandedTimeLabelSize : layout.statsLabelSize,
                                weight: .medium,
                                design: .rounded
                            ))
                            .foregroundStyle(theme.textDark.opacity(0.9))
                            .opacity(scoreboardExpanded ? 1 : 0)
                            .offset(
                                x: scoreboardExpanded ? layout.expandedSideOffsetX : 0,
                                y: scoreboardExpanded ? layout.expandedLabelOffsetY : 0
                            )
                        
                        Text("\(Int(ceil(engine.remaining)))s")
                            .font(.system(
                                size: scoreboardExpanded ? layout.expandedTimeValueSize : layout.statsTimeSize,
                                weight: .heavy,
                                design: .rounded
                            ))
                            .foregroundStyle(theme.textDark.opacity(scoreboardExpanded ? 1.0 : 0.85))
                            .minimumScaleFactor(0.7)
                            .lineLimit(1)
                            .offset(
                                x: scoreboardExpanded ? layout.expandedSideOffsetX : 0,
                                y: scoreboardExpanded ? layout.expandedValueOffsetY : layout.collapsedTimeOffsetY
                            )
                    }
                    .animation(.spring(response: 1.1, dampingFraction: 0.85), value: scoreboardExpanded)
                }
                .frame(maxWidth: .infinity)
                .frame(height: scoreboardExpanded ? 140 : layout.ringDiameter)
                .animation(.spring(response: 0.5, dampingFraction: 0.75), value: scoreboardExpanded)

                Spacer(minLength: 0)

                BoardView(
                    theme: theme,
                    layout: layout,
                    active: engine.active,
                    pressed: engine.pressed,
                    onTap: { engine.tapDot($0) },
                    bounceAll: engine.bounceAll,
                    bounceIndividual: engine.bounceIndividual,
                    rippleDisplacements: engine.rippleDisplacements,
                    idleTapFlash: engine.idleTapFlash,
                    themeWaveDisplacements: engine.themeWaveDisplacements
                )
                .id(engine.boardEpoch)
                .frame(maxWidth: layout.boardWidth)
                .frame(height: layout.boardHeight)
                .padding(.bottom, layout.boardBottomPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            theme.background.ignoresSafeArea()
        }
        .safeAreaInset(edge: .bottom) {
            StartButton(
                theme: theme,
                layout: layout,
                title: (engine.isCountingDown || engine.isRunning) ? "POP" : "START",
                textColor: theme.textOnAccent,
                action: {
                    if !engine.isRunning && !engine.isCountingDown {
                        if !hasCompletedFirstGame {
                            hasCompletedFirstGame = true
                        }
                        engine.start()
                    }
                    else if engine.popReady { engine.pressPop() }
                },
                isDisabled: engine.isCountingDown || (engine.isRunning && !engine.popReady) || celebratingNewHigh || engine.cooldownActive
            )
            .frame(height: layout.startButtonHeight)
            .padding(.horizontal, layout.startButtonHorizontalPadding)
            .padding(.bottom, layout.startButtonBottomPadding)
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        startButtonFrame = geo.frame(in: .global)
                    }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        startButtonFrame = newFrame
                    }
                }
            )
        }
        .overlay {
            ZStack {
                if engine.isCountingDown, let c = engine.countdown {
                    CountdownOverlay(theme: theme, count: c)
                }
                if engine.gameOver {
                    GameOverOverlay(theme: theme) { engine.dismissGameOver() }
                }
                if showTimePicker {
                    VerticalTimePicker(
                        theme: theme,
                        show: $showTimePicker,
                        selected: $selectedTime,
                        buttonFrame: setTimeButtonFrame,
                        onConfirm: { s in
                            if !ProcessInfo.processInfo.isPreview {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            
                            // Track time duration change
                            let oldDuration = engine.roundLength
                            AnalyticsManager.shared.trackTimeDurationChange(
                                from: oldDuration,
                                to: s
                            )
                            
                            engine.roundLength = s
                            engine.remaining = Double(s)
                            
                            if !hasChangedTime {
                                hasChangedTime = true
                            }
                        }
                    )
                }
            }
        }
        .overlay {
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .compositingGroup()
                    .transition(.opacity)
            }
        }
        .overlay {
            MenuDrawer(
                theme: theme,
                isOpen: $showMenu,
                tutorialResetCount: $tutorialResetCount,
                hasCompletedFirstGame: $hasCompletedFirstGame,
                hasCompletedFirstRound: $hasCompletedFirstRound,
                hasChangedTheme: $hasChangedTheme,
                hasChangedTime: $hasChangedTime,
                hasOpenedMenu: $hasOpenedMenu
            )
            .environmentObject(highs)
            .zIndex(100)
        }
        .paperTextureOverlay()
        .onChange(of: tutorialResetCount) { _, newCount in
            if newCount > 0 {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    scoreboardExpanded = false
                }
            }
        }
    }
    
    private func triggerThemeTransition() {
        guard let previous = store.previous else { return }
        transitionOldTheme = previous
        isTransitioning = true
    }
}

// MARK: - Tutorial Overlay System

struct TutorialOverlaySystem: View {
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
    
    private var tutorialActive: Bool {
        !UserDefaults.standard.tutorialCompleted &&
        ((!hasCompletedFirstGame) ||
         (hasCompletedFirstRound && (!hasChangedTheme || !hasChangedTime || !hasOpenedMenu)))
    }
    
    var body: some View {
        // Only render TutorialManager - it handles its own overlay with spotlight cutout
        if tutorialActive {
            TutorialManager(
                theme: theme,
                layout: layout,
                startButtonFrame: startButtonFrame,
                themeButtonFrame: themeButtonFrame,
                timeButtonFrame: timeButtonFrame,
                menuButtonFrame: menuButtonFrame,
                hasCompletedFirstGame: $hasCompletedFirstGame,
                hasCompletedFirstRound: $hasCompletedFirstRound,
                hasChangedTheme: $hasChangedTheme,
                hasChangedTime: $hasChangedTime,
                hasOpenedMenu: $hasOpenedMenu,
                showTimePicker: $showTimePicker,
                showMenu: $showMenu
            )
            .zIndex(9999)  // Above everything else
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HighscoreStore())
        .environmentObject(ThemeStore())
        .environmentObject(StoreManager.preview)
}
