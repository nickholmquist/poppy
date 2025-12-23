import Foundation
import Combine
import UIKit
import SwiftUI
import CoreHaptics
import AudioToolbox

// MARK: - Seeky Mode Types

/// Seeky uses color difference only - the odd dot has a slightly different hue
enum SeekyDifference {
    case color  // Odd dot has a different color (hue shift)
}

// MARK: - Zoomy Dot Model

struct ZoomyDot: Identifiable {
    let id: UUID
    var position: CGPoint       // Current position (normalized 0-1 within container)
    var velocity: CGPoint       // Direction and speed (normalized)
    var spawnTime: Date         // When the dot was spawned
    var colorIndex: Int         // Color variation (0-4)
    var isFast: Bool            // Fast dots move quicker but are smaller
    var exitEdge: Int           // Which edge dot will exit (0=top, 1=right, 2=bottom, 3=left)

    init(position: CGPoint, velocity: CGPoint, colorIndex: Int = 0, isFast: Bool = false, exitEdge: Int = 0) {
        self.id = UUID()
        self.position = position
        self.velocity = velocity
        self.spawnTime = Date()
        self.colorIndex = colorIndex
        self.isFast = isFast
        self.exitEdge = exitEdge
    }

    /// Check if dot has crossed through and exited the container
    func hasExited() -> Bool {
        // Check based on exit edge - dot must have crossed past the boundary
        switch exitEdge {
        case 0: return position.y < -0.15  // Exited top
        case 1: return position.x > 1.15   // Exited right
        case 2: return position.y > 1.15   // Exited bottom
        case 3: return position.x < -0.15  // Exited left
        default: return false
        }
    }
}

// MARK: - Tappy State Enum

enum TappyState {
    case waiting      // Waiting before dots light up (random delay)
    case active       // Dots are lit, player must tap them
    case roundComplete // Player tapped all dots, brief pause before next round
    case failed       // Player missed the time window
}

@MainActor
final class GameEngine: ObservableObject {

    private var countdownTask: Task<Void, Never>?
    private var tickerTask: Task<Void, Never>?
    private var hapticEngine: CHHapticEngine?
    private let soundManager = SoundManager.shared

    // Board config
    static let totalDots = 10
    static let activeCount = 3

    // Current game mode
    @Published var currentMode: GameMode = .classic

    // Game state
    @Published var isRunning = false
    @Published var isCountingDown = false
    @Published var countdown: Int? = nil
    @Published var gameOver = false
    @Published var cooldownActive = false

    @Published var score = 0
    @Published var remaining: Double = 30

    // Copy mode state (Simon Says)
    @Published var copySequence: [Int] = []           // The sequence to memorize
    @Published var copyPlayerIndex: Int = 0           // Current position in player's input
    @Published var copyShowingSequence = false        // True while showing the sequence
    @Published var copyCurrentShowIndex: Int = 0      // Which dot in sequence is currently lit
    @Published var copyDifficulty: CopyDifficulty = .classic  // Classic (4 dots) or Challenge (10 dots)
    @Published var copyRound: Int = 0                 // Current round number (1-based for display)

    // Boppy mode state (Whack-a-mole with multiple dots)
    @Published var boppyActiveDots: [Int: Date] = [:] // Active dots with their expiration times
    private var boppySpawnTask: Task<Void, Never>?    // Task that spawns new dots
    private var boppyCleanupTask: Task<Void, Never>?  // Task that removes expired dots
    private var boppyDotLifetime: Double = 1.0        // How long each dot stays visible
    private var boppySpawnInterval: Double = 0.6      // Time between spawning new dots
    private var boppyMaxDots: Int = 2                 // Max dots visible at once (increases with score)

    // Daily mode state
    @Published var dailyAlreadyPlayed = false         // True if user already played today

    // Matchy mode state (Memory matching)
    @Published var matchyColors: [Int: Int] = [:]       // Dot index -> color index (0-4 for 5 pairs)
    @Published var matchyRevealed: Set<Int> = []        // Currently revealed (face-up) dots
    @Published var matchyMatched: Set<Int> = []         // Dots that have been matched (stay revealed)
    @Published var matchyFirstPick: Int? = nil          // First dot of current pair pick
    @Published var matchyAttempts: Int = 0              // Number of attempts (pair comparisons)
    private var matchyLocked = false                    // True while showing mismatched pair

    // Matchy multiplayer state
    @Published var matchyPlayerCount: Int = 1           // Number of players (1-4)
    @Published var matchyCurrentPlayer: Int = 0         // Current player's turn (0-indexed)
    @Published var matchyPlayerScores: [Int] = [0]      // Score for each player
    @Published var matchyLastMatchPlayer: Int? = nil    // Which player got the last match (for display)
    @Published var matchyGridSize: Int = 10             // Number of dots (10, 16, or 20)
    @Published var matchyPerfectRound: Bool = false     // True when player achieves perfect score
    @Published var matchyShowTurnCard: Bool = false     // Show turn change announcement card

    // Lives (for Zoomy, Seeky modes)
    @Published var lives: Int = 3

    // Zoomy mode state (catch drifting dots)
    @Published var zoomyDots: [ZoomyDot] = []        // Active floating dots
    private var zoomySpawnTask: Task<Void, Never>?   // Task that spawns new dots
    private var zoomyUpdateTask: Task<Void, Never>?  // Task that updates dot positions
    private var zoomySpawnInterval: Double = 1.2     // Time between spawning new dots
    private var zoomyDotSpeed: Double = 50.0         // Pixels per second
    private var zoomyMaxDots: Int = 3                // Max dots visible at once

    // Tappy mode state (survival rounds)
    @Published var tappyRound: Int = 0               // Current round (1-10, then bonus)
    @Published var tappyState: TappyState = .waiting // Current phase of the round
    @Published var tappyTargetDots: Set<Int> = []    // Which dots need to be tapped this round
    @Published var tappyTappedDots: Set<Int> = []    // Dots player has tapped so far
    @Published var tappyTimeRemaining: Double = 0    // Time left to tap all dots
    private var tappyRoundTask: Task<Void, Never>?   // Manages round timing
    private var tappyTimerStartDate: Date?           // For smooth countdown
    private let tappyBaseTimeLimit: Double = 2.0     // Base time to tap dots (decreases with rounds)

    // Seeky mode state (find the odd one)
    @Published var seekyOddDot: Int? = nil           // The dot that's different
    @Published var seekyRound: Int = 0               // Current round
    @Published var seekyDifference: SeekyDifference = .color  // Type of difference (color only)
    @Published var seekyDifferenceAmount: CGFloat = 0.3      // How noticeable (decreases with rounds)
    @Published var seekyBaseColor: Color = .red              // Base color for current round (changes each round)
    @Published var seekyRevealingAnswer: Bool = false        // True when showing the correct answer before game over
    @Published var seekyTimeRemaining: Double = 0            // Countdown timer for current puzzle
    private var seekyTimerTask: Task<Void, Never>?           // Task running the countdown
    private var seekyTimerStartDate: Date?                   // When the timer started (for smooth countdown)
    private let seekyTimeLimit: Double = 5.0                 // Seconds to guess (5 seconds)

