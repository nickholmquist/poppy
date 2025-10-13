import Foundation
import Combine
import UIKit
import SwiftUI
import CoreHaptics

@MainActor
final class GameEngine: ObservableObject {
    
    private var countdownTask: Task<Void, Never>?
    private var tickerTask: Task<Void, Never>?
    private var hapticEngine: CHHapticEngine?
    
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

    // Idle fidget pops (visual signal if you wire it in the board)
    @Published var fidget: Set<Int> = []

    // UI signal for score pop animation
    @Published var scoreBump = false

    // Round length
    var roundLength: Int = 30 {
        didSet { if !isRunning { remaining = Double(roundLength) } }
    }

    // Timers
    private var ticker: Timer?
    private var countdownTimer: Timer?
    private var endTime: Date = .init()
    
    // MARK: - Initialization
    
    init() {
        setupHaptics()
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

        isCountingDown = true
        countdown = 3

        // Cancel any prior async work
        stopTimers()

        // Countdown loop on the main actor
        countdownTask = Task { [weak self] in
            guard let self else { return }
            while let c = self.countdown, c > 0 {
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

        // Bubble pop haptic using Core Haptics
        playBubblePopHaptic()

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
        
        // Trigger bounce on idle tap
        bounceIndividual[index, default: 0] += 1
        
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

    // Game over logic
    private func triggerGameOver() {
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
}
