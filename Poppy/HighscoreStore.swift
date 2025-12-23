//
//  HighscoreStore.swift
//  Poppy
//
//  Stores high scores for all game modes
//  - Classic/Daily/Boppy/Zoomy/Tappy: best score per duration
//  - Copy/Matchy/Seeky: single best score each
//

import Foundation
import Combine

@MainActor
final class HighscoreStore: ObservableObject {
    // Timed modes: best score per round length in seconds
    @Published private(set) var classicBest: [Int: Int] = [:]
    @Published private(set) var boppyBest: [Int: Int] = [:]
    @Published private(set) var zoomyBest: [Int: Int] = [:]
    @Published private(set) var tappyBest: [Int: Int] = [:]

    // Daily mode tracking
    @Published private(set) var dailyBest: Int = 0           // Best score ever in Daily
    @Published private(set) var dailyTodayScore: Int? = nil  // Score for today (nil if not played)
    @Published private(set) var dailyLastPlayedDate: String = ""  // "YYYY-MM-DD" format
    @Published private(set) var dailyStreak: Int = 0         // Consecutive days played

    // Untimed modes: single best score each
    @Published private(set) var copyClassicBest: Int = 0    // Highest round reached (4-dot Classic)
    @Published private(set) var copyChallengeBest: Int = 0  // Highest round reached (10-dot Challenge)
    @Published private(set) var matchyBest: Int = 0    // Best pairs/attempts ratio or fastest time
    @Published private(set) var seekyBest: Int = 0     // Highest round reached

    // Legacy compatibility - maps to classicBest
    var best: [Int: Int] {
        get { classicBest }
        set { classicBest = newValue }
    }

    // UserDefaults keys
    private let classicKey = "poppy.best.scores"  // Keep legacy key for Classic
    private let dailyKey = "poppy.best.daily"
    private let dailyTodayKey = "poppy.daily.todayScore"
    private let dailyLastPlayedKey = "poppy.daily.lastPlayed"
    private let dailyStreakKey = "poppy.daily.streak"
    private let boppyKey = "poppy.best.boppy"
    private let zoomyKey = "poppy.best.zoomy"
    private let tappyKey = "poppy.best.tappy"
    private let copyClassicKey = "poppy.best.copy.classic"
    private let copyChallengeKey = "poppy.best.copy.challenge"
    private let matchyKey = "poppy.best.matchy"
    private let seekyKey = "poppy.best.seeky"

    init() {
        loadScores()
    }

    private func loadScores() {
        // Load Classic scores (legacy format)
        if let data = UserDefaults.standard.dictionary(forKey: classicKey) as? [String: Int] {
            var out: [Int: Int] = [:]
            for (k, v) in data where Int(k) != nil {
                out[Int(k)!] = v
            }
            classicBest = out
        }

        // Load timed mode scores
        if let data = UserDefaults.standard.dictionary(forKey: boppyKey) as? [String: Int] {
            boppyBest = data.reduce(into: [:]) { result, pair in
                if let key = Int(pair.key) { result[key] = pair.value }
            }
        }
        if let data = UserDefaults.standard.dictionary(forKey: zoomyKey) as? [String: Int] {
            zoomyBest = data.reduce(into: [:]) { result, pair in
                if let key = Int(pair.key) { result[key] = pair.value }
            }
        }
        if let data = UserDefaults.standard.dictionary(forKey: tappyKey) as? [String: Int] {
            tappyBest = data.reduce(into: [:]) { result, pair in
                if let key = Int(pair.key) { result[key] = pair.value }
            }
        }

        // Load Daily mode state
        dailyBest = UserDefaults.standard.integer(forKey: dailyKey)
        dailyLastPlayedDate = UserDefaults.standard.string(forKey: dailyLastPlayedKey) ?? ""
        dailyStreak = UserDefaults.standard.integer(forKey: dailyStreakKey)

        // Check if today's score is valid (was played today)
        let todayString = Self.todayDateString()
        if dailyLastPlayedDate == todayString {
            let todayScore = UserDefaults.standard.integer(forKey: dailyTodayKey)
            dailyTodayScore = todayScore > 0 ? todayScore : nil
        } else {
            dailyTodayScore = nil

            // Check if streak should be reset (missed a day)
            // Streak is valid only if last played was today or yesterday
            if !dailyLastPlayedDate.isEmpty {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
                    let yesterdayString = formatter.string(from: yesterday)
                    if dailyLastPlayedDate != yesterdayString {
                        // Missed more than one day, reset streak to 0
                        dailyStreak = 0
                        UserDefaults.standard.set(0, forKey: dailyStreakKey)
                    }
                }
            }
        }

