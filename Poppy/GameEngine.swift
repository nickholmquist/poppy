import Foundation
import Combine
import UIKit
import SwiftUI
import CoreHaptics
import AudioToolbox

@MainActor
final class GameEngine: ObservableObject {
    
    private var countdownTask: Task<Void, Never>?
    private var tickerTask: Task<Void, Never>?
    private var hapticEngine: CHHapticEngine?
    private let soundManager = SoundManager.shared
    
    // Board config
    static let totalDots = 10
    static let activeCount = 3

    // Game state
    @Published var isRunning = false
    @Published var isCountingDown = false
    @Published var countdown: Int? = nil
    @Published var gameOver = false

    @Published var score = 0
    @Published var remaining: Double = 30

    @Published var active: Set<Int> = []   // currently lit
    @Published var pressed: Set<Int> = []  // pressed in this cycle
    @Published var popReady = false        // true when all 10 are pressed
    @Published var boardEpoch: Int = 0
    
    // Bounce animation triggers - increment to trigger bounce on specific dots
    @Published var bounceAll: Int = 0      // triggers bounce on all dots
    @Published var bounceIndividual: [Int: Int] = [:]  // triggers bounce on individual dot
    
    // Ripple displacement
    @Published var rippleDisplacements: [Int: CGPoint] = [:]  // offset for each dot
    
    // Idle tap flashes
    @Published var idleTapFlash: [Int: Int] = [:]  // increment to trigger flash on idle tap
    
    // Theme change wave - NEW
    @Published var themeWaveDisplacements: [Int: CGPoint] = [:]  // wave from theme change

    // Idle fidget pops (visual signal if you wire it in the board)
    @Published var fidget: Set<Int> = []

    // UI signal for score pop animation
    @Published var scoreBump = false
    
    // High score tracking
    @Published var isNewHighScore = false
    private var highScoreThreshold: Int = 0
    
    // Last 5 seconds urgency - NEW
    @Published var isUrgent = false
    private var lastHapticSecond: Int = -1

    // Round length
    var roundLength: Int = 30 {
        didSet { if !isRunning { remaining = Double(roundLength) } }
    }

    // Timers
    private var ticker: Timer?
    private var countdownTimer: Timer?
    private var endTime: Date = .init()
    
    // Reference to highscore store - NEW
    private var highscoreStore: HighscoreStore?
    
    // MARK: - Initialization
    
    init() {
        setupHaptics()
    }
    
