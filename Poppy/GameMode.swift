import Foundation
import SwiftUI

/// Game modes available in Poppy v1.2
/// - Free: Poppy, Daily, Matchy, Copy, Boppy
/// - Poppy Plus: Zoomy, Tappy, Seeky
enum GameMode: String, CaseIterable, Codable, Identifiable {
    case classic
    case daily
    case matchy
    case copy
    case boppy
    case zoomy
    case tappy
    case seeky

    var id: String { rawValue }

    /// Display name shown in UI
    var displayName: String {
        switch self {
        case .classic: return "Poppy"
        case .daily: return "Daily"
        case .matchy: return "Matchy"
        case .copy: return "Copy"
        case .boppy: return "Boppy"
        case .zoomy: return "Zoomy"
        case .tappy: return "Tappy"
        case .seeky: return "Seeky"
        }
    }

    /// SF Symbol icon for the mode
    var icon: String {
        switch self {
        case .classic: return "circle.grid.3x3.fill"
        case .daily: return "calendar"
        case .matchy: return "square.grid.2x2.fill"
        case .copy: return "doc.on.doc.fill"
        case .boppy: return "hand.tap.fill"
        case .zoomy: return "arrow.up.left.and.arrow.down.right"
        case .tappy: return "bolt.fill"
        case .seeky: return "eye.fill"
        }
    }

    /// Short description for the picker
    var description: String {
        switch self {
        case .classic: return "Tap dots, press POP, repeat"
        case .daily: return "One chance per day"
        case .matchy: return "Find matching pairs"
        case .copy: return "Repeat the sequence"
        case .boppy: return "Tap before they vanish"
        case .zoomy: return "Catch drifting dots"
        case .tappy: return "Survive all 10 rounds"
        case .seeky: return "Find the odd one out"
        }
    }

    /// Whether this mode requires Poppy Plus
    var requiresPlus: Bool {
        switch self {
        case .zoomy, .tappy, .seeky: return true
        default: return false
        }
    }

    /// Whether this mode is free (doesn't require purchase)
    var isFree: Bool {
        !requiresPlus
    }

    /// Whether this mode shows the time duration picker in the mode selector
    /// Note: Classic and Boppy duration is now controlled via header pills, not the mode picker
    var showsTimePicker: Bool {
        // No modes show duration in the mode picker anymore
        return false
    }

    /// Whether the POP button is used during gameplay
    var showsPOPButton: Bool {
        self == .classic || self == .daily
    }

    /// Whether to show the high score board
    var showsScoreboard: Bool {
        self == .classic || self == .daily
    }

    /// Whether to show lives indicator (hearts)
    var showsLives: Bool {
        switch self {
        case .zoomy, .seeky, .tappy: return true
        default: return false
        }
    }

    /// Whether this mode has Game Center leaderboards
    var hasGameCenter: Bool {
        switch self {
        case .classic, .daily, .boppy, .tappy, .seeky, .zoomy: return true
        case .matchy, .copy: return false
        }
    }

    /// Whether to show the timer during gameplay
    var showsTimer: Bool {
        switch self {
        case .classic, .daily, .boppy, .seeky: return true
        case .matchy, .copy, .zoomy, .tappy: return false
        }
    }

    /// Available time durations for this mode
    var availableDurations: [Int] {
        switch self {
        case .classic: return [10, 20, 30, 40, 50, 60]
        case .boppy: return [20, 30, 40]
        default: return []
        }
    }

    /// Default duration for modes with time selection
    var defaultDuration: Int {
        switch self {
        case .classic: return 30
        case .boppy: return 30
        default: return 0
        }
    }

    /// Score label for this mode
    var scoreLabel: String {
        switch self {
        case .classic, .daily, .boppy, .zoomy: return "Score"
        case .matchy: return "Pairs"
        case .copy, .seeky, .tappy: return "Round"
        }
    }

    /// How many lives this mode starts with (0 = no lives system)
    var startingLives: Int {
        switch self {
        case .zoomy, .seeky, .tappy: return 3
        default: return 0
        }
    }
}

// MARK: - UserDefaults persistence

extension GameMode {
    private static let selectedModeKey = "poppy.selectedMode"

    /// Load the last selected mode from UserDefaults
    static func loadSelected() -> GameMode {
        guard let raw = UserDefaults.standard.string(forKey: selectedModeKey),
              let mode = GameMode(rawValue: raw) else {
            return .classic
        }
        return mode
    }

    /// Save the selected mode to UserDefaults
    func save() {
        UserDefaults.standard.set(self.rawValue, forKey: GameMode.selectedModeKey)
    }
}

// MARK: - Mode grouping for UI

extension GameMode {
    /// Free modes (top row in picker)
    static var freeModes: [GameMode] {
        [.classic, .daily, .matchy, .copy, .boppy]
    }

    /// Poppy Plus modes (bottom row in picker)
    static var plusModes: [GameMode] {
        [.zoomy, .tappy, .seeky]
    }
}

// MARK: - Copy Mode Difficulty

enum CopyDifficulty: String, CaseIterable, Codable {
    case classic   // 4 large colored dots (like Simon)
    case challenge // 10 dots (Poppy style)

    var displayName: String {
        switch self {
        case .classic: return "Classic"
        case .challenge: return "Challenge"
        }
    }

    var dotCount: Int {
        switch self {
        case .classic: return 4
        case .challenge: return 10
        }
    }

    // UserDefaults persistence
    private static let key = "poppy.copy.difficulty"

    static func load() -> CopyDifficulty {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let difficulty = CopyDifficulty(rawValue: raw) else {
            return .classic
        }
        return difficulty
    }

    func save() {
        UserDefaults.standard.set(self.rawValue, forKey: CopyDifficulty.key)
    }
}
