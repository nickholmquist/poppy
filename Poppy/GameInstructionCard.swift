//
//  GameInstructionCard.swift
//  Poppy
//
//  First-time instruction card shown when a user visits a game mode for the first time.
//  Can also be re-opened via the info button in the top bar.
//  For locked premium modes, shows unlock options instead of "Got it!"
//

import SwiftUI

// MARK: - Instruction Card

struct GameInstructionCard: View {
    let theme: Theme
    let layout: LayoutController
    let gameMode: GameMode
    let isLocked: Bool
    let onDismiss: () -> Void
    let onUnlock: (() -> Void)?

    init(
        theme: Theme,
        layout: LayoutController,
        gameMode: GameMode,
        isLocked: Bool = false,
        onDismiss: @escaping () -> Void,
        onUnlock: (() -> Void)? = nil
    ) {
        self.theme = theme
        self.layout = layout
        self.gameMode = gameMode
        self.isLocked = isLocked
        self.onDismiss = onDismiss
        self.onUnlock = onUnlock
    }

    private var cardWidth: CGFloat {
        min(layout.scoreboardExpandedWidth + 40, 340)
    }

    private var cornerRadius: CGFloat { 24 }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black
                .opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissCard()
                }

            // Card
            VStack(spacing: 20) {
                // Header with icon and title
                VStack(spacing: 12) {
                    // Mode icon with lock badge for premium
                    ZStack(alignment: .bottomTrailing) {
                        Image(systemName: gameMode.icon)
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(theme.accent)

                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(6)
                                .background(Circle().fill(theme.textDark.opacity(0.7)))
                                .offset(x: 8, y: 4)
                        }
                    }

                    // Mode name
                    Text(gameMode.displayName)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.textDark)

                    // Premium badge
                    if isLocked {
                        Text("POPPY PLUS")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(theme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(theme.accent.opacity(0.15))
                            )
                    }
                }

                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(gameMode.instructions, id: \.self) { instruction in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(theme.accent)
                                .frame(width: 8, height: 8)
                                .offset(y: 6)

                            Text(instruction)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.textDark.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)

                // Goal
                if let goal = gameMode.goal {
                    Text(goal)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textDark.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }

                // Tips (only for Classic mode to help new users discover UI)
                if let tips = gameMode.tips, !isLocked {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tips")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textDark.opacity(0.5))

                        ForEach(tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textDark.opacity(0.5))

                                Text(tip)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(theme.textDark.opacity(0.6))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                }

                // Action buttons
                if isLocked {
                    // Unlock button for locked modes
                    VStack(spacing: 12) {
                        Button(action: {
                            SoundManager.shared.play(.pop)
                            HapticsManager.shared.medium()
                            onDismiss()
                            onUnlock?()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.open.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Unlock to Play")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(theme.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(theme.accent)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: dismissCard) {
                            Text("Maybe Later")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(theme.textDark.opacity(0.5))
                        }
                    }
                } else {
                    // Got it button for unlocked modes
                    Button(action: dismissCard) {
                        Text("Got it!")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(theme.accent)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.black.opacity(0.1), lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .frame(width: cardWidth)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.bgTop)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(theme.textDark.opacity(0.15), lineWidth: 2)
            )
        }
        .transition(.opacity)
    }

    private func dismissCard() {
        SoundManager.shared.play(.pop)
        HapticsManager.shared.light()
        onDismiss()
    }
}

// MARK: - GameMode Instructions Extension