    // NEW - Set the highscore store reference
    func setHighscoreStore(_ store: HighscoreStore) {
        self.highscoreStore = store
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine creation error: \(error)")
        }
    }

    // MARK: Lifecycle

    func start() {
        guard !isRunning else { return }

        resetBoard()
        score = 0  // Reset score at START of new game
        gameOver = false
        
        // Set high score threshold for this round - NEW
        highScoreThreshold = highscoreStore?.best[roundLength] ?? 0
        isNewHighScore = false

        isCountingDown = true
        countdown = 3

        // Cancel any prior async work
        stopTimers()

        // Countdown loop on the main actor
        countdownTask = Task { [weak self] in
            guard let self else { return }
            while let c = self.countdown, c > 0 {
                // Play countdown sound
                self.soundManager.play(.countdown)
                
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                // Task may be cancelled while sleeping
                if Task.isCancelled { return }
                withAnimation(.none) { self.countdown = c - 1 }
            }

            // Done counting
            withAnimation(.none) { self.countdown = nil }
            self.beginRound()
        }
    }

    private func beginRound() {
        isCountingDown = false
        isRunning = true
        remaining = Double(roundLength)
        endTime = Date().addingTimeInterval(TimeInterval(roundLength))

        seedActive()

        // Cancel any previous ticker and start a new one
        tickerTask?.cancel()
        tickerTask = Task { [weak self] in
            guard let self else { return }
            while true {
                if Task.isCancelled { return }

                let left = self.endTime.timeIntervalSinceNow
                withAnimation(.none) {
                    self.remaining = max(0, left)
                }
                
                // Check for urgency zone (last 5 seconds) - NEW
                let secondsLeft = Int(ceil(left))
                if secondsLeft <= 5 && secondsLeft > 0 {
                    if !self.isUrgent {
                        withAnimation(.easeIn(duration: 0.3)) {
                            self.isUrgent = true
                        }
                    }
                    // Trigger haptic at each second countdown
                    if secondsLeft != self.lastHapticSecond {
                        self.lastHapticSecond = secondsLeft
                        self.playUrgencyHaptic(secondsLeft: secondsLeft)
                    }
                } else if self.isUrgent && secondsLeft > 5 {
                    // Reset if somehow time gets extended
                    withAnimation(.easeOut(duration: 0.3)) {
                        self.isUrgent = false
                    }
                }
                
                if left <= 0 {
                    self.finishRound()
                    return
                }

                try? await Task.sleep(nanoseconds: 50_000_000) // 50 ms
            }
        }
    }

    private func finishRound() {
        stopTimers()
        withAnimation(.none) {
            isRunning = false
            popReady = false
        }
    }

    private func stopTimers() {
        countdownTask?.cancel()
        tickerTask?.cancel()
        countdownTask = nil
        tickerTask = nil
    }


    // MARK: Gameplay

    /// Single entry point for taps from the board
    func tapDot(_ index: Int) {
        if isRunning {
            handleRunningTap(index)
        } else {
            handleFidgetTap(index)
        }
    }

    private func handleRunningTap(_ index: Int) {
        // Lose if tapping a raised inactive dot (not active, not already pressed)
        if !active.contains(index) && !pressed.contains(index) {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            triggerGameOver()
            return
        }

        // Correct tap on an active dot
        guard active.contains(index) else { return }

        // Play pop sound
        soundManager.play(.pop)
        
        // Bubble pop haptic using Core Haptics
        playBubblePopHaptic()
        
        // Trigger ripple on adjacent dots - NEW
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
        
        // Trigger bounce on idle tap
        bounceIndividual[index, default: 0] += 1
        
        // Trigger idle flash - NEW
        idleTapFlash[index, default: 0] += 1
        
        // Trigger ripple on adjacent dots - NEW
        triggerRipple(from: index)
        
        fidget.insert(index)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000) // ~150 ms
            _ = await MainActor.run {
                self?.fidget.remove(index)
            }
        }
    }

    func pressPop() {
        guard popReady else { return }
        
        // Play pop all sound
        soundManager.play(.popAll)
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Kill animations for the board reset transaction
        var tx = Transaction()
        tx.animation = nil
        withTransaction(tx) {
            popReady = false
            resetBoard()
            seedActive()
            boardEpoch &+= 1
        }
        
        // Trigger bounce AFTER resetting (when dots are raised again)
        bounceAll += 1
    }
    
    // MARK: - Bubble Pop Haptic
    
    private func playBubblePopHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            // Fallback to simple impact
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }
        
        var events: [CHHapticEvent] = []
        
        // Bubble pop feel: sharp initial hit, quick decay
        // Like popping bubble wrap - satisfying "snap"
        let event1 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ],
            relativeTime: 0
        )
        
        // Quick follow-up for the "release" feeling
        let event2 = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ],
            relativeTime: 0.04
        )
        
        events = [event1, event2]
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Fallback if pattern fails
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
    }
    
    // MARK: - Urgency Haptic (Last 5 Seconds)
    
    private func playUrgencyHaptic(secondsLeft: Int) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            // Fallback to simple impact with escalating intensity
            let style: UIImpactFeedbackGenerator.FeedbackStyle = secondsLeft <= 2 ? .heavy : .medium
            UIImpactFeedbackGenerator(style: style).impactOccurred()
            return
        }
        
        // Escalating intensity as we approach zero
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

    // Game over logic
    private func triggerGameOver() {
        // Play game over sound
        soundManager.play(.gameOver)
        
        stopTimers()
        withAnimation(.none) {
            isRunning = false
            popReady = false
            gameOver = true
            resetBoard() // all raised, white
        }
    }

    func dismissGameOver() {
        resetToIdle()
    }

    /// Public reset used by overlays
    func resetToIdle() {
        withAnimation(.none) {
            gameOver = false
            isRunning = false
            isCountingDown = false
            countdown = nil
            popReady = false
            remaining = Double(roundLength)
            isNewHighScore = false  // Reset high score indicator
            isUrgent = false  // Reset urgency flag
            lastHapticSecond = -1  // Reset haptic tracker
            resetBoard()
            // DON'T reset score here - let it persist until next start()
            
            // Trigger bounce on all dots when resetting
            bounceAll += 1
        }
    }

    // MARK: Helpers

    private func addPoint(_ n: Int = 1) {
        score += n
        scoreBump.toggle()
        
        // Check if we just crossed the high score threshold - NEW
        if !isNewHighScore && score > highScoreThreshold && highScoreThreshold > 0 {
            isNewHighScore = true
            
            // Play new high score sound
            soundManager.play(.newHigh)
            
            // Celebratory haptic
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
    
    /// Calculate adjacent dots and trigger displacement ripple
    private func triggerRipple(from tappedIndex: Int) {
        // 3-4-3 layout positions
        let layout = [
            // Row 0 (3 dots): indices 0, 1, 2
            [0, 1, 2],
            // Row 1 (4 dots): indices 3, 4, 5, 6
            [3, 4, 5, 6],
            // Row 2 (3 dots): indices 7, 8, 9
            [7, 8, 9]
        ]
        
        // Find position of tapped dot
        var tappedRow = 0
        var tappedCol = 0
        for (r, row) in layout.enumerated() {
            if let c = row.firstIndex(of: tappedIndex) {
                tappedRow = r
                tappedCol = c
                break
            }
        }
        
        // Find adjacent dots (orthogonal neighbors only - not diagonals)
        var adjacentDots: [Int] = []
        
        // Same row neighbors
        let currentRow = layout[tappedRow]
        if tappedCol > 0 {
            adjacentDots.append(currentRow[tappedCol - 1])  // Left
        }
        if tappedCol < currentRow.count - 1 {
            adjacentDots.append(currentRow[tappedCol + 1])  // Right
        }
        
        // Row above
        if tappedRow > 0 {
            let aboveRow = layout[tappedRow - 1]
            // Account for offset in 3-4-3 pattern
            let offset = (aboveRow.count < currentRow.count) ? 1 : -1
            let aboveCol = tappedCol + offset
            if aboveCol >= 0 && aboveCol < aboveRow.count {
                adjacentDots.append(aboveRow[aboveCol])
            }
        }
        
        // Row below
        if tappedRow < layout.count - 1 {
            let belowRow = layout[tappedRow + 1]
            // Account for offset in 3-4-3 pattern
            let offset = (belowRow.count < currentRow.count) ? 1 : -1
            let belowCol = tappedCol + offset
            if belowCol >= 0 && belowCol < belowRow.count {
                adjacentDots.append(belowRow[belowCol])
            }
        }
        
        // Apply displacement to adjacent dots
        for dotIndex in adjacentDots {
            // Calculate push direction (away from tapped dot)
            let direction = calculateDirection(from: tappedIndex, to: dotIndex, layout: layout)
            
            // Gentle drift - like idle boat wake
            let displacement = CGPoint(x: direction.x * 1.0, y: direction.y * 1.0)
            
            // Slow, soft drift away
            withAnimation(.easeOut(duration: 0.6)) {
                rippleDisplacements[dotIndex] = displacement
            }
            
            // Slow, soft drift back
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 600_000_000) // 600ms
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        self?.rippleDisplacements[dotIndex] = .zero
                    }
                }
            }
        }
    }
    
    /// Calculate direction vector from one dot to another
    private func calculateDirection(from: Int, to: Int, layout: [[Int]]) -> CGPoint {
        // Find positions
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
        
        // Calculate normalized direction
        let dx = toPos.x - fromPos.x
        let dy = toPos.y - fromPos.y
        let length = sqrt(dx * dx + dy * dy)
        
        if length > 0 {
            return CGPoint(x: dx / length, y: dy / length)
        }
        return .zero
    }
    
    // MARK: - Theme Change Wave
    
    /// Trigger wave effect radiating from top-left (theme dot position)
    func triggerThemeWave() {
        // 3-4-3 layout positions
        let layout = [
            [0, 1, 2],      // Row 0
            [3, 4, 5, 6],   // Row 1
            [7, 8, 9]       // Row 2
        ]
        
        // Theme dot is at top-left, so wave emanates from ~(-1, -1) position
        let waveOrigin = CGPoint(x: -1.5, y: -0.5)
        
        // Calculate distance and direction for each dot
        var dotDistances: [(index: Int, distance: CGFloat, direction: CGPoint)] = []
        
        for (r, row) in layout.enumerated() {
            for (c, dotIndex) in row.enumerated() {
                let dotPos = CGPoint(x: CGFloat(c), y: CGFloat(r))
                
                // Distance from wave origin
                let dx = dotPos.x - waveOrigin.x
                let dy = dotPos.y - waveOrigin.y
                let distance = sqrt(dx * dx + dy * dy)
                
                // Direction away from origin
                let length = max(distance, 0.001)
                let direction = CGPoint(x: dx / length, y: dy / length)
                
                dotDistances.append((dotIndex, distance, direction))
            }
        }
        
        // Sort by distance (closest dots react first)
        dotDistances.sort { $0.distance < $1.distance }
        
        // Trigger wave with cascading delays
        for (i, dotInfo) in dotDistances.enumerated() {
            let initialDelay = 0.35
            let delay = initialDelay + (Double(i) * 0.05)  // 80ms between each dot
            let displacement = CGPoint(
                x: dotInfo.direction.x * 12,  // Stronger push than ripple
                y: dotInfo.direction.y * 12
            )
            
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await MainActor.run {
                    // Push away
                    withAnimation(.easeOut(duration: 0.5)) {
                        self?.themeWaveDisplacements[dotInfo.index] = displacement
                    }
                    
                    // Drift back
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