    @Published var active: Set<Int> = []   // currently lit
    @Published var pressed: Set<Int> = []  // pressed in this cycle
    @Published var popReady = false        // true when all 10 are pressed
    @Published var boardEpoch: Int = 0

    // Bounce animation triggers
    @Published var bounceAll: Int = 0
    @Published var bounceIndividual: [Int: Int] = [:]

    // Ripple displacement
    @Published var rippleDisplacements: [Int: CGPoint] = [:]

    // Idle tap flashes
    @Published var idleTapFlash: [Int: Int] = [:]

    // Theme change wave
    @Published var themeWaveDisplacements: [Int: CGPoint] = [:]

    // Idle fidget pops
    @Published var fidget: Set<Int> = []

    // UI signal for score pop animation
    @Published var scoreBump = false

    // High score tracking
    @Published var isNewHighScore = false
    @Published var highScoreFlash = false
    private var highScoreThreshold: Int = 0

    // Last 5 seconds urgency
    @Published var isUrgent = false
    private var lastHapticSecond: Int = -1

    // Round length
    var roundLength: Int = 10 {
        didSet {
            if !isRunning {
                remaining = Double(roundLength)
                UserDefaults.standard.set(roundLength, forKey: "poppy.roundLength")
            }
        }
    }

    // Time progress for bar/ring visualization
    var timeProgress: Double {
        guard roundLength > 0 else { return 0 }
        return remaining / Double(roundLength)
    }

    // Timers
    private var ticker: Timer?
    private var countdownTimer: Timer?
    private var endTime: Date = .init()

    // Reference to highscore store
    private var highscoreStore: HighscoreStore?

    // MARK: - Initialization

    init() {
        let savedTime = UserDefaults.standard.integer(forKey: "poppy.roundLength")
        if savedTime > 0 {
            self.roundLength = savedTime
            self.remaining = Double(savedTime)
        }

        setupHaptics()
    }

    func setHighscoreStore(_ store: HighscoreStore) {
        self.highscoreStore = store
    }

    func setGameMode(_ mode: GameMode) {
        guard !isRunning else { return }
        currentMode = mode

        // Update daily played status when switching to Daily mode
        if mode == .daily {
            dailyAlreadyPlayed = highscoreStore?.hasPlayedDailyToday() ?? false
        }
    }

    /// Set the number of players for Matchy mode (1-4)
    func setMatchyPlayerCount(_ count: Int) {
        guard !isRunning else { return }
        matchyPlayerCount = max(1, min(4, count))
        matchyPlayerScores = Array(repeating: 0, count: matchyPlayerCount)
        matchyCurrentPlayer = 0
    }

    /// Set the grid size for Matchy mode (10, 16, or 20 dots)
    func setMatchyGridSize(_ size: Int) {
        guard !isRunning else { return }
        // Only allow valid sizes
        if [10, 16, 20].contains(size) {
            matchyGridSize = size
        }
    }

    /// Dismiss the turn change card and unlock the board
    func dismissMatchyTurnCard() {
        matchyShowTurnCard = false
        matchyLocked = false
    }

    /// Check if user can play Daily mode today (hasn't played yet)
    func canPlayDailyToday() -> Bool {
        return !(highscoreStore?.hasPlayedDailyToday() ?? false)
    }

