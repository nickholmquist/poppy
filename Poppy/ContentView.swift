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
    
    // Theme transition animation
    @State private var isTransitioning = false
    @State private var transitionOldTheme: Theme? = nil

    var theme: Theme { store.current }

    var body: some View {
        GeometryReader { geo in
            let M = LayoutMetrics(geo)

            ZStack {
                // Base layer - OLD theme (or current if not transitioning)
                let baseTheme = isTransitioning ? (transitionOldTheme ?? theme) : theme
                gameUIView(geo: geo, M: M, theme: baseTheme)
                
                // Overlay layer - NEW theme (only during transition)
                if isTransitioning {
                    gameUIView(geo: geo, M: M, theme: theme)
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
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
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
    }
    
    // MARK: - Game UI View
    
    @ViewBuilder
    private func gameUIView(geo: GeometryProxy, M: LayoutMetrics, theme: Theme) -> some View {
        VStack(spacing: M.stackSpacing) {
            // Title row with theme dot
            TopBar(theme: theme, compact: M.compact) {
                store.cycleNext()
                triggerThemeTransition()
            }

            // Scoreboard
            ScoreboardPanel(
                maxWidth: M.scoreboardW,
                height: M.scoreboardH,
                theme: theme,
                highs: highs,
                tintOpacity: 0.95,
                brightnessLift: 0.06
            )
            .frame(maxWidth: M.scoreboardW, minHeight: M.scoreboardH)
            .padding(.top, M.titleToBoard)

            // Score and Time
            StatsRow(
                theme: theme,
                compact: M.compact,
                score: engine.score,
                remainingSeconds: Int(ceil(engine.remaining)),
                isRunning: engine.isRunning,
                onTimeTap: {
                    selectedTime = engine.roundLength
                    showTimePicker = true
                },
                scoreBump: engine.scoreBump
            )
            .padding(.horizontal, M.statsSide)
            .padding(.top, M.statsTop)
            .frame(maxWidth: M.maxW)

            Spacer(minLength: 0)

            // Board
            BoardView(
                theme: theme,
                active: engine.active,
                pressed: engine.pressed,
                onTap: { engine.tapDot($0) },
                compact: M.compact,
                bounceAll: engine.bounceAll,
                bounceIndividual: engine.bounceIndividual
            )
            .id(engine.boardEpoch)
            .frame(maxWidth: M.boardCapW)
            .frame(height: M.boardH)
            .padding(.bottom, M.boardToButtonGap)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            ZStack {
                theme.background.ignoresSafeArea()
            }
        }

        // Start or Pop button pinned to bottom
        .safeAreaInset(edge: .bottom) {
            let safeW = max(1, geo.size.width)
            let insetWidth = max(44, min(safeW - 32, 500))
            StartButton(
                theme: theme,
                title: engine.isRunning ? (engine.popReady ? "POP" : "POP") : "Start",
                textColor: theme.textOnAccent,
                tintOpacity: 0.95,
                brightnessLift: 0.06
            ) {
                if !engine.isRunning { engine.start() }
                else if engine.popReady { engine.pressPop() }
            }
            .disabled(engine.isRunning && !engine.popReady)
            .opacity((engine.isRunning && !engine.popReady) ? 0.6 : 1.0)
            .frame(width: insetWidth, height: M.startH)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
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
}
