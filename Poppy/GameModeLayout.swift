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
        case .classic, .daily, .boppy, .seeky:
            return true
        case .matchy, .copy, .zoomy, .tappy:
            return false  // Tappy shows stats above board instead
        }
    }

    // MARK: - Timer Configuration

    var timerStyle: TimerStyle {
        switch mode {
        case .classic, .daily, .boppy, .seeky:
            return .morphing
        case .tappy:
            return .solidBar
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

    /// Padding between settings section and stats/board
    func statsTopPadding(_ layout: LayoutController) -> CGFloat {
        guard showsStatsSection else { return 0 }
        switch mode {
        case .classic, .boppy, .daily:
            return layout.unit * 2  // Tight spacing - header sits just above score container
        default:
            return layout.statsTopPadding
        }
    }

    /// Spacer height between header/stats and board
    func boardSpacerHeight(_ layout: LayoutController) -> CGFloat {
        switch mode {
        case .zoomy:
            return 0  // No spacer - content flows directly
        case .matchy:
            return layout.spacingLoose  // Match Classic/Boppy spacing
        case .tappy:
            return layout.spacingLoose  // 24pt
        case .classic, .boppy, .seeky:
            return layout.spacingLoose  // minLength for flexible spacer
        default:
            return 0  // Flexible spacer handles this
        }
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