    /// Get today's Daily mode duration for display
    func getDailyDuration() -> Int {
        return HighscoreStore.dailyDurationForToday()
    }

    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
        }
    }

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }

        resetBoard()
        resetModeState()
        score = 0
        gameOver = false

        // Set high score threshold based on mode
        // Lives-based modes (Zoomy, Tappy, Seeky) use duration: 0 since they don't have timed variants
        let durationForHighScore = currentMode.startingLives > 0 ? 0 : roundLength
        highScoreThreshold = highscoreStore?.getBest(for: currentMode, duration: durationForHighScore) ?? 0
        isNewHighScore = false

        // Set starting lives for modes that use them
        lives = currentMode.startingLives

        isCountingDown = true
        countdown = 3

        stopTimers()
        soundManager.play(.countdownStart)

        countdownTask = Task { [weak self] in
            guard let self else { return }
            while let c = self.countdown, c > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled { return }
                withAnimation(.none) { self.countdown = c - 1 }
            }

            withAnimation(.none) { self.countdown = nil }
            self.beginRound()
        }
    }

    /// Reset mode-specific state
    private func resetModeState() {
        // Copy mode
        copySequence = []
        copyPlayerIndex = 0
        copyShowingSequence = false
        copyCurrentShowIndex = 0
        copyRound = 0

        // Boppy mode
        boppyActiveDots = [:]
        boppySpawnTask?.cancel()
        boppyCleanupTask?.cancel()
        boppySpawnTask = nil
        boppyCleanupTask = nil
        boppyDotLifetime = 1.0
        boppySpawnInterval = 0.6
        boppyMaxDots = 2

        // Matchy mode
        matchyColors = [:]
        matchyRevealed = []
        matchyMatched = []
        matchyFirstPick = nil
        matchyAttempts = 0
        matchyLocked = false
        matchyPerfectRound = false
        // Reset multiplayer scores but keep player count
        matchyPlayerScores = Array(repeating: 0, count: matchyPlayerCount)
        matchyCurrentPlayer = 0
        matchyLastMatchPlayer = nil

        // Lives
        lives = 3

        // Zoomy mode
        zoomyDots = []
        zoomySpawnTask?.cancel()
        zoomyUpdateTask?.cancel()
        zoomySpawnTask = nil
        zoomyUpdateTask = nil
        zoomySpawnInterval = 1.2
        zoomyDotSpeed = 50.0
        zoomyMaxDots = 3

        // Tappy mode
        tappyRound = 0
        tappyState = .waiting
        tappyTargetDots = []
        tappyTappedDots = []
        tappyTimeRemaining = 0
        tappyRoundTask?.cancel()
        tappyRoundTask = nil
        tappyTimerStartDate = nil

        // Seeky mode
        seekyOddDot = nil
        seekyRound = 0
        seekyDifference = .color
        seekyDifferenceAmount = 0.35
        seekyBaseColor = .red
        seekyRevealingAnswer = false
        seekyTimerTask?.cancel()
        seekyTimerTask = nil
        seekyTimerStartDate = nil
        seekyTimeRemaining = 0
    }

    private func beginRound() {
        isCountingDown = false
        isRunning = true

        // For Daily mode, set the duration from today's seed
        if currentMode == .daily {
            roundLength = HighscoreStore.dailyDurationForToday()
        }

        AnalyticsManager.shared.trackGameStart(duration: roundLength, mode: currentMode)

        // Branch based on mode
        switch currentMode {
        case .classic:
            beginClassicRound()
        case .daily:
            // Daily uses same logic as Classic but with seeded duration and RNG
            beginClassicRound()
        case .copy:
            beginCopyRound()
        case .boppy:
            beginBoppyRound()
        case .matchy:
            beginMatchyRound()
        case .zoomy:
            beginZoomyRound()
        case .tappy:
            beginTappyRound()
        case .seeky:
            beginSeekyRound()
        }
    }

    // MARK: - Classic Mode

    private func beginClassicRound() {
        remaining = Double(roundLength)
        endTime = Date().addingTimeInterval(TimeInterval(roundLength))

        seedActive()

        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            guard let self else { return }
            while true {
                if Task.isCancelled { return }

                let left = self.endTime.timeIntervalSinceNow
                withAnimation(.none) {
                    self.remaining = max(0, left)
                }

                // Check for urgency zone (last 5 seconds)
                let secondsLeft = Int(ceil(left))
                if secondsLeft <= 5 && secondsLeft > 0 {
                    if !self.isUrgent {
                        withAnimation(.easeIn(duration: 0.3)) {
                            self.isUrgent = true
                        }
                    }
                    if secondsLeft != self.lastHapticSecond {
                        self.lastHapticSecond = secondsLeft
                        self.playUrgencyHaptic(secondsLeft: secondsLeft)
                    }
                } else if self.isUrgent && secondsLeft > 5 {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.isUrgent = false
                    }
                }

                if left <= 0 {
                    self.finishRound()
                    return
                }

                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    // MARK: - Copy Mode (Simon Says)

    private func beginCopyRound() {
        copyRound += 1
        // Start with sequence of 3, grows each round
        let sequenceLength = 3 + score // score = rounds completed
        generateCopySequence(length: sequenceLength)
        showCopySequence()
    }

    private func generateCopySequence(length: Int) {
        let dotCount = copyDifficulty.dotCount

        if copySequence.isEmpty {
            // First round - generate new sequence
            copySequence = (0..<length).map { _ in Int.random(in: 0..<dotCount) }
        } else {
            // Add one more to existing sequence (cumulative)
            copySequence.append(Int.random(in: 0..<dotCount))
        }
    }

    /// Calculate playback speed multiplier based on round (speeds up every 5 rounds)
    private var copySpeedMultiplier: Double {
        // Round 1-5: 1.0x, Round 6-10: 0.85x, Round 11-15: 0.72x, etc.
        // Each tier is 15% faster, capping at 0.5x (2x speed)
        let tier = (copyRound - 1) / 5
        let multiplier = pow(0.85, Double(tier))
        return max(multiplier, 0.5)
    }

    private func showCopySequence() {
        copyShowingSequence = true
        copyCurrentShowIndex = 0
        copyPlayerIndex = 0

        let speedMultiplier = copySpeedMultiplier
        let holdDuration = UInt64(500_000_000 * speedMultiplier)
        let gapDuration = UInt64(200_000_000 * speedMultiplier)

        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            guard let self else { return }

            // Brief pause before starting
            try? await Task.sleep(nanoseconds: 500_000_000)

            for (index, dotIndex) in self.copySequence.enumerated() {
                if Task.isCancelled { return }

                // Light up the dot
                await MainActor.run {
                    self.copyCurrentShowIndex = index
                    withAnimation(.easeOut(duration: 0.15)) {
                        self.active = [dotIndex]
                    }
                }
                self.soundManager.playSimon(dotIndex)

                // Hold lit (speed adjusted)
                try? await Task.sleep(nanoseconds: holdDuration)

                // Turn off
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.15)) {
                        self.active = []
                    }
                }

                // Gap between dots (speed adjusted)
                try? await Task.sleep(nanoseconds: gapDuration)
            }

            // Done showing - player's turn
            await MainActor.run {
                self.copyShowingSequence = false
            }
        }
    }

    private func handleCopyTap(_ index: Int) {
        guard !copyShowingSequence else { return }

        let expectedIndex = copySequence[copyPlayerIndex]

        if index == expectedIndex {
            // Correct tap - play the Simon tone for this dot
            soundManager.playSimon(index)
            playBubblePopHaptic()

            // Flash the dot
            withAnimation(.easeOut(duration: 0.1)) {
                active = [index]
            }
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.1)) {
                        self.active = []
                    }
                }
            }

            copyPlayerIndex += 1

            // Check if sequence complete
            if copyPlayerIndex >= copySequence.count {
                // Round complete - add point and start next
                addPoint()

                Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    await MainActor.run {
                        self.beginCopyRound()
                    }
                }
            }
        } else {
            // Wrong tap - game over
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            triggerGameOver()
        }
    }

    // MARK: - Boppy Mode (Whack-a-mole with multiple dots)

    private func beginBoppyRound() {
        remaining = Double(roundLength)
        endTime = Date().addingTimeInterval(TimeInterval(roundLength))

        // Reset difficulty based on duration
        // Shorter games = harder from the start
        switch roundLength {
        case 20:
            boppyDotLifetime = 0.9
            boppySpawnInterval = 0.5
            boppyMaxDots = 2
        case 30:
            boppyDotLifetime = 1.0
            boppySpawnInterval = 0.6
            boppyMaxDots = 2
        case 40:
            boppyDotLifetime = 1.1
            boppySpawnInterval = 0.7
            boppyMaxDots = 2
        default:
            boppyDotLifetime = 1.0
            boppySpawnInterval = 0.6
            boppyMaxDots = 2
        }

        boppyActiveDots = [:]

        // Spawn initial dots immediately so the game starts active
        spawnInitialBoppyDots()

        // Start the main timer
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            guard let self else { return }
            while true {
                if Task.isCancelled { return }

                let left = self.endTime.timeIntervalSinceNow
                withAnimation(.none) {
                    self.remaining = max(0, left)
                }

                // Urgency zone (last 5 seconds)
                let secondsLeft = Int(ceil(left))
                if secondsLeft <= 5 && secondsLeft > 0 {
                    if !self.isUrgent {
                        withAnimation(.easeIn(duration: 0.3)) {
                            self.isUrgent = true
                        }
                    }
                    if secondsLeft != self.lastHapticSecond {
                        self.lastHapticSecond = secondsLeft
                        self.playUrgencyHaptic(secondsLeft: secondsLeft)
                    }
                } else if self.isUrgent && secondsLeft > 5 {
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.isUrgent = false
                    }
                }

                if left <= 0 {
                    self.boppySpawnTask?.cancel()
                    self.boppyCleanupTask?.cancel()
                    self.finishRound()
                    return
                }

                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }

        // Start spawning dots continuously
        startBoppySpawner()

        // Start cleanup task to remove expired dots
        startBoppyCleanup()
    }

    private func startBoppySpawner() {
        boppySpawnTask?.cancel()
        boppySpawnTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled && self.isRunning {
                // Wait for spawn interval
                try? await Task.sleep(nanoseconds: UInt64(self.boppySpawnInterval * 1_000_000_000))
                if Task.isCancelled { return }

                await MainActor.run {
                    self.spawnBoppyDot()
                }
            }
        }
    }

    private func spawnInitialBoppyDots() {
        // Spawn 2 dots immediately at game start
        let availablePositions = Array(0..<Self.totalDots).shuffled()
        let initialCount = min(2, boppyMaxDots)

        for i in 0..<initialCount {
            let dotIndex = availablePositions[i]
            let expirationTime = Date().addingTimeInterval(boppyDotLifetime)
            boppyActiveDots[dotIndex] = expirationTime

            let _ = withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                active.insert(dotIndex)
            }
        }

        soundManager.play(.pop)
    }

    private func spawnBoppyDot() {
        // Don't spawn if we're at max dots
        guard boppyActiveDots.count < boppyMaxDots else { return }

        // Find available dot positions (not currently active)
        let availablePositions = Array(Set(0..<Self.totalDots).subtracting(Set(boppyActiveDots.keys)))
        guard !availablePositions.isEmpty else { return }

        // Determine how many dots to spawn at once
        // Higher chance of multiple spawns as game progresses
        let slotsAvailable = boppyMaxDots - boppyActiveDots.count
        let maxToSpawn = min(slotsAvailable, availablePositions.count)

        // 40% chance of spawning 2 dots, 15% chance of 3 dots (if available)
        let spawnCount: Int
        let roll = Double.random(in: 0...1)
        if maxToSpawn >= 3 && roll < 0.15 {
            spawnCount = 3
        } else if maxToSpawn >= 2 && roll < 0.55 {
            spawnCount = 2
        } else {
            spawnCount = 1
        }

        // Pick random positions for all dots to spawn
        let shuffled = availablePositions.shuffled()
        let dotsToSpawn = Array(shuffled.prefix(spawnCount))

        // Spawn all dots simultaneously
        for dotIndex in dotsToSpawn {
            let expirationTime = Date().addingTimeInterval(boppyDotLifetime)
            boppyActiveDots[dotIndex] = expirationTime

            let _ = withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
                active.insert(dotIndex)
            }
        }

        soundManager.play(.pop)
    }

    private func startBoppyCleanup() {
        boppyCleanupTask?.cancel()
        boppyCleanupTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled && self.isRunning {
                // Check every 50ms for expired dots
                try? await Task.sleep(nanoseconds: 50_000_000)
                if Task.isCancelled { return }

                await MainActor.run {
                    self.cleanupExpiredBoppyDots()
                }
            }
        }
    }

    private func cleanupExpiredBoppyDots() {
        let now = Date()
        var expiredDots: [Int] = []

        for (dotIndex, expirationTime) in boppyActiveDots {
            if now >= expirationTime {
                expiredDots.append(dotIndex)
            }
        }

        // Remove expired dots
        for dotIndex in expiredDots {
            boppyActiveDots.removeValue(forKey: dotIndex)
            let _ = withAnimation(.easeOut(duration: 0.12)) {
                active.remove(dotIndex)
            }
        }
    }

    private func handleBoppyTap(_ index: Int) {
        // Check if tapped an active dot
        if boppyActiveDots[index] != nil {
            // Correct tap!
            soundManager.play(.pop)
            playBubblePopHaptic()
            triggerRipple(from: index)

            // Remove the tapped dot
            boppyActiveDots.removeValue(forKey: index)
            let _ = withAnimation(.easeOut(duration: 0.08)) {
                active.remove(index)
            }

            // Score!
            addPoint()

            // Gradually increase difficulty
            if score % 8 == 0 && score > 0 {
                // Every 8 points, speed up and potentially add more dots
                boppyDotLifetime = max(0.5, boppyDotLifetime - 0.05)
                boppySpawnInterval = max(0.3, boppySpawnInterval - 0.05)

                // Increase max dots at certain thresholds
                if score == 16 {
                    boppyMaxDots = 3
                } else if score == 32 {
                    boppyMaxDots = 4
                }
            }

            // Trigger bounce on tapped dot
            bounceIndividual[index, default: 0] += 1
        } else {
            // Tapped inactive dot - light feedback, no penalty
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    // MARK: - Matchy Mode (Memory matching)

    private func beginMatchyRound() {
        // Calculate number of pairs based on grid size
        let pairCount = matchyGridSize / 2

        // Setup color pairs - each color appears exactly twice
        var colorAssignments: [Int] = []
        for colorIndex in 0..<pairCount {
            colorAssignments.append(colorIndex)
            colorAssignments.append(colorIndex)
        }
        colorAssignments.shuffle()

        // Assign colors to dot indices
        matchyColors = [:]
        for (dotIndex, colorIndex) in colorAssignments.enumerated() {
            matchyColors[dotIndex] = colorIndex
        }

        // All dots start face-down (not revealed) - no preview!
        matchyRevealed = []
        matchyMatched = []
        matchyFirstPick = nil
        matchyAttempts = 0
        matchyLocked = false
        matchyPerfectRound = false
    }

    private func handleMatchyTap(_ index: Int) {
        // Ignore if locked (showing mismatched pair)
        guard !matchyLocked else { return }

        // Ignore if already matched
        guard !matchyMatched.contains(index) else { return }

        // Ignore if this dot is already revealed as first pick
        if matchyRevealed.contains(index) { return }

        // Reveal this dot
        soundManager.play(.pop)
        HapticsManager.shared.light()

        // Trigger bounce animation on the tapped dot
        bounceIndividual[index, default: 0] += 1

        matchyRevealed.insert(index)

        if let firstPick = matchyFirstPick {
            // This is the second pick - count as a flip/attempt
            matchyAttempts += 1

            let firstColor = matchyColors[firstPick] ?? -1
            let secondColor = matchyColors[index] ?? -2

            if firstColor == secondColor {
                // Match found!
                HapticsManager.shared.medium()
                soundManager.play(.popUp)

                // Mark as matched
                matchyMatched.insert(firstPick)
                matchyMatched.insert(index)

                // Award point to current player
                if matchyCurrentPlayer < matchyPlayerScores.count {
                    matchyPlayerScores[matchyCurrentPlayer] += 1
                }
                matchyLastMatchPlayer = matchyCurrentPlayer

                // Update total score for tracking
                score = matchyPlayerScores.reduce(0, +)

                // Check if game complete (all dots matched)
                if matchyMatched.count == matchyGridSize {
                    finishMatchyGame()
                }

                // Reset for next pick - player gets extra turn on match!
                matchyFirstPick = nil
            } else {
                // No match - show briefly then hide, then rotate to next player
                matchyLocked = true

                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    await MainActor.run {
                        guard let self else { return }

                        // Hide both dots
                        withAnimation(.easeOut(duration: 0.2)) {
                            self.matchyRevealed.remove(firstPick)
                            self.matchyRevealed.remove(index)
                        }

                        UINotificationFeedbackGenerator().notificationOccurred(.warning)
                        self.matchyFirstPick = nil

                        // Rotate to next player (only in multiplayer)
                        if self.matchyPlayerCount > 1 {
                            self.matchyCurrentPlayer = (self.matchyCurrentPlayer + 1) % self.matchyPlayerCount
                            // Show turn card announcement
                            self.matchyShowTurnCard = true
                        } else {
                            self.matchyLocked = false
                        }
                    }
                }
            }
        } else {
            // This is the first pick
            matchyFirstPick = index
        }
    }

    private func finishMatchyGame() {
        isRunning = false
        gameOver = true

        // Check for perfect round (attempts == number of pairs)
        let pairCount = matchyGridSize / 2
        if matchyPlayerCount == 1 && matchyAttempts == pairCount {
            matchyPerfectRound = true
            soundManager.play(.newHighEnd)  // Special celebration sound
            HapticsManager.shared.heavy()
        } else {
            matchyPerfectRound = false
            soundManager.play(.gameOver)
            HapticsManager.shared.medium()
        }

        // Register score (pairs matched = 5 for perfect game)
        highscoreStore?.register(score: score, mode: .matchy)

        // Analytics
        AnalyticsManager.shared.trackGameComplete(
            score: score,
            duration: 0,
            isNewHigh: false,
            timeLimitSeconds: 0,
            mode: currentMode
        )
    }

    // MARK: - Zoomy Mode (Catch drifting dots)

    private func beginZoomyRound() {
        // Zoomy is a survival mode - no timer, just lives
        // Game ends when player loses all 3 lives

        // Start moderate but ramp up quickly based on score
        // Base speed for slow dots (fast dots are 2x this)
        zoomySpawnInterval = 1.0  // Start with 1 second between spawns
        zoomyDotSpeed = 0.10      // Base speed (normalized per second) - faster start
        zoomyMaxDots = 2          // Start with just 2 max dots

        zoomyDots = []
        lives = 3

        // No timer task needed - game ends when lives run out

        // Start spawning dots
        startZoomySpawner()

        // Start position update loop
        startZoomyUpdateLoop()
    }

    private func startZoomySpawner() {
        zoomySpawnTask?.cancel()
        zoomySpawnTask = Task { [weak self] in
            guard let self else { return }

            // Spawn first dot immediately
            await MainActor.run {
                self.spawnZoomyDot()
            }

            while !Task.isCancelled && self.isRunning {
                try? await Task.sleep(nanoseconds: UInt64(self.zoomySpawnInterval * 1_000_000_000))
                if Task.isCancelled { return }

                await MainActor.run {
                    self.spawnZoomyDot()
                }
            }
        }
    }

    private func spawnZoomyDot() {
        // Don't spawn if at max dots
        guard zoomyDots.count < zoomyMaxDots else { return }

        // Pick a random entry edge (0=top, 1=right, 2=bottom, 3=left)
        let entryEdge = Int.random(in: 0..<4)
        // Exit edge is always opposite (no corner cutting)
        let exitEdge = (entryEdge + 2) % 4

        // Determine if this is a fast dot (25% base, increases faster with score)
        let fastChance = min(0.25 + Double(score) * 0.02, 0.6)
        let isFast = Double.random(in: 0...1) < fastChance

        var startPos: CGPoint
        var endPos: CGPoint

        // Calculate start position on entry edge
        switch entryEdge {
        case 0: // Enter from top
            startPos = CGPoint(x: CGFloat.random(in: 0.2...0.8), y: -0.15)
            endPos = CGPoint(x: CGFloat.random(in: 0.2...0.8), y: 1.15)
        case 1: // Enter from right
            startPos = CGPoint(x: 1.15, y: CGFloat.random(in: 0.2...0.8))
            endPos = CGPoint(x: -0.15, y: CGFloat.random(in: 0.2...0.8))
        case 2: // Enter from bottom
            startPos = CGPoint(x: CGFloat.random(in: 0.2...0.8), y: 1.15)
            endPos = CGPoint(x: CGFloat.random(in: 0.2...0.8), y: -0.15)
        default: // Enter from left
            startPos = CGPoint(x: -0.15, y: CGFloat.random(in: 0.2...0.8))
            endPos = CGPoint(x: 1.15, y: CGFloat.random(in: 0.2...0.8))
        }

        // Calculate velocity direction (from start to end)
        var velocity = CGPoint(
            x: endPos.x - startPos.x,
            y: endPos.y - startPos.y
        )

        // Normalize velocity
        let length = sqrt(velocity.x * velocity.x + velocity.y * velocity.y)
        velocity = CGPoint(x: velocity.x / length, y: velocity.y / length)

        let dot = ZoomyDot(
            position: startPos,
            velocity: velocity,
            colorIndex: Int.random(in: 0..<5),
            isFast: isFast,
            exitEdge: exitEdge
        )

        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
            zoomyDots.append(dot)
        }

        soundManager.play(.pop)
    }

    private func startZoomyUpdateLoop() {
        zoomyUpdateTask?.cancel()
        zoomyUpdateTask = Task { [weak self] in
            guard let self else { return }

            var lastUpdate = Date()

            while !Task.isCancelled && self.isRunning {
                try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
                if Task.isCancelled { return }

                let now = Date()
                let deltaTime = now.timeIntervalSince(lastUpdate)
                lastUpdate = now

                await MainActor.run {
                    self.updateZoomyDots(deltaTime: deltaTime)
                }
            }
        }
    }

    private func updateZoomyDots(deltaTime: TimeInterval) {
        var escapedDots: [UUID] = []

        // Update positions
        for i in zoomyDots.indices {
            // Fast dots move 2x faster than slow dots
            let speedMultiplier: Double = zoomyDots[i].isFast ? 2.0 : 1.0
            let speed = zoomyDotSpeed * deltaTime * speedMultiplier

            zoomyDots[i].position.x += zoomyDots[i].velocity.x * speed
            zoomyDots[i].position.y += zoomyDots[i].velocity.y * speed

            // Check if dot has crossed through and exited
            if zoomyDots[i].hasExited() {
                escapedDots.append(zoomyDots[i].id)
            }
        }

        // Handle escaped dots - player loses a life for each
        for id in escapedDots {
            if let index = zoomyDots.firstIndex(where: { $0.id == id }) {
                zoomyDots.remove(at: index)
                loseZoomyLife()
            }
        }
    }

    private func loseZoomyLife() {
        lives -= 1
        UINotificationFeedbackGenerator().notificationOccurred(.warning)

        if lives <= 0 {
            // Game over
            zoomySpawnTask?.cancel()
            zoomyUpdateTask?.cancel()
            triggerGameOver()
        }
    }

    /// Tap a Zoomy dot by ID - called from ZoomyBoardView
    func tapZoomyDot(_ id: UUID) {
        guard isRunning else { return }

        if let index = zoomyDots.firstIndex(where: { $0.id == id }) {
            // Caught it!
            soundManager.play(.pop)
            playBubblePopHaptic()

            // Remove immediately - no fade
            zoomyDots.remove(at: index)

            addPoint()

            // Ramp up difficulty every catch
            // Increase speed every catch (compounding 5% increase)
            zoomyDotSpeed = min(zoomyDotSpeed * 1.05, 0.35)
            // Decrease spawn interval every catch (more dots faster)
            zoomySpawnInterval = max(zoomySpawnInterval * 0.95, 0.35)

            // Add more simultaneous dots at earlier thresholds
            if score == 3 {
                zoomyMaxDots = 3
            } else if score == 6 {
                zoomyMaxDots = 4
            } else if score == 10 {
                zoomyMaxDots = 5
            } else if score == 15 {
                zoomyMaxDots = 6
            } else if score == 22 {
                zoomyMaxDots = 7
            } else if score == 30 {
                zoomyMaxDots = 8
            }
        }
    }

    // MARK: - Tappy Mode (Survival rounds - tap N dots before time runs out)

    private func beginTappyRound() {
        // Initialize lives on first round
        lives = currentMode.startingLives
        tappyRound = 0

        // Start first round
        startNextTappyRound()
    }

    private func startNextTappyRound() {
        tappyRound += 1
        tappyTappedDots = []
        tappyState = .waiting

        // Clear board
        withAnimation(.easeOut(duration: 0.15)) {
            active = []
        }

        // Random delay before dots light up (1-2.5 seconds) - builds anticipation
        let waitDelay = Double.random(in: 1.0...2.5)

        tappyRoundTask?.cancel()
        tappyRoundTask = Task { [weak self] in
            guard let self else { return }

            // Wait phase
            try? await Task.sleep(nanoseconds: UInt64(waitDelay * 1_000_000_000))
            if Task.isCancelled { return }

            await MainActor.run {
                self.lightUpTappyDots()
            }
        }
    }

    private func lightUpTappyDots() {
        // Pick N random dots for this round (N = round number)
        let dotsToLight = min(tappyRound, Self.totalDots)
        let shuffled = Array(0..<Self.totalDots).shuffled()
        tappyTargetDots = Set(shuffled.prefix(dotsToLight))
        tappyTappedDots = []

        // Calculate time limit - gets tighter as rounds progress
        // Round 1: 2.0s, Round 5: 1.5s, Round 10: 1.0s, Round 15+: 0.7s
        let timeLimit: Double
        if tappyRound <= 5 {
            timeLimit = tappyBaseTimeLimit - (Double(tappyRound - 1) * 0.1)  // 2.0 -> 1.6
        } else if tappyRound <= 10 {
            timeLimit = 1.5 - (Double(tappyRound - 6) * 0.1)  // 1.5 -> 1.0
        } else {
            timeLimit = max(0.7, 1.0 - (Double(tappyRound - 11) * 0.05))  // 1.0 -> 0.7 min
        }

        tappyTimeRemaining = timeLimit
        tappyTimerStartDate = Date()
        tappyState = .active

        // Light up the dots
        withAnimation(.spring(response: 0.15, dampingFraction: 0.7)) {
            active = tappyTargetDots
        }

        soundManager.play(.pop)

        // Start the countdown timer
        startTappyTimer(timeLimit: timeLimit)
    }

    private func startTappyTimer(timeLimit: Double) {
        tappyRoundTask?.cancel()
        tappyRoundTask = Task { [weak self] in
            guard let self else { return }

            let tickInterval: UInt64 = 16_666_667  // ~60fps for smooth animation

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: tickInterval)

                let shouldStop = await MainActor.run { () -> Bool in
                    guard self.isRunning, self.tappyState == .active,
                          let startDate = self.tappyTimerStartDate else { return true }

                    // Calculate remaining time
                    let elapsed = Date().timeIntervalSince(startDate)
                    let remaining = timeLimit - elapsed

                    if remaining <= 0 {
                        self.tappyTimeRemaining = 0
                        self.handleTappyTimeout()
                        return true
                    } else {
                        self.tappyTimeRemaining = remaining
                        return false
                    }
                }

                if shouldStop {
                    break
                }
            }
        }
    }

    private func handleTappyTimeout() {
        // Time ran out - lose a life
        tappyRoundTask?.cancel()
        tappyState = .failed

        lives -= 1
        UINotificationFeedbackGenerator().notificationOccurred(.warning)

        // Flash the missed dots briefly
        let missedDots = tappyTargetDots.subtracting(tappyTappedDots)

        if lives <= 0 {
            // Game over - show missed dots then end
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    guard let self else { return }
                    withAnimation(.easeOut(duration: 0.2)) {
                        self.active = []
                    }
                    self.triggerGameOver()
                }
            }
        } else {
            // Still have lives - brief pause then restart same round
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                await MainActor.run {
                    guard let self, self.isRunning else { return }
                    // Retry the same round (don't increment tappyRound)
                    self.tappyRound -= 1
                    self.startNextTappyRound()
                }
            }
        }
    }

    private func handleTappyTap(_ index: Int) {
        // Only process taps during active phase
        guard tappyState == .active else { return }

        // Check if this is a target dot that hasn't been tapped yet
        if tappyTargetDots.contains(index) && !tappyTappedDots.contains(index) {
            // Correct tap!
            soundManager.play(.pop)
            playBubblePopHaptic()

            tappyTappedDots.insert(index)
            bounceIndividual[index, default: 0] += 1

            // Turn off the tapped dot
            withAnimation(.easeOut(duration: 0.1)) {
                active.remove(index)
            }

            // Check if all dots tapped
            if tappyTappedDots == tappyTargetDots {
                // Round complete!
                tappyRoundTask?.cancel()
                tappyState = .roundComplete

                // Brief celebration then next round
                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s pause
                    await MainActor.run {
                        guard let self, self.isRunning else { return }
                        self.startNextTappyRound()
                    }
                }
            }
        }
        // No penalty for tapping wrong dots - just ignore
    }

    /// Time limit for current Tappy round (for UI display)
    func tappyCurrentTimeLimit() -> Double {
        if tappyRound <= 5 {
            return tappyBaseTimeLimit - (Double(tappyRound - 1) * 0.1)
        } else if tappyRound <= 10 {
            return 1.5 - (Double(tappyRound - 6) * 0.1)
        } else {
            return max(0.7, 1.0 - (Double(tappyRound - 11) * 0.05))
        }
    }

    // MARK: - Seeky Mode (Find the odd one)

    private func beginSeekyRound() {
        // No timer - round based
        seekyRound += 1
        lives = currentMode.startingLives  // Reset lives on first round only handled in resetModeState

        setupSeekyPuzzle()
    }

    // Vibrant colors for Seeky rounds
    private static let seekyColors: [Color] = [
        Color(hex: "#FF6B6B"),  // Coral red
        Color(hex: "#4ECDC4"),  // Teal
        Color(hex: "#FFE66D"),  // Yellow
        Color(hex: "#95E1D3"),  // Mint
        Color(hex: "#DDA0DD"),  // Plum
        Color(hex: "#7DD3FC"),  // Sky blue
        Color(hex: "#A3E635"),  // Lime
        Color(hex: "#FB923C"),  // Orange
        Color(hex: "#F472B6"),  // Pink
        Color(hex: "#A78BFA"),  // Purple
    ]

    private func setupSeekyPuzzle() {
        // Cancel any existing timer
        seekyTimerTask?.cancel()

        // Pick a random dot to be the odd one
        seekyOddDot = Int.random(in: 0..<Self.totalDots)

        // Pick a random color for this round (different from last if possible)
        var newColorIndex = Int.random(in: 0..<Self.seekyColors.count)
        let currentColorIndex = Self.seekyColors.firstIndex(where: { $0 == seekyBaseColor })
        if let current = currentColorIndex, Self.seekyColors.count > 1 {
            while newColorIndex == current {
                newColorIndex = Int.random(in: 0..<Self.seekyColors.count)
            }
        }
        seekyBaseColor = Self.seekyColors[newColorIndex]

        // Saturation difference - odd dot is slightly less saturated (washed out)
        seekyDifference = .color

        // Calculate difficulty - saturation difference becomes subtler each round
        // Round 1: 0.35 (35% less saturated - easy layup)
        // Round 5: ~0.18 (getting harder)
        // Round 10+: ~0.06 (very subtle but still perceptible)
        let baseAmount: CGFloat = 0.35
        let minAmount: CGFloat = 0.04  // Always at least 4% difference
        let decay: CGFloat = 0.85
        seekyDifferenceAmount = max(minAmount, baseAmount * pow(decay, CGFloat(seekyRound - 1)))

        // All dots "active" for display purposes
        active = Set(0..<Self.totalDots)

        soundManager.play(.pop)

        // Start the countdown timer
        startSeekyTimer()
    }

    private func startSeekyTimer() {
        seekyTimerStartDate = Date()
        seekyTimeRemaining = seekyTimeLimit

        seekyTimerTask = Task { [weak self] in
            let tickInterval: UInt64 = 16_666_667  // ~60fps for smooth animation

            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: tickInterval)

                let shouldStop = await MainActor.run { () -> Bool in
                    guard let self, self.isRunning, !self.seekyRevealingAnswer,
                          let startDate = self.seekyTimerStartDate else { return true }

                    // Calculate remaining time based on actual elapsed time
                    let elapsed = Date().timeIntervalSince(startDate)
                    let remaining = self.seekyTimeLimit - elapsed

                    if remaining <= 0 {
                        self.seekyTimeRemaining = 0
                        self.handleSeekyTimeout()
                        return true
                    } else {
                        self.seekyTimeRemaining = remaining
                        return false
                    }
                }

                if shouldStop {
                    break
                }
            }
        }
    }

    private func handleSeekyTimeout() {
        // Time ran out - treat as wrong guess
        seekyTimerTask?.cancel()
        seekyTimerTask = nil

        lives -= 1
        UINotificationFeedbackGenerator().notificationOccurred(.warning)

        if lives <= 0 {
            // Reveal the correct answer with pulsating animation before game over
            seekyRevealingAnswer = true

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    guard let self else { return }
                    self.seekyRevealingAnswer = false
                    self.triggerGameOver()
                }
            }
        } else {
            // Still have lives - show correct answer briefly then next puzzle
            seekyRevealingAnswer = true

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second reveal
                await MainActor.run {
                    guard let self, self.isRunning else { return }
                    self.seekyRevealingAnswer = false
                    self.setupSeekyPuzzle()
                }
            }
        }
    }

    private func handleSeekyTap(_ index: Int) {
        // Cancel the timer on any tap
        seekyTimerTask?.cancel()
        seekyTimerTask = nil

        if index == seekyOddDot {
            // Correct! Found the odd one
            soundManager.play(.popUp)
            HapticsManager.shared.medium()

            // Flash the correct dot
            bounceIndividual[index, default: 0] += 1
            triggerRipple(from: index)

            addPoint()

            // Brief pause then next round
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 600_000_000)
                await MainActor.run {
                    guard let self, self.isRunning else { return }
                    self.setupSeekyPuzzle()
                }
            }
        } else {
            // Wrong tap - lose a life
            lives -= 1
            UINotificationFeedbackGenerator().notificationOccurred(.warning)

            // Brief shake on wrong dot
            bounceIndividual[index, default: 0] += 1

            if lives <= 0 {
                // Reveal the correct answer with pulsating animation before game over
                seekyRevealingAnswer = true

                Task { [weak self] in
                    // Pulsate for ~1.5 seconds (3 pulses)
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    await MainActor.run {
                        guard let self else { return }
                        self.seekyRevealingAnswer = false
                        self.triggerGameOver()
                    }
                }
            } else {
                // Still have lives - show correct answer briefly then next puzzle
                seekyRevealingAnswer = true

                Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second reveal
                    await MainActor.run {
                        guard let self, self.isRunning else { return }
                        self.seekyRevealingAnswer = false
                        self.setupSeekyPuzzle()
                    }
                }
            }
        }
    }

    // MARK: - Round End

    /// End the current game early (used by end game button)
    func endGameEarly() {
        guard isRunning else { return }
        stopTimers()

        withAnimation(.none) {
            isRunning = false
            popReady = false
            isUrgent = false
            lastHapticSecond = -1
            remaining = Double(roundLength)
            resetBoard()
            cooldownActive = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                self.bounceAll += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.none) {
                self.cooldownActive = false
            }
        }
    }

    private func finishRound() {
        stopTimers()

        AnalyticsManager.shared.trackGameComplete(
            score: score,
            duration: roundLength,
            isNewHigh: isNewHighScore,
            timeLimitSeconds: roundLength,
            mode: currentMode
        )

        // Submit to appropriate leaderboard based on mode
        switch currentMode {
        case .classic:
            GameCenterManager.shared.submitClassicScore(score, duration: roundLength)
        case .boppy:
            GameCenterManager.shared.submitBoppyScore(score, duration: roundLength)
        default:
            break
        }

        withAnimation(.none) {
            isRunning = false
            popReady = false
            isUrgent = false
            lastHapticSecond = -1
            remaining = Double(roundLength)
            resetBoard()
            cooldownActive = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                self.bounceAll += 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.none) {
                self.cooldownActive = false
            }
        }
    }

    private func stopTimers() {
        countdownTask?.cancel()
        tickerTask?.cancel()
        boppySpawnTask?.cancel()
        boppyCleanupTask?.cancel()
        zoomySpawnTask?.cancel()
        zoomyUpdateTask?.cancel()
        countdownTask = nil
        tickerTask = nil
        boppySpawnTask = nil
        boppyCleanupTask = nil
        zoomySpawnTask = nil
        zoomyUpdateTask = nil
    }

    // MARK: - Gameplay

    /// Single entry point for taps from the board
    func tapDot(_ index: Int) {
        if isRunning {
            handleRunningTap(index)
        } else {
            handleFidgetTap(index)
        }
    }

    private func handleRunningTap(_ index: Int) {
        switch currentMode {
        case .classic, .daily:
            handleClassicTap(index)
        case .copy:
            handleCopyTap(index)
        case .boppy:
            handleBoppyTap(index)
        case .matchy:
            handleMatchyTap(index)
        case .zoomy:
            // Zoomy handles taps via tapZoomyDot() directly
            break
        case .tappy:
            handleTappyTap(index)
        case .seeky:
            handleSeekyTap(index)
        }
    }

    private func handleClassicTap(_ index: Int) {
        // Lose if tapping a raised inactive dot (not active, not already pressed)
        if !active.contains(index) && !pressed.contains(index) {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            triggerGameOver()
            return
        }

        guard active.contains(index) else { return }

        soundManager.play(.pop)
        playBubblePopHaptic()
        triggerRipple(from: index)

        withAnimation(.none) {
            addPoint()
            pressed.insert(index)
            active.remove(index)

            if pressed.count < Self.totalDots {
                if let newIdx = nextInactiveNotPressed() {
                    active.insert(newIdx)
                }
            } else {
                popReady = true
            }
        }
    }

    private func handleFidgetTap(_ index: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        soundManager.play(.pop)

        bounceIndividual[index, default: 0] += 1
        idleTapFlash[index, default: 0] += 1
        triggerRipple(from: index)

        fidget.insert(index)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            _ = await MainActor.run {
                self?.fidget.remove(index)
            }
        }
    }

    func pressPop() {
        guard popReady else { return }

        soundManager.play(.popUp)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        var tx = Transaction()
        tx.animation = nil
        withTransaction(tx) {
            popReady = false
            resetBoard()
            seedActive()
            boardEpoch &+= 1
        }

        bounceAll += 1
    }

    // MARK: - Haptics

    private func playBubblePopHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }

        let event1 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ],
            relativeTime: 0
        )

        let event2 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: 0.04
        )

        do {
            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }

    private func playUrgencyHaptic(secondsLeft: Int) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            let style: UIImpactFeedbackGenerator.FeedbackStyle = secondsLeft <= 2 ? .heavy : .medium
            UIImpactFeedbackGenerator(style: style).impactOccurred()
            return
        }

        let intensity: Float = secondsLeft == 1 ? 1.0 : (secondsLeft == 2 ? 0.8 : 0.6)
        let sharpness: Float = secondsLeft == 1 ? 0.9 : 0.7

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    // MARK: - Game Over

    private func triggerGameOver() {
        soundManager.play(.gameOver)

        stopTimers()

        // Submit scores for lives-based modes
        switch currentMode {
        case .zoomy:
            GameCenterManager.shared.submitZoomyScore(score)
        case .tappy:
            GameCenterManager.shared.submitTappyScore(score)
        case .seeky:
            GameCenterManager.shared.submitSeekyScore(score)
        default:
            break
        }

        withAnimation(.none) {
            isRunning = false
            popReady = false
            gameOver = true
            resetBoard()
        }
    }

    func dismissGameOver() {
        resetToIdle()
    }

    func resetToIdle() {
        withAnimation(.none) {
            gameOver = false
            isRunning = false
            isCountingDown = false
            countdown = nil
            popReady = false
            remaining = Double(roundLength)
            isNewHighScore = false
            isUrgent = false
            lastHapticSecond = -1
            cooldownActive = false
            resetBoard()

            bounceAll += 1
        }
    }

    // MARK: - Helpers

    private func addPoint(_ n: Int = 1) {
        score += n
        scoreBump.toggle()

        if !isNewHighScore && score > highScoreThreshold && highScoreThreshold > 0 {
            isNewHighScore = true

            highScoreFlash = true
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 800_000_000)
                await MainActor.run {
                    self?.highScoreFlash = false
                }
            }

            AnalyticsManager.shared.trackHighScore(
                score: score,
                duration: roundLength,
                mode: currentMode
            )

            soundManager.play(.newHigh)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func nextInactiveNotPressed() -> Int? {
        let remaining = Set(0..<Self.totalDots).subtracting(pressed).subtracting(active)
        return remaining.randomElement()
    }

    private func seedActive() {
        active.removeAll()
        var pool = Array(0..<Self.totalDots)
        pool.shuffle()

        for i in 0..<min(Self.activeCount, pool.count) {
            active.insert(pool[i])
        }
    }

    private func resetBoard() {
        active.removeAll()
        pressed.removeAll()
        fidget.removeAll()
    }

    // MARK: - Ripple Displacement

    private func triggerRipple(from tappedIndex: Int) {
        let layout = [
            [0, 1, 2],
            [3, 4, 5, 6],
            [7, 8, 9]
        ]

        var tappedRow = 0
        var tappedCol = 0
        for (r, row) in layout.enumerated() {
            if let c = row.firstIndex(of: tappedIndex) {
                tappedRow = r
                tappedCol = c
                break
            }
        }

        var adjacentDots: [Int] = []

        let currentRow = layout[tappedRow]
        if tappedCol > 0 {
            adjacentDots.append(currentRow[tappedCol - 1])
        }
        if tappedCol < currentRow.count - 1 {
            adjacentDots.append(currentRow[tappedCol + 1])
        }

        if tappedRow > 0 {
            let aboveRow = layout[tappedRow - 1]
            let offset = (aboveRow.count < currentRow.count) ? 1 : -1
            let aboveCol = tappedCol + offset
            if aboveCol >= 0 && aboveCol < aboveRow.count {
                adjacentDots.append(aboveRow[aboveCol])
            }
        }

        if tappedRow < layout.count - 1 {
            let belowRow = layout[tappedRow + 1]
            let offset = (belowRow.count < currentRow.count) ? 1 : -1
            let belowCol = tappedCol + offset
            if belowCol >= 0 && belowCol < belowRow.count {
                adjacentDots.append(belowRow[belowCol])
            }
        }

        for dotIndex in adjacentDots {
            let direction = calculateDirection(from: tappedIndex, to: dotIndex, layout: layout)
            let displacement = CGPoint(x: direction.x * 1.0, y: direction.y * 1.0)

            withAnimation(.easeOut(duration: 0.6)) {
                rippleDisplacements[dotIndex] = displacement
            }

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 600_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self?.rippleDisplacements[dotIndex] = .zero
                    }
                }
            }
        }
    }

    private func calculateDirection(from: Int, to: Int, layout: [[Int]]) -> CGPoint {
        var fromPos = CGPoint.zero
        var toPos = CGPoint.zero

        for (r, row) in layout.enumerated() {
            if let c = row.firstIndex(of: from) {
                fromPos = CGPoint(x: c, y: r)
            }
            if let c = row.firstIndex(of: to) {
                toPos = CGPoint(x: c, y: r)
            }
        }

        let dx = toPos.x - fromPos.x
        let dy = toPos.y - fromPos.y
        let length = sqrt(dx * dx + dy * dy)

        if length > 0 {
            return CGPoint(x: dx / length, y: dy / length)
        }
        return .zero
    }

    // MARK: - Theme Change Wave

    func triggerThemeWave() {
        let layout = [
            [0, 1, 2],
            [3, 4, 5, 6],
            [7, 8, 9]
        ]

        let waveOrigin = CGPoint(x: -1.5, y: -0.5)

        var dotDistances: [(index: Int, distance: CGFloat, direction: CGPoint)] = []

        for (r, row) in layout.enumerated() {
            for (c, dotIndex) in row.enumerated() {
                let dotPos = CGPoint(x: CGFloat(c), y: CGFloat(r))

                let dx = dotPos.x - waveOrigin.x
                let dy = dotPos.y - waveOrigin.y
                let distance = sqrt(dx * dx + dy * dy)

                let length = max(distance, 0.001)
                let direction = CGPoint(x: dx / length, y: dy / length)

                dotDistances.append((dotIndex, distance, direction))
            }
        }

        dotDistances.sort { $0.distance < $1.distance }

        for (i, dotInfo) in dotDistances.enumerated() {
            let initialDelay = 0.35
            let delay = initialDelay + (Double(i) * 0.05)
            let displacement = CGPoint(
                x: dotInfo.direction.x * 12,
                y: dotInfo.direction.y * 12
            )

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await MainActor.run {
                    withAnimation(.easeOut(duration: 0.5)) {
                        self?.themeWaveDisplacements[dotInfo.index] = displacement
                    }

                    Task { [weak self] in
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.7)) {
                                self?.themeWaveDisplacements[dotInfo.index] = .zero
                            }
                        }
                    }
                }
            }
        }
    }
}