extension GameMode {
    /// Step-by-step instructions for each game mode
    var instructions: [String] {
        switch self {
        case .classic:
            return [
                "Tap the highlighted dots as fast as you can",
                "Once all 10 are down, hit POP to reset them",
                "Keep going until time runs out!",
                "Tap the wrong dot and it's game over"
            ]
        case .daily:
            return [
                "Same as Poppy, but you only get one chance per day",
                "Time limit changes daily (10-60 seconds)",
                "Build your streak by playing every day!"
            ]
        case .matchy:
            return [
                "Tap two dots to flip them over",
                "Find all matching pairs to win",
                "In multiplayer, take turns finding matches"
            ]
        case .copy:
            return [
                "Watch the sequence of dots light up",
                "Tap the dots in the same order",
                "Each round adds one more to remember!"
            ]
        case .boppy:
            return [
                "Dots pop up randomly like whack-a-mole",
                "Tap them before they disappear!",
                "Keep tapping until time runs out",
                "Wrong taps won't end the game"
            ]
        case .zoomy:
            return [
                "Dots drift across the screen",
                "Tap them before they escape!",
                "Let one escape and you lose a heart",
                "Lose all 3 hearts and it's game over"
            ]
        case .tappy:
            return [
                "Tap the highlighted dot before time runs out",
                "Each round gets faster!",
                "Survive all 10 rounds to win"
            ]
        case .seeky:
            return [
                "One dot is slightly different from the rest",
                "You have 5 seconds to find and tap it",
                "Wrong tap or time runs out = lose a heart",
                "Lose all 3 hearts and it's game over"
            ]
        }
    }

    /// Optional goal text shown at bottom of card
    var goal: String? {
        switch self {
        case .classic:
            return "Goal: Get the highest score!"
        case .daily:
            return "Goal: Get the highest score with today's unique time!"
        case .matchy:
            return "Solo: Match with the fewest taps!\nMultiplayer: Get the most matches to win!"
        case .copy:
            return "Goal: See how far you can go!"
        case .boppy:
            return "Goal: Score as many as you can!"
        case .zoomy:
            return "Goal: Don't let any escape!"
        case .tappy:
            return "Goal: Survive all 10 rounds!"
        case .seeky:
            return "Goal: Find the odd dot each round!"
        }
    }

    /// Tips shown below instructions (only for Classic to help new users discover UI)
    var tips: [String]? {
        switch self {
        case .classic:
            return [
                "Tap the top-left dot to change themes",
                "Long-press it to see all themes",
                "Tap the top-right dot for settings"
            ]
        default:
            return nil
        }
    }
}

// MARK: - First Visit Tracking

struct InstructionTracker {
    private static let keyPrefix = "poppy.hasSeenInstructions."

    /// Check if the user has seen instructions for a mode
    static func hasSeenInstructions(for mode: GameMode) -> Bool {
        UserDefaults.standard.bool(forKey: keyPrefix + mode.rawValue)
    }

    /// Mark instructions as seen for a mode
    static func markInstructionsSeen(for mode: GameMode) {
        UserDefaults.standard.set(true, forKey: keyPrefix + mode.rawValue)
    }

    /// Reset instruction state for a mode (for testing)
    static func resetInstructions(for mode: GameMode) {
        UserDefaults.standard.removeObject(forKey: keyPrefix + mode.rawValue)
    }

    /// Reset all instruction states (for testing)
    static func resetAllInstructions() {
        for mode in GameMode.allCases {
            resetInstructions(for: mode)
        }
    }
}

// MARK: - Preview

#Preview("Poppy Instructions") {
    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        GameInstructionCard(
            theme: .daylight,
            layout: .preview,
            gameMode: .classic,
            onDismiss: {}
        )
    }
}

#Preview("Matchy Instructions") {
    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        GameInstructionCard(
            theme: .daylight,
            layout: .preview,
            gameMode: .matchy,
            onDismiss: {}
        )
    }
}

#Preview("Seeky Instructions") {
    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        GameInstructionCard(
            theme: .daylight,
            layout: .preview,
            gameMode: .seeky,
            onDismiss: {}
        )
    }
}

#Preview("Zoomy Locked") {
    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        GameInstructionCard(
            theme: .daylight,
            layout: .preview,
            gameMode: .zoomy,
            isLocked: true,
            onDismiss: {},
            onUnlock: {}
        )
    }
}
