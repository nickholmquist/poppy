//
//  GameModeLayout.swift
//  Poppy
//
//  Centralized layout configuration for each game mode.
//  Eliminates scattered conditionals in ContentView.
//

import SwiftUI

// MARK: - Layout Enums

/// How the header/scoreboard behaves
enum HeaderStyle {
    case collapsibleScoreboard  // Classic, Boppy - expandable 3D card with multiple scores
    case fixedCard              // Zoomy, Tappy, Seeky - simple fixed high score card
    case dailyCard              // Daily - special card with date, streak, status
    case customInline           // Matchy, Copy - custom header with settings inline
}

/// Where lives (hearts) are displayed
enum LivesPlacement {
    case none                   // No lives system
    case inHeader               // Part of the header (Tappy, Seeky)
    case aboveBoard             // Above the board container (Zoomy)
}

/// Type of timer display
enum TimerStyle {
    case morphing               // MorphingTimerDisplay - Classic, Daily, Boppy, Seeky
    case solidBar               // TappyTimerBar - Tappy
    case none                   // No timer - Matchy, Copy, Zoomy
}

// MARK: - Game Mode Layout Configuration

/// Centralized layout configuration for each game mode.
/// Use this instead of scattered `if gameMode == .x` conditionals.
struct GameModeLayoutConfig {
    let mode: GameMode

    // MARK: - Header Configuration

    var headerStyle: HeaderStyle {
        switch mode {
        case .classic, .boppy:
            return .collapsibleScoreboard
        case .daily:
            return .dailyCard
        case .matchy, .copy:
            return .customInline
        case .zoomy, .tappy, .seeky:
            return .fixedCard
        }
    }

    /// Whether the stats section (Score/Time labels) should be shown
    var showsStatsSection: Bool {
        switch mode {
        case .classic, .daily, .boppy, .seeky, .tappy, .copy:
            return true
        case .matchy, .zoomy:
            return false
        }
    }

    // MARK: - Timer Configuration

    var timerStyle: TimerStyle {
        switch mode {
        case .classic, .daily, .boppy, .seeky, .tappy:
            return .morphing  // Tappy now uses integrated container like Seeky
        case .matchy, .copy, .zoomy:
            return .none
        }
    }

    // MARK: - Lives Configuration

    var livesPlacement: LivesPlacement {
        switch mode {
        case .zoomy:
            return .aboveBoard
        case .tappy, .seeky:
            return .inHeader
        default:
            return .none
        }
    }

    var startingLives: Int {
        mode.startingLives
    }

    // MARK: - Spacing Configuration

    /// Spacing from top bar to first content element (40pt)
    func topBarToContentSpacing(_ layout: LayoutController) -> CGFloat {
        layout.unit * 5  // 40pt - more breathing room from top bar
    }

    /// Standard vertical spacing between content sections (16pt)
    /// All 3D elements now have proper frame bounds, so spacing is consistent
    func sectionSpacing(_ layout: LayoutController) -> CGFloat {
        layout.spacingNormal  // 16pt - uniform for all modes
    }

    /// Spacing from headers to stats containers (16pt)
    func headerToStatsSpacing(_ layout: LayoutController) -> CGFloat {
        layout.spacingNormal  // 16pt - matches section spacing
    }

    /// Spacing from stats/lives to the dot board
    /// Matches the dots-to-start-button distance for visual consistency
    func statsToBoardSpacing(_ layout: LayoutController) -> CGFloat {
        layout.boardBottomPadding  // Same as dots to start button
    }

    /// Whether to use a flexible spacer (Spacer()) vs fixed
    var usesFlexibleSpacer: Bool {
        switch mode {
        case .zoomy:
            return false
        default:
            return true  // Classic, Boppy, Daily, Copy, Seeky, Tappy, Matchy use flexible spacer
        }
    }

    /// Whether stats should be placed near the board (Gestalt proximity)
    /// When true, the flexible spacer comes BEFORE stats, pushing stats toward the board
    var statsNearBoard: Bool {
        switch mode {
        case .classic, .boppy, .tappy, .seeky, .copy:
            return true  // Score/time displays relate to gameplay, not header
        default:
            return false
        }
    }

    // MARK: - Board Configuration

    /// Whether the board uses inline rendering (Zoomy) vs standard boardSection
    var usesInlineBoard: Bool {
        mode == .zoomy
    }

    /// Whether the mode has custom board rendering (Copy with Simon, Seeky with lives)
    var hasCustomBoardLayout: Bool {
        switch mode {
        case .copy, .seeky:
            return true
        default:
            return false
        }
    }

    // MARK: - Settings Configuration

    /// Whether this mode has settings that appear in the mode picker
    var hasPickerSettings: Bool {
        switch mode {
        case .classic, .boppy:
            return true  // Duration picker
        case .matchy:
            return true  // Players, grid size (moving to picker)
        case .copy:
            return true  // Difficulty (moving to picker)
        default:
            return false
        }
    }

    // MARK: - Score Display

    /// What metric to display as the primary score
    var scoreLabel: String {
        mode.scoreLabel
    }

    /// Whether this mode tracks scores by duration
    var hasDurationBasedScores: Bool {
        switch mode {
        case .classic, .boppy:
            return true
        default:
            return false
        }
    }
}

// MARK: - Convenience Extension

extension GameMode {
    /// Get the layout configuration for this mode
    var layoutConfig: GameModeLayoutConfig {
        GameModeLayoutConfig(mode: self)
    }
}
