//
//  ContentView.swift
//  Poppy
//
//  Clean version - tutorial shows above dimmed overlay
//

import SwiftUI
import UIKit
import StoreKit

extension ProcessInfo {
    var isPreview: Bool { environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }
}

struct ContentView: View {
    @EnvironmentObject private var highs: HighscoreStore
    @EnvironmentObject private var store: ThemeStore
    @EnvironmentObject private var storeManager: StoreManager
    @EnvironmentObject private var adManager: AdManager
    @StateObject private var engine = GameEngine()
    @Environment(\.colorScheme) private var colorScheme

    @State private var showSetupPicker = false
    @State private var isNewHigh = false
    @State private var showConfetti = false
    @State private var selectedTime: Int = 30
    @State private var gameMode: GameMode = .classic
    @State private var matchyGridSize: MatchyGridSize = .small
    @State private var matchyPlayers: Int = 1
    @State private var showMenu = false
    @State private var showThemeDrawer = false
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

    // Copy mode state
    @State private var copyDifficulty: CopyDifficulty = .classic
    @State private var copySlideDirection: CopySlideDirection = .none

    enum CopySlideDirection {
        case none
        case toClassic   // Challenge slides right, Classic slides in from left
        case toChallenge // Classic slides left, Challenge slides in from right
    }

    // Classic/Boppy header overlay state
    @State private var showTimeScoreOverlay = false
    @State private var timeScorePillFrame: CGRect = .zero

    // Instruction card state
    @State private var showInstructionCard = false
    @State private var previewingLockedMode: GameMode? = nil  // For showing locked mode preview

    // End game confirmation overlay
    @State private var showEndGameConfirmation = false
    @State private var endedMatchEarly = false  // Skip celebration when ending early

    // IAP unlock modal states
    @State private var showUnlockModal = false
    @State private var unlockModalType: UnlockType = .modes
    @State private var showPoppyPlusUpsell = false

    @Namespace private var statsNamespace
    
    @AppStorage("poppy.tutorial.resetCount") private var tutorialResetCount = 0
    @AppStorage("poppy.tutorial.firstGame") private var hasCompletedFirstGame = false
    @AppStorage("poppy.tutorial.firstRound") private var hasCompletedFirstRound = false
    @AppStorage("poppy.tutorial.theme") private var hasChangedTheme = false
    @AppStorage("poppy.tutorial.time") private var hasChangedTime = false
    @AppStorage("poppy.tutorial.menu") private var hasOpenedMenu = false
    @AppStorage("poppy.tutorial.modes") private var hasDiscoveredModes = false
    @AppStorage("poppy.completedGamesCount") private var completedGamesCount = 0
    @AppStorage("poppy.hasRequestedReview") private var hasRequestedReview = false
    
    var theme: Theme { store.current }

    // Check if Daily mode has already been played today
    private var dailyAlreadyPlayed: Bool {
        gameMode == .daily && highs.hasPlayedDailyToday()
    }

    // Mode-specific start button title
    private var startButtonTitle: String {
        if engine.isCountingDown || engine.isRunning {
            // During gameplay, show POP only for Classic mode
            return gameMode.showsPOPButton ? "POP" : ""
        }
        if dailyAlreadyPlayed {
            return "DONE"
        }
        return "START"
    }

    // Mode-specific start button disabled state
    private var startButtonDisabled: Bool {
        // Daily mode already played today
        if dailyAlreadyPlayed {
            return true
        }
        if celebratingNewHigh || engine.cooldownActive {
            return true
        }
        if engine.isCountingDown {
            return true
        }
        if engine.isRunning {
            // For Classic: disabled unless popReady
            // For other modes: always disabled during gameplay (no POP button)
            if gameMode.showsPOPButton {
                return !engine.popReady
            } else {
                return true
            }
        }
        return false
    }

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
                
