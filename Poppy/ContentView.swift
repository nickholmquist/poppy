//
//  ContentView.swift
//  Poppy
//

import SwiftUI
import UIKit

// Inline helper so Previews are easy to gate
extension ProcessInfo {
    var isPreview: Bool { environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }
}

struct ContentView: View {
    @EnvironmentObject private var highs: HighscoreStore
    @EnvironmentObject private var store: ThemeStore
    @StateObject private var engine = GameEngine()

    @State private var showTimePicker = false
    @State private var showEndCard = false
    @State private var isNewHigh = false
    @State private var showConfetti = false
    @State private var selectedTime: Int? = nil
    @State private var endCardLocked = false
    @State private var showMenu = false
    @State private var showTutorial = !UserDefaults.standard.hasSeenTutorial
    
    // Theme transition animation
    @State private var isTransitioning = false
    @State private var transitionOldTheme: Theme? = nil
    
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
            }
        }
        // End-of-time hook
        .onChange(of: engine.isRunning) { _, running in
            if !running && !engine.gameOver {
                let mode = engine.roundLength
                let prev = highs.best[mode] ?? 0
                highs.register(score: engine.score, for: mode)
                isNewHigh = engine.score > prev

                if isNewHigh {
                    if !ProcessInfo.processInfo.isPreview {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.7)) {
                        showConfetti = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showConfetti = false
                        }
                    }
                }

                // show and lock the card briefly
                showEndCard = true
                endCardLocked = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeIn(duration: 0.15)) {
                        endCardLocked = false
                    }
                }
            }
        }
        .onAppear {
            engine.setHighscoreStore(highs)
        }
        .overlay {
                    if showTutorial {
                        TutorialOverlay(theme: theme, isShowing: $showTutorial)
                            .transition(.opacity)
                    }
                }
    }
    
    // MARK: - Game UI View
    
    @ViewBuilder
    private func gameUIView(layout: LayoutController, theme: Theme) -> some View {
        VStack(spacing: 0) {
            // Title row with theme dot and menu button
            TopBar(
                theme: theme,
                layout: layout,
                onThemeTap: {
                    SoundManager.shared.play(.themeChange)
                    store.cycleNext()
                    triggerThemeTransition()
                    engine.triggerThemeWave()
                },
                onMenuTap: {
                    showMenu = true
                }
            )

            // Scoreboard
            ScoreboardPanel(
                layout: layout,
                theme: theme,
                highs: highs
            )
            .padding(.top, layout.scoreboardTopPadding)

            // Score and Time
            StatsRow(
                theme: theme,
                layout: layout,
                score: engine.score,
                remainingSeconds: Int(ceil(engine.remaining)),
                isRunning: engine.isRunning,
                onTimeTap: {
                    selectedTime = engine.roundLength
                    showTimePicker = true
                },
                scoreBump: engine.scoreBump,
                highScoreJustBeaten: engine.isNewHighScore
            )
            .padding(.horizontal, layout.statsHorizontalPadding)
            .padding(.top, layout.statsTopPadding)
            .frame(maxWidth: layout.contentWidth)

            Spacer(minLength: 0)

            // Board
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            theme.background.ignoresSafeArea()
        }

        // Start or Pop button pinned to bottom
        .safeAreaInset(edge: .bottom) {
            StartButton(
                theme: theme,
                layout: layout,
                title: engine.isRunning ? (engine.popReady ? "POP" : "POP") : "START",
                textColor: theme.textOnAccent
            ) {
                if !engine.isRunning { engine.start() }
                else if engine.popReady { engine.pressPop() }
            }
            .disabled(engine.isRunning && !engine.popReady)
            .opacity((engine.isRunning && !engine.popReady) ? 0.6 : 1.0)
            .frame(width: layout.startButtonWidth, height: layout.startButtonHeight)
            .padding(.horizontal, layout.startButtonHorizontalPadding)
            .padding(.bottom, layout.startButtonBottomPadding)
            .zIndex(10)
        }

        // Overlays above the button
        .overlay {
            ZStack {
                if engine.isCountingDown, let c = engine.countdown {
                    CountdownOverlay(theme: theme, count: c)
                }
                if engine.gameOver {
                    GameOverOverlay(theme: theme) { engine.dismissGameOver() }
                }
                if showEndCard {
                    EndCardOverlay(
                        theme: theme,
                        show: $showEndCard,
                        score: engine.score,
                        isNewHigh: isNewHigh,
                        endCardLocked: endCardLocked,
                        onOK: { engine.resetToIdle() },
                        showConfetti: showConfetti
                    )
                }
                if showTimePicker {
                    LiquidGlassTimePicker(
                        theme: theme,
                        show: $showTimePicker,
                        selected: $selectedTime,
                        onConfirm: { s in
                            if !ProcessInfo.processInfo.isPreview {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            engine.roundLength = s
                            engine.remaining = Double(s)
                        }
                    )
                }
            }
        }
        .overlay {
            MenuDrawer(theme: theme, isOpen: $showMenu)
                .environmentObject(highs)
                .zIndex(100)
        }
        
        // Put the paper texture last so it sits above everything
        .paperTextureOverlay()
    }
    
    // MARK: - Theme Transition
    
    private func triggerThemeTransition() {
        guard let previous = store.previous else { return }
        transitionOldTheme = previous
        isTransitioning = true
    }
}

#Preview {
    ContentView()
        .environmentObject(HighscoreStore())
        .environmentObject(ThemeStore())
        .environmentObject(StoreManager.preview)
}