        // Load untimed mode scores
        copyClassicBest = UserDefaults.standard.integer(forKey: copyClassicKey)
        copyChallengeBest = UserDefaults.standard.integer(forKey: copyChallengeKey)
        matchyBest = UserDefaults.standard.integer(forKey: matchyKey)
        seekyBest = UserDefaults.standard.integer(forKey: seekyKey)
    }

    // MARK: - Daily Mode Helpers

    /// Returns today's date as "YYYY-MM-DD" string
    static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    /// Check if user has already played Daily mode today
    func hasPlayedDailyToday() -> Bool {
        return dailyTodayScore != nil && dailyLastPlayedDate == Self.todayDateString()
    }

    /// Register a Daily mode score for today
    func registerDailyScore(_ score: Int) {
        let today = Self.todayDateString()

        // Update today's score
        dailyTodayScore = score
        UserDefaults.standard.set(score, forKey: dailyTodayKey)

        // Submit to Game Center daily leaderboard
        GameCenterManager.shared.submitDailyScore(score)

        // Update streak
        if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let yesterdayString = formatter.string(from: yesterday)

            if dailyLastPlayedDate == yesterdayString {
                // Played yesterday, increment streak
                dailyStreak += 1
            } else if dailyLastPlayedDate != today {
                // Missed a day (or first play), reset streak to 1
                dailyStreak = 1
            }
            // If already played today, streak doesn't change
        }

        // Update last played date
        dailyLastPlayedDate = today
        UserDefaults.standard.set(today, forKey: dailyLastPlayedKey)
        UserDefaults.standard.set(dailyStreak, forKey: dailyStreakKey)

        // Update best if applicable
        if score > dailyBest {
            dailyBest = score
            UserDefaults.standard.set(score, forKey: dailyKey)
        }
    }

    /// Get the seeded random generator for today's Daily puzzle
    /// Uses a deterministic hash with mixing to ensure good distribution
    static func dailySeedForToday() -> UInt64 {
        let today = todayDateString()
        let input = "poppy-daily-\(today)"

        // FNV-1a hash - better distribution than djb2
        var hash: UInt64 = 14695981039346656037 // FNV offset basis
        for char in input.utf8 {
            hash ^= UInt64(char)
            hash = hash &* 1099511628211 // FNV prime
        }

        // Additional mixing (xorshift) to break any patterns
        hash ^= hash >> 33
        hash = hash &* 0xff51afd7ed558ccd
        hash ^= hash >> 33
        hash = hash &* 0xc4ceb9fe1a85ec53
        hash ^= hash >> 33

        return hash
    }

    /// Get today's Daily mode duration (10-60 seconds, no repeats within cycle)
    /// Uses a pre-shuffled sequence that guarantees each duration appears once
    /// before any repeat
    static func dailyDurationForToday() -> Int {
        // All possible durations: 10, 11, 12, ... 60 (51 values)
        let allDurations = Array(10...60)

        // Get day of year (1-366)
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let year = calendar.component(.year, from: Date())

        // Create a seeded shuffle based on year
        // This ensures the sequence is the same all year, but different each year
        var shuffled = allDurations
        var rng = SeededRNG(seed: UInt64(year) &* 2654435761)
        shuffled.shuffle(using: &rng)

        // Use day of year to index into shuffled array (wrapping if needed)
        let index = (dayOfYear - 1) % shuffled.count
        return shuffled[index]
    }

    // MARK: - Generic Registration

    /// Register a score for any game mode
    func register(score: Int, mode: GameMode, duration: Int? = nil) {
        switch mode {
        case .classic:
            if let seconds = duration {
                registerTimed(score: score, for: seconds, dict: &classicBest, key: classicKey)
            }
        case .daily:
            registerDailyScore(score)
        case .boppy:
            if let seconds = duration {
                registerTimed(score: score, for: seconds, dict: &boppyBest, key: boppyKey)
            }
        case .zoomy:
            if let seconds = duration {
                registerTimed(score: score, for: seconds, dict: &zoomyBest, key: zoomyKey)
            }
        case .tappy:
            if let seconds = duration {
                registerTimed(score: score, for: seconds, dict: &tappyBest, key: tappyKey)
            }
        case .copy:
            // Copy mode uses registerCopyScore with difficulty parameter
            break
        case .matchy:
            if score > matchyBest {
                matchyBest = score
                UserDefaults.standard.set(score, forKey: matchyKey)
            }
        case .seeky:
            if score > seekyBest {
                seekyBest = score
                UserDefaults.standard.set(score, forKey: seekyKey)
            }
        }
    }

    /// Get the best score for a mode
    func getBest(for mode: GameMode, duration: Int? = nil) -> Int {
        switch mode {
        case .classic:
            if let seconds = duration {
                return classicBest[seconds] ?? 0
            }
            return 0
        case .daily:
            return dailyBest
        case .boppy:
            if let seconds = duration {
                return boppyBest[seconds] ?? 0
            }
            return 0
        case .zoomy:
            if let seconds = duration {
                return zoomyBest[seconds] ?? 0
            }
            return 0
        case .tappy:
            if let seconds = duration {
                return tappyBest[seconds] ?? 0
            }
            return 0
        case .copy:
            // Use getCopyBest(for:) instead for difficulty-specific scores
            return copyClassicBest
        case .matchy:
            return matchyBest
        case .seeky:
            return seekyBest
        }
    }

    // MARK: - Copy Mode (Difficulty-Specific)

    /// Register a Copy mode score for a specific difficulty
    func registerCopyScore(_ score: Int, difficulty: CopyDifficulty) {
        switch difficulty {
        case .classic:
            if score > copyClassicBest {
                copyClassicBest = score
                UserDefaults.standard.set(score, forKey: copyClassicKey)
            }
        case .challenge:
            if score > copyChallengeBest {
                copyChallengeBest = score
                UserDefaults.standard.set(score, forKey: copyChallengeKey)
            }
        }
    }

    /// Get the best Copy mode score for a specific difficulty
    func getCopyBest(for difficulty: CopyDifficulty) -> Int {
        switch difficulty {
        case .classic:
            return copyClassicBest
        case .challenge:
            return copyChallengeBest
        }
    }

    // MARK: - Helpers

    private func registerTimed(score: Int, for seconds: Int, dict: inout [Int: Int], key: String) {
        if score > (dict[seconds] ?? 0) {
            dict[seconds] = score
            var toSave: [String: Int] = [:]
            for (k, v) in dict { toSave["\(k)"] = v }
            UserDefaults.standard.set(toSave, forKey: key)
        }
    }

    // MARK: - Legacy Classic Mode Support

    func register(score: Int, for seconds: Int) {
        registerTimed(score: score, for: seconds, dict: &classicBest, key: classicKey)
    }

    // MARK: - Reset

    func reset() {
        // Reset all modes
        classicBest = [:]
        dailyBest = 0
        dailyTodayScore = nil
        dailyLastPlayedDate = ""
        dailyStreak = 0
        boppyBest = [:]
        zoomyBest = [:]
        tappyBest = [:]
        copyClassicBest = 0
        copyChallengeBest = 0
        matchyBest = 0
        seekyBest = 0

        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: classicKey)
        UserDefaults.standard.removeObject(forKey: dailyKey)
        UserDefaults.standard.removeObject(forKey: dailyTodayKey)
        UserDefaults.standard.removeObject(forKey: dailyLastPlayedKey)
        UserDefaults.standard.removeObject(forKey: dailyStreakKey)
        UserDefaults.standard.removeObject(forKey: boppyKey)
        UserDefaults.standard.removeObject(forKey: zoomyKey)
        UserDefaults.standard.removeObject(forKey: tappyKey)
        UserDefaults.standard.removeObject(forKey: copyClassicKey)
        UserDefaults.standard.removeObject(forKey: copyChallengeKey)
        UserDefaults.standard.removeObject(forKey: matchyKey)
        UserDefaults.standard.removeObject(forKey: seekyKey)
    }

    /// Reset scores for a specific mode only
    func reset(mode: GameMode) {
        switch mode {
        case .classic:
            classicBest = [:]
            UserDefaults.standard.removeObject(forKey: classicKey)
        case .daily:
            dailyBest = 0
            dailyTodayScore = nil
            dailyLastPlayedDate = ""
            dailyStreak = 0
            UserDefaults.standard.removeObject(forKey: dailyKey)
            UserDefaults.standard.removeObject(forKey: dailyTodayKey)
            UserDefaults.standard.removeObject(forKey: dailyLastPlayedKey)
            UserDefaults.standard.removeObject(forKey: dailyStreakKey)
        case .boppy:
            boppyBest = [:]
            UserDefaults.standard.removeObject(forKey: boppyKey)
        case .zoomy:
            zoomyBest = [:]
            UserDefaults.standard.removeObject(forKey: zoomyKey)
        case .tappy:
            tappyBest = [:]
            UserDefaults.standard.removeObject(forKey: tappyKey)
        case .copy:
            copyClassicBest = 0
            copyChallengeBest = 0
            UserDefaults.standard.removeObject(forKey: copyClassicKey)
            UserDefaults.standard.removeObject(forKey: copyChallengeKey)
        case .matchy:
            matchyBest = 0
            UserDefaults.standard.removeObject(forKey: matchyKey)
        case .seeky:
            seekyBest = 0
            UserDefaults.standard.removeObject(forKey: seekyKey)
        }
    }
}

// MARK: - Seeded RNG for Daily Mode

/// Simple seeded RNG for deterministic shuffling
private struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