                // Instruction card (how to play)
                if showInstructionCard {
                    let displayMode = previewingLockedMode ?? gameMode
                    let isModeLocked = !UnlockManager.shared.isModeUnlocked(displayMode)
                    GameInstructionCard(
                        theme: theme,
                        layout: layout,
                        gameMode: displayMode,
                        isLocked: isModeLocked,
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showInstructionCard = false
                            }
                            if !isModeLocked {
                                InstructionTracker.markInstructionsSeen(for: displayMode)
                            }
                            // Clear preview mode
                            previewingLockedMode = nil
                        },
                        onUnlock: {
                            // Show unlock modal after instruction card dismisses
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                unlockModalType = .modes
                                withAnimation(.easeOut(duration: 0.25)) {
                                    showUnlockModal = true
                                }
                            }
                            // Clear preview mode
                            previewingLockedMode = nil
                        }
                    )
                }

                // Unlock modal (for modes)
                if showUnlockModal {
                    UnlockModal(
                        theme: theme,
                        unlockType: unlockModalType,
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showUnlockModal = false
                            }
                        },
                        onShowPoppyPlus: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showPoppyPlusUpsell = true
                            }
                        }
                    )
                }

                // Poppy Plus upsell
                if showPoppyPlusUpsell {
                    PoppyPlusUpsell(
                        theme: theme,
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                showPoppyPlusUpsell = false
                            }
                        }
                    )
                }
            }
        }
        .onChange(of: engine.isRunning) { _, running in
            // Dismiss end confirmation if game ends naturally
            if !running && showEndGameConfirmation {
                showEndGameConfirmation = false
            }
            if !running && !engine.gameOver {
                // Register score based on current game mode
                // For round-based modes, use the round number instead of score
                let scoreToRegister: Int
                switch gameMode {
                case .copy: scoreToRegister = engine.copyRound
                case .tappy: scoreToRegister = engine.tappyRound
                default: scoreToRegister = engine.score
                }
                let prev = highs.getBest(for: gameMode, duration: engine.roundLength)
                highs.register(score: scoreToRegister, mode: gameMode, duration: engine.roundLength)
                isNewHigh = scoreToRegister > prev && !endedMatchEarly

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

                // Track completed games and request review after 5 games
                completedGamesCount += 1
                if completedGamesCount >= 5 && !hasRequestedReview {
                    hasRequestedReview = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        requestAppReview()
                    }
                }

                // Trigger interstitial ad check (shows every 6-7 games for non-premium users)
                adManager.gameCompleted(storeManager: storeManager)
            }
        }
        .onChange(of: engine.gameOver) { _, isGameOver in
            // Register scores for modes that end with gameOver=true (lives-based modes)
            if isGameOver {
                var gotNewHigh = false
                switch gameMode {
                case .copy:
                    highs.registerCopyScore(engine.copyRound, difficulty: copyDifficulty)
                case .tappy:
                    let score = engine.tappyRound
                    let prev = highs.getBest(for: .tappy, duration: 0)
                    highs.register(score: score, mode: .tappy, duration: 0)
                    if score > prev {
                        isNewHigh = true
                        gotNewHigh = true
                    }
                case .zoomy:
                    let score = engine.score
                    let prev = highs.getBest(for: .zoomy, duration: 0)
                    highs.register(score: score, mode: .zoomy, duration: 0)
                    if score > prev {
                        isNewHigh = true
                        gotNewHigh = true
                    }
                case .seeky:
                    let score = engine.seekyRound
                    let prev = highs.getBest(for: .seeky, duration: 0)
                    highs.register(score: score, mode: .seeky, duration: 0)
                    if score > prev {
                        isNewHigh = true
                        gotNewHigh = true
                    }
                default:
                    break
                }

                // Trigger celebration for new high scores in lives-based modes
                if gotNewHigh {
                    SoundManager.shared.play(.newHighEnd)
                    if !ProcessInfo.processInfo.isPreview {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }

                    withAnimation(.spring(response: 0.36, dampingFraction: 0.7)) {
                        showConfetti = true
                    }

                    // Auto-dismiss after celebration
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showConfetti = false
                        }
                        // Dismiss game over state after celebration
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            engine.dismissGameOver()
                            isNewHigh = false
                        }
                    }
                }
            }
        }
        .onAppear {
            engine.setHighscoreStore(highs)

            // Apply correct theme for current system appearance
            store.applyCurrentColorScheme(colorScheme)

            // Load the user's last selected mode and time
            gameMode = GameMode.loadSelected()
            engine.setGameMode(gameMode)  // Sync to engine
            let savedTime = UserDefaults.standard.integer(forKey: "poppy.roundLength")
            let timeToUse = (savedTime > 0) ? savedTime : 10
            selectedTime = timeToUse

            // Load saved Copy difficulty
            copyDifficulty = CopyDifficulty.load()
            engine.copyDifficulty = copyDifficulty

            if !hasCompletedFirstGame {
                engine.roundLength = 10
                engine.remaining = 10.0
                selectedTime = 10
                scoreboardExpanded = false
                userPreferredScoreboardState = false
            } else {
                engine.roundLength = timeToUse
                engine.remaining = Double(timeToUse)
                scoreboardExpanded = true
                userPreferredScoreboardState = true
            }

            // Show instruction card on first visit to this mode
            if !InstructionTracker.hasSeenInstructions(for: gameMode) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showInstructionCard = true
                    }
                }
            }
        }
        .onChange(of: gameMode) { _, newMode in
            // Show instruction card on first visit to a new mode
            if !InstructionTracker.hasSeenInstructions(for: newMode) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.25)) {
                        showInstructionCard = true
                    }
                }
            }
        }
        .onChange(of: selectedTime) { _, newTime in
            // Sync engine.roundLength when user changes time via TimeScoreSelector
            // Only for timed modes, and not during gameplay
            if !engine.isRunning && !engine.isCountingDown {
                if gameMode == .classic || gameMode == .boppy {
                    engine.roundLength = newTime
                    engine.remaining = Double(newTime)
                }
            }
        }
        .onChange(of: colorScheme) { _, newScheme in
            // Auto-switch theme when system appearance changes
            store.updateColorScheme(newScheme)
        }
        .onChange(of: copyDifficulty) { oldDifficulty, newDifficulty in
            // Sync Copy difficulty to engine
            engine.copyDifficulty = newDifficulty

            // Trigger slide animation when in Copy mode and not during gameplay
            if gameMode == .copy && !engine.isRunning && !engine.isCountingDown && oldDifficulty != newDifficulty {
                copySlideDirection = newDifficulty == .classic ? .toClassic : .toChallenge

                // Reset after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    copySlideDirection = .none
                }
            }
        }
        .onChange(of: matchyPlayers) { _, newPlayers in
            engine.setMatchyPlayerCount(newPlayers)
        }
        .onChange(of: matchyGridSize) { _, newSize in
            engine.setMatchyGridSize(newSize.dotCount)
        }
        .onChange(of: scoreboardExpanded) { _, expanded in
            // Track user's preference, but only if not currently celebrating
            if !celebratingNewHigh {
                userPreferredScoreboardState = expanded
            }
        }
        .onChange(of: engine.gameOver) { _, isGameOver in
            // Show confetti for all Matchy completions
            if isGameOver && gameMode == .matchy {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.7)) {
                    showConfetti = true
                }

                // For single player, auto-dismiss after confetti
                // For multiplayer, confetti stays until winner overlay is dismissed
                let confettiDuration: Double = engine.matchyPlayerCount == 1 ? 3.5 : 5.0
                DispatchQueue.main.asyncAfter(deadline: .now() + confettiDuration) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showConfetti = false
                    }
                    // For single player, also dismiss the game over state
                    if engine.matchyPlayerCount == 1 && engine.gameOver {
                        engine.dismissGameOver()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func gameUIView(layout: LayoutController, theme: Theme) -> some View {
        let mainContent = mainGameContent(layout: layout, theme: theme)
        let withOverlays = mainContent
            .overlay { gameOverlays(layout: layout, theme: theme) }
            .overlay { confettiOverlay() }
            .overlay { menuOverlay(theme: theme) }
            .overlay { themeDrawerOverlay(theme: theme) }

        withOverlays
            .paperTextureOverlay()
            .onChange(of: tutorialResetCount) { _, newCount in
                if newCount > 0 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        scoreboardExpanded = false
                    }
                }
            }
    }

    @ViewBuilder
    private func mainGameContent(layout: LayoutController, theme: Theme) -> some View {
        let config = gameMode.layoutConfig

        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                topBarSection(layout: layout, theme: theme)

                settingsSection(layout: layout, theme: theme)

                // Stats section placement depends on mode
                // For Tappy/Seeky: Spacer first, then stats (pushes stats toward board)
                // For others: Stats first, then Spacer (pushes stats toward header)
                if config.showsStatsSection && !config.statsNearBoard {
                    Spacer().frame(height: config.headerToStatsSpacing(layout))
                    statsSection(layout: layout, theme: theme)
                }

                // Spacer between header/stats and board (only for non-Zoomy modes)
                if config.usesFlexibleSpacer {
                    Spacer(minLength: config.headerToStatsSpacing(layout))
                }

                // Stats near board (Tappy/Seeky) - placed after spacer, above board
                if config.showsStatsSection && config.statsNearBoard {
                    statsSection(layout: layout, theme: theme)
                    Spacer().frame(height: config.statsToBoardSpacing(layout))
                }

                // Board rendering
                if config.usesInlineBoard {
                    // Zoomy uses inline board - centered in remaining space
                    Spacer()
                    ZoomyBoardView(
                        theme: theme,
                        layout: layout,
                        dots: engine.zoomyDots,
                        lives: engine.lives,
                        score: engine.score,
                        onTapDot: { engine.tapZoomyDot($0) }
                    )
                    Spacer()
                } else {
                    boardSection(layout: layout, theme: theme)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { theme.background.ignoresSafeArea() }
        .safeAreaInset(edge: .bottom) {
            bottomButtonSection(layout: layout, theme: theme)
        }
    }

    // MARK: - View Sections (broken up to reduce compiler complexity)

    @ViewBuilder
    private func topBarSection(layout: LayoutController, theme: Theme) -> some View {
        TopBar(
            theme: theme,
            layout: layout,
            isPlaying: engine.isRunning,
            isThemeLocked: isThemeChangeLocked,
            isSetupPickerOpen: showSetupPicker,
            gameMode: gameMode,
            selectedTime: selectedTime,
            showModeHint: hasCompletedFirstGame && !hasDiscoveredModes,
            isDailyCompleted: highs.hasPlayedDailyToday(),
            onThemeTap: { handleThemeTap() },
            onThemeLongPress: { showThemeDrawer = true },
            onMenuTap: { handleMenuTap() },
            onSetupTap: {
                showSetupPicker = true
                if !hasDiscoveredModes { hasDiscoveredModes = true }
            },
            onDailyTap: {
                guard !engine.isRunning && !engine.isCountingDown else { return }
                SoundManager.shared.play(.menu)
                HapticsManager.shared.light()
                gameMode = .daily
                engine.setGameMode(.daily)
                let dailyDuration = HighscoreStore.dailyDurationForToday()
                engine.roundLength = dailyDuration
                engine.remaining = Double(dailyDuration)
                GameMode.daily.save()
            },
            onButtonFrameChange: { setTimeButtonFrame = $0 },
            onThemeButtonFrameChange: { themeButtonFrame = $0 },
            onMenuButtonFrameChange: { menuButtonFrame = $0 }
        )
    }

    private func handleThemeTap() {
        guard !isThemeChangeLocked else { return }
        isThemeChangeLocked = true
        SoundManager.shared.play(.themeChange)
        store.cycleNext()
        let themeName = store.names[store.themes.firstIndex(where: { $0.accent == store.current.accent }) ?? 0]
        AnalyticsManager.shared.trackThemeChange(themeName: themeName)
        triggerThemeTransition()
        engine.triggerThemeWave()
        if !hasChangedTheme { hasChangedTheme = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isThemeChangeLocked = false }
    }

    private func handleMenuTap() {
        AnalyticsManager.shared.trackMenuOpened()
        showMenu = true
        if !hasOpenedMenu { hasOpenedMenu = true }
    }

    @ViewBuilder
    private func settingsSection(layout: LayoutController, theme: Theme) -> some View {
        let config = gameMode.layoutConfig
        // All modes now use top bar to content spacing (Daily Banner removed)
        let topPadding = config.topBarToContentSpacing(layout)

        if gameMode == .matchy {
            // Matchy header with pills and matches display
            MatchyHeader(
                theme: theme,
                layout: layout,
                playerCount: Binding(
                    get: { engine.matchyPlayerCount },
                    set: { engine.setMatchyPlayerCount($0) }
                ),
                gridSize: Binding(
                    get: { MatchyGridSize(rawValue: engine.matchyGridSize) ?? .small },
                    set: { engine.setMatchyGridSize($0.dotCount) }
                ),
                playerScores: engine.matchyPlayerScores,
                currentPlayer: engine.matchyCurrentPlayer,
                isPlaying: engine.isRunning || engine.isCountingDown,
                flipsCount: engine.matchyAttempts,
                onInfoTap: { showInstructionCard = true }
            )
            .padding(.horizontal, 20)
            .padding(.top, topPadding)
        } else if gameMode == .daily {
            // Daily mode gets its own card instead of scoreboard
            DailyCard(
                theme: theme,
                layout: layout,
                highs: highs,
                isRunning: engine.isRunning,
                onInfoTap: { showInstructionCard = true }
            )
            .padding(.top, topPadding)
        } else if gameMode == .copy {
            // Copy mode header with difficulty rocker and best round
            CopyHeader(
                theme: theme,
                layout: layout,
                difficulty: $copyDifficulty,
                classicBest: highs.copyClassicBest,
                challengeBest: highs.copyChallengeBest,
                currentRound: engine.copyRound,
                isShowingSequence: engine.copyShowingSequence,
                isPlaying: engine.isRunning || engine.isCountingDown,
                isRunning: engine.isRunning || engine.isCountingDown || copySlideDirection != .none,
                onInfoTap: { showInstructionCard = true }
            )
            .padding(.top, topPadding)
        } else if gameMode == .zoomy {
            // Zoomy mode - simple high score header (Daily is now in top bar)
            ZoomyHeader(
                theme: theme,
                layout: layout,
                best: highs.getBest(for: .zoomy, duration: 0),
                isPlaying: engine.isRunning || engine.isCountingDown,
                onInfoTap: { showInstructionCard = true }
            )
            .padding(.top, topPadding)
        } else if gameMode == .tappy {
            // Tappy mode - High Score card only (matches Seeky layout)
            TappyHeader(
                theme: theme,
                layout: layout,
                best: highs.getBest(for: .tappy, duration: 0),
                isPlaying: engine.isRunning || engine.isCountingDown,
                onInfoTap: { showInstructionCard = true }
            )
            .padding(.top, topPadding)
        } else if gameMode == .seeky {
            // Seeky mode header - High Score card only (flat, not a button)
            SeekyHeader(
                theme: theme,
                layout: layout,
                best: highs.getBest(for: .seeky, duration: 0),
                isPlaying: engine.isRunning || engine.isCountingDown,
                onInfoTap: { showInstructionCard = true }
            )
            .padding(.top, topPadding)
        } else {
            // Classic and Boppy use pill-based header - under top bar
            ClassicHeader(
                theme: theme,
                layout: layout,
                gameMode: gameMode,
                highScores: gameMode == .boppy ? highs.boppyBest : highs.best,
                selectedDuration: $selectedTime,
                isPlaying: engine.isRunning || engine.isCountingDown,
                timeRemaining: engine.remaining,
                onInfoTap: { showInstructionCard = true },
                showTimeScoreOverlay: $showTimeScoreOverlay,
                timeScorePillFrame: $timeScorePillFrame
            )
            .padding(.top, topPadding)
        }
    }

    @ViewBuilder
    private func statsSection(layout: LayoutController, theme: Theme) -> some View {
        // For Matchy mode, the stats are shown in the header, so this section is empty
        if gameMode != .matchy {
            ZStack(alignment: .center) {
                classicStatsView(layout: layout, theme: theme)
            }
            .frame(maxWidth: .infinity)
            .id(gameMode)  // Force view recreation when mode changes
        }
    }

    // Daily and Seeky modes always use expanded layout
    private var effectiveExpanded: Bool {
        (gameMode == .daily || gameMode == .seeky) ? true : scoreboardExpanded
    }

    // Seeky timer progress (0-1)
    private var seekyTimeProgress: Double {
        // Show full bar before game starts
        guard engine.isRunning else { return 1.0 }
        guard engine.seekyTimeRemaining > 0 else { return 0 }
        return engine.seekyTimeRemaining / 5.0
    }

    // Seeky urgent state (<=2 seconds)
    private var seekyIsUrgent: Bool {
        engine.isRunning && engine.seekyTimeRemaining <= 2 && engine.seekyTimeRemaining > 0
    }

    // Tappy timer progress (0-1)
    private var tappyTimeProgress: Double {
        guard engine.isRunning && engine.tappyState == .active else { return 1.0 }
        let timeLimit = engine.tappyCurrentTimeLimit()
        guard timeLimit > 0 else { return 1.0 }
        return engine.tappyTimeRemaining / timeLimit
    }

    // Tappy urgent state (<=25% time remaining)
    private var tappyIsUrgent: Bool {
        engine.isRunning && engine.tappyState == .active && tappyTimeProgress < 0.25
    }

    @ViewBuilder
    private func classicStatsView(layout: LayoutController, theme: Theme) -> some View {
        Group {
            // Copy mode shows status and round near the board
            if gameMode == .copy {
                CopyStatusDisplay(
                    theme: theme,
                    layout: layout,
                    currentRound: engine.copyRound,
                    isShowingSequence: engine.copyShowingSequence,
                    isPlaying: engine.isRunning || engine.isCountingDown
                )
            }
            // Tappy uses integrated score container like Seeky
            else if gameMode == .tappy {
                VStack(spacing: layout.spacingLoose) {  // More spacing between container and hearts
                    // Score container with integrated timer (Round + Time)
                    TappyScoreContainer(
                        theme: theme,
                        layout: layout,
                        round: engine.tappyRound,
                        timeRemaining: Int(ceil(engine.tappyTimeRemaining > 0 ? engine.tappyTimeRemaining : engine.tappyCurrentTimeLimit())),
                        timeProgress: tappyTimeProgress,
                        isUrgent: tappyIsUrgent,
                        isRunning: engine.isRunning && engine.tappyState == .active
                    )

                    // Lives display below timer
                    TappyLivesDisplay(
                        theme: theme,
                        layout: layout,
                        lives: engine.lives
                    )
                }
            }
            // Seeky uses its own integrated score container with center-out timer
            else if gameMode == .seeky {
                VStack(spacing: layout.spacingLoose) {  // More spacing between container and hearts
                    // Score container with integrated timer
                    SeekyScoreContainer(
                        theme: theme,
                        layout: layout,
                        score: engine.seekyRound,
                        timeRemaining: Int(ceil(engine.seekyTimeRemaining > 0 ? engine.seekyTimeRemaining : 5.0)),
                        timeProgress: seekyTimeProgress,
                        isUrgent: seekyIsUrgent,
                        isRunning: engine.isRunning,
                        lives: engine.lives
                    )

                    // Lives display between timer and dots
                    SeekyLivesDisplay(
                        theme: theme,
                        layout: layout,
                        lives: engine.lives
                    )
                }
            } else {
                scoreAndTimeDisplay(layout: layout, theme: theme)
            }
        }
    }

    @ViewBuilder
    private func scoreAndTimeDisplay(layout: LayoutController, theme: Theme) -> some View {
        // Classic, Boppy, and Daily use integrated timer-container score display
        if gameMode == .classic || gameMode == .boppy || gameMode == .daily {
            ClassicScoreContainer(
                theme: theme,
                layout: layout,
                score: engine.score,
                timeRemaining: Int(ceil(engine.remaining)),
                timeProgress: engine.timeProgress,
                isUrgent: engine.isUrgent,
                isRunning: engine.isRunning,
                highScoreFlash: engine.highScoreFlash,
                scoreBump: engine.scoreBump,
                showTimer: gameMode == .daily  // Daily shows both Score and Time
            )
        } else {
            // Other modes use the original stacked layout
            ZStack {
                Text(gameMode.scoreLabel)
                    .font(.system(
                        size: effectiveExpanded ? layout.expandedScoreLabelSize : layout.statsLabelSize,
                        weight: .medium,
                        design: .rounded
                    ))
                    .foregroundStyle(theme.textDark.opacity(0.9))
                    .offset(
                        x: (effectiveExpanded && gameMode.showsTimer) ? -layout.expandedSideOffsetX : 0,
                        y: effectiveExpanded ? layout.expandedLabelOffsetY : layout.collapsedScoreLabelOffsetY
                    )

                scoreValueText(layout: layout, theme: theme)

                if gameMode.showsTimer {
                    timeLabels(layout: layout, theme: theme)
                }
            }
            .animation(.spring(response: 1.1, dampingFraction: 0.85), value: effectiveExpanded)
        }
    }

    @ViewBuilder
    private func scoreValueText(layout: LayoutController, theme: Theme) -> some View {
        Text("\(engine.score)")
            .font(.system(
                size: effectiveExpanded ? layout.expandedScoreValueSize : layout.statsScoreSize * 2.2,
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
                x: (effectiveExpanded && gameMode.showsTimer) ? -layout.expandedSideOffsetX : 0,
                y: effectiveExpanded ? layout.expandedValueOffsetY : layout.collapsedScoreValueOffsetY
            )
    }

    @ViewBuilder
    private func timeLabels(layout: LayoutController, theme: Theme) -> some View {
        // Seeky shows its own time, others use engine.remaining
        let displayTime = gameMode == .seeky
            ? Int(ceil(engine.seekyTimeRemaining > 0 ? engine.seekyTimeRemaining : 5.0))
            : Int(ceil(engine.remaining))

        Group {
            Text("Time")
                .font(.system(
                    size: effectiveExpanded ? layout.expandedTimeLabelSize : layout.statsLabelSize,
                    weight: .medium,
                    design: .rounded
                ))
                .foregroundStyle(theme.textDark.opacity(0.9))
                .opacity(effectiveExpanded ? 1 : 0)
                .offset(
                    x: effectiveExpanded ? layout.expandedSideOffsetX : 0,
                    y: effectiveExpanded ? layout.expandedLabelOffsetY : 0
                )

            Text("\(displayTime)s")
                .font(.system(
                    size: effectiveExpanded ? layout.expandedTimeValueSize : layout.statsTimeSize,
                    weight: .heavy,
                    design: .rounded
                ))
                .foregroundStyle(theme.textDark.opacity(effectiveExpanded ? 1.0 : 0.85))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .offset(
                    x: effectiveExpanded ? layout.expandedSideOffsetX : 0,
                    y: effectiveExpanded ? layout.expandedValueOffsetY : layout.collapsedTimeOffsetY
                )
        }
    }

    @ViewBuilder
    private func boardSection(layout: LayoutController, theme: Theme) -> some View {
        VStack(spacing: layout.unit * 8) {
            ZStack {
                // Copy Classic uses 4-dot Simon board
                if gameMode == .copy && copyDifficulty == .classic {
                    SimonBoard(
                        theme: theme,
                        layout: layout,
                        activeIndex: engine.active.first,
                        pressedIndex: engine.pressed.first,
                        onTap: { engine.tapDot($0) }
                    )
                    .transition(.asymmetric(
                        insertion: .offset(x: -layout.screenWidth),
                        removal: .offset(x: -layout.screenWidth)
                    ))
                } else if gameMode == .copy && copyDifficulty == .challenge {
                    // Copy Challenge uses regular BoardView
                    standardBoardView(layout: layout, theme: theme)
                        .transition(.asymmetric(
                            insertion: .offset(x: layout.screenWidth),
                            removal: .offset(x: layout.screenWidth)
                        ))
                } else if gameMode == .seeky {
                    // Seeky mode - with odd dot detection
                    standardBoardView(layout: layout, theme: theme, includeSeekProps: true)
                } else {
                    // All other modes (Classic, Daily, Matchy, Boppy, Tappy)
                    standardBoardView(layout: layout, theme: theme)
                        .opacity(dailyAlreadyPlayed ? 0.3 : 1.0)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: copyDifficulty)
            .frame(maxWidth: layout.boardWidth)
            .frame(maxHeight: gameMode == .matchy ? .infinity : layout.boardHeight)
            .frame(height: gameMode == .matchy ? nil : layout.boardHeight)
            // Clip to full screen width so boards slide off screen edges
            .clipShape(
                Rectangle()
                    .size(width: 3000, height: 10000)
                    .offset(x: -1500 + layout.boardWidth / 2, y: -5000)
            )
        }
        .padding(.bottom, layout.boardBottomPadding)
    }

    /// Standard BoardView with common parameters - reduces code duplication
    @ViewBuilder
    private func standardBoardView(layout: LayoutController, theme: Theme, includeSeekProps: Bool = false) -> some View {
        let isMatchy = gameMode == .matchy

        BoardView(
            theme: theme,
            layout: layout,
            active: dailyAlreadyPlayed ? [] : engine.active,
            pressed: dailyAlreadyPlayed ? Set(0..<10) : engine.pressed,
            onTap: { engine.tapDot($0) },
            bounceAll: engine.bounceAll,
            bounceIndividual: engine.bounceIndividual,
            rippleDisplacements: engine.rippleDisplacements,
            idleTapFlash: engine.idleTapFlash,
            themeWaveDisplacements: engine.themeWaveDisplacements,
            matchyColors: isMatchy ? engine.matchyColors : [:],
            matchyRevealedArray: isMatchy ? Array(engine.matchyRevealed) : [],
            matchyMatchedArray: isMatchy ? Array(engine.matchyMatched) : [],
            matchyGridSize: isMatchy ? engine.matchyGridSize : 10,
            seekyOddDot: includeSeekProps ? engine.seekyOddDot : nil,
            seekyDifference: includeSeekProps ? engine.seekyDifference : .color,
            seekyDifferenceAmount: includeSeekProps ? engine.seekyDifferenceAmount : 0,
            seekyBaseColor: (includeSeekProps && engine.isRunning) ? engine.seekyBaseColor : nil,  // Only use Seeky color during gameplay
            seekyRevealingAnswer: includeSeekProps ? engine.seekyRevealingAnswer : false
        )
        .id(engine.boardEpoch)
    }

    @ViewBuilder
    private func bottomButtonSection(layout: LayoutController, theme: Theme) -> some View {
        let showEndButton = engine.isRunning && !gameMode.showsPOPButton

        ZStack {
            // Show either START or END button - END takes over START's position
            // Instant swap with no transition/fade
            if showEndButton {
                EndGameButton(theme: theme, layout: layout, showConfirmation: $showEndGameConfirmation)
                .transition(.identity)
            } else {
                StartButton(
                    theme: theme,
                    layout: layout,
                    title: startButtonTitle,
                    textColor: theme.textOnAccent,
                    action: { handleStartButtonTap() },
                    isDisabled: startButtonDisabled
                )
                .transition(.identity)
            }
        }
        .animation(nil, value: showEndButton)
        .padding(.horizontal, layout.startButtonHorizontalPadding)
        .padding(.bottom, layout.startButtonBottomPadding)
        .background(
            GeometryReader { geo in
                Color.clear.onAppear { startButtonFrame = geo.frame(in: .global) }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in startButtonFrame = newFrame }
            }
        )
    }

    private func handleStartButtonTap() {
        if !engine.isRunning && !engine.isCountingDown {
            if !hasCompletedFirstGame { hasCompletedFirstGame = true }
            isNewHigh = false  // Reset high score state for new game
            endedMatchEarly = false  // Reset early end flag
            engine.start()
        } else if engine.popReady && gameMode.showsPOPButton {
            engine.pressPop()
        }
    }

    @ViewBuilder
    private func gameOverlays(layout: LayoutController, theme: Theme) -> some View {
        ZStack {
            // Daily completed overlay - centered on screen (below pickers)
            if dailyAlreadyPlayed, let todayScore = highs.dailyTodayScore {
                DailyCompletedOverlay(theme: theme, score: todayScore, streak: highs.dailyStreak)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.scale.combined(with: .opacity))
            }

            if engine.isCountingDown, let c = engine.countdown {
                CountdownOverlay(theme: theme, count: c)
            }
            // Game over overlay - skip for Matchy (has its own end screen) and when celebrating new high
            if engine.gameOver && gameMode != .matchy && !showConfetti && !isNewHigh {
                GameOverOverlay(
                    theme: theme,
                    onOK: { engine.dismissGameOver() },
                    isPerfectMatchy: false,
                    copyRound: gameMode == .copy ? engine.copyRound : nil
                )
            }
            // Matchy multiplayer winner overlay
            if engine.gameOver && gameMode == .matchy && engine.matchyPlayerCount > 1 {
                MatchyWinnerOverlay(
                    theme: theme,
                    playerScores: engine.matchyPlayerScores,
                    onDismiss: { engine.dismissGameOver() }
                )
            }
            if showSetupPicker {
                gameSetupPickerView(layout: layout, theme: theme)
            }

            // Classic/Boppy time/score selector overlay
            if showTimeScoreOverlay {
                TimeScoreSelectorOverlay(
                    theme: theme,
                    layout: layout,
                    gameMode: gameMode,
                    highScores: gameMode == .boppy ? highs.boppyBest : highs.best,
                    selectedDuration: $selectedTime,
                    show: $showTimeScoreOverlay,
                    buttonFrame: timeScorePillFrame
                )
            }

            // End game confirmation overlay
            if showEndGameConfirmation {
                EndGameOverlay(
                    theme: theme,
                    layout: layout,
                    show: $showEndGameConfirmation
                ) {
                    endedMatchEarly = true
                    engine.endGameEarly()
                }
            }

            // Matchy turn change card (multiplayer only)
            if engine.matchyShowTurnCard {
                MatchyTurnCard(
                    theme: theme,
                    currentPlayer: engine.matchyCurrentPlayer,
                    onDismiss: { engine.dismissMatchyTurnCard() }
                )
            }
        }
    }

    @ViewBuilder
    private func gameSetupPickerView(layout: LayoutController, theme: Theme) -> some View {
        GameSetupPicker(
            theme: theme,
            layout: layout,
            show: $showSetupPicker,
            selectedMode: $gameMode,
            selectedTime: $selectedTime,
            buttonFrame: setTimeButtonFrame,
            onConfirm: { handleSetupConfirm() },
            onLockedModeTap: { lockedMode in
                // Show instruction card for the locked mode (as preview)
                previewingLockedMode = lockedMode
                withAnimation(.easeOut(duration: 0.25)) {
                    showInstructionCard = true
                }
            },
            isDailyCompleted: highs.hasPlayedDailyToday()
        )
    }

    private func handleSetupConfirm() {
        if !ProcessInfo.processInfo.isPreview {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        let oldMode = engine.currentMode
        let modeChanged = gameMode != oldMode

        if modeChanged {
            AnalyticsManager.shared.trackGameModeChange(from: oldMode, to: gameMode)
            withAnimation(.easeInOut(duration: 0.3)) { scoreboardExpanded = false }
            // Reset score when switching modes
            engine.score = 0

            // Load the saved time for Classic/Boppy when switching to them
            if gameMode == .classic || gameMode == .boppy {
                let savedTime = UserDefaults.standard.integer(forKey: "poppy.roundLength")
                if savedTime > 0 && gameMode.availableDurations.contains(savedTime) {
                    selectedTime = savedTime
                } else {
                    selectedTime = 30  // Default
                }
            }
        }

        if gameMode == .classic || gameMode == .daily {
            let oldDuration = engine.roundLength
            if oldDuration != selectedTime {
                AnalyticsManager.shared.trackTimeDurationChange(from: oldDuration, to: selectedTime)
            }
        }
        engine.setGameMode(gameMode)

        // Set roundLength and remaining based on mode
        if gameMode == .daily {
            let dailyDuration = HighscoreStore.dailyDurationForToday()
            engine.roundLength = dailyDuration
            engine.remaining = Double(dailyDuration)
        } else {
            engine.roundLength = selectedTime
            engine.remaining = Double(selectedTime)
        }
        if !hasChangedTime { hasChangedTime = true }
    }

    @ViewBuilder
    private func confettiOverlay() -> some View {
        if showConfetti {
            ConfettiView()
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .compositingGroup()
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private func menuOverlay(theme: Theme) -> some View {
        MenuDrawer(
            theme: theme,
            isOpen: $showMenu,
            showThemeDrawer: $showThemeDrawer
        )
        .environmentObject(highs)
        .zIndex(100)
    }

    @ViewBuilder
    private func themeDrawerOverlay(theme: Theme) -> some View {
        ThemeDrawer(
            theme: theme,
            isOpen: $showThemeDrawer,
            onLockedThemeTap: {
                // Show themes unlock modal
                unlockModalType = .themes
                withAnimation(.easeOut(duration: 0.25)) {
                    showUnlockModal = true
                }
            }
        )
        .zIndex(101)
    }
    
    private func triggerThemeTransition() {
        guard let previous = store.previous else { return }
        transitionOldTheme = previous
        isTransitioning = true
    }

    private func requestAppReview() {
        guard !ProcessInfo.processInfo.isPreview else { return }
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HighscoreStore())
        .environmentObject(ThemeStore())
        .environmentObject(StoreManager.preview)
        .environmentObject(AdManager.preview)
}
