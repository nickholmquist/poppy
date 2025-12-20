//
//  MatchyUI.swift
//  Poppy
//
//  UI components for Matchy mode: overlay-style settings pickers and score display
//

import SwiftUI

// MARK: - Grid Size Enum

/// Grid size options for Matchy mode
enum MatchyGridSize: Int, CaseIterable {
    case small = 10   // 5 pairs
    case medium = 16  // 8 pairs
    case large = 20   // 10 pairs

    var dotCount: Int { rawValue }
    var pairCount: Int { rawValue / 2 }

    var label: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        }
    }

    var fullLabel: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var description: String {
        switch self {
        case .small: return "5 pairs"
        case .medium: return "8 pairs"
        case .large: return "10 pairs"
        }
    }
}

// MARK: - Pill Button (3D tappable style - matches ClassicPillButton)

/// A 3D pill button that triggers an overlay picker
struct MatchyPillButton<Content: View>: View {
    let theme: Theme
    let layout: LayoutController
    let isDisabled: Bool
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var isPressed = false

    private var height: CGFloat { layout.unit * 12 }  // Match Classic pills (~96pt)
    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }
    private var layerOffset: CGFloat { layout.unit * 1.2 }  // Match Classic layerOffset

    var body: some View {
        Button(action: {
            if !isDisabled {
                SoundManager.shared.play(.pop)
                HapticsManager.shared.light()
                onTap()
            }
        }) {
            ZStack {
                // Bottom layer (shadow/depth)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color.black.opacity(0.35))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )

                // Top layer (main button)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )
                    .offset(y: isPressed ? 0 : -layerOffset)

                // Content
                content()
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent)
                    .offset(y: isPressed ? 0 : -layerOffset)
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .opacity(isDisabled ? 0.5 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDisabled && !isPressed {
                        withAnimation(.easeOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Players Overlay Picker

/// Overlay picker for selecting number of players (2x2 grid)
struct MatchyPlayersOverlay: View {
    let theme: Theme
    let layout: LayoutController
    @Binding var show: Bool
    @Binding var playerCount: Int
    let buttonFrame: CGRect

    @State private var phase: AnimationPhase = .collapsed
    @State private var showContent = false
    @State private var localCount: Int = 1

    enum AnimationPhase {
        case collapsed
        case expanding
        case expanded
    }

    private var collapsedWidth: CGFloat { buttonFrame.width }
    private var collapsedHeight: CGFloat { buttonFrame.height }
    private let expandedHeight: CGFloat = 240

    private var currentWidth: CGFloat {
        collapsedWidth  // Always match button width
    }

    private var currentHeight: CGFloat {
        phase == .expanded ? expandedHeight : collapsedHeight
    }

    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }

    // Account for 3D button's layer offset (top layer is shifted up)
    private var layerOffset: CGFloat { layout.unit * 1.2 }  // Match pill layerOffset

    private var currentY: CGFloat {
        switch phase {
        case .collapsed:
            return buttonFrame.midY - layerOffset
        case .expanding, .expanded:
            // Start from button top and expand downward
            return buttonFrame.minY - layerOffset + currentHeight / 2
        }
    }

    private var dimOpacity: Double {
        phase == .expanded ? 0.4 : 0
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black
                .opacity(dimOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissPicker() }
                .animation(.easeOut(duration: 0.2), value: phase)

            // The morphing picker
            ZStack {
                // Background - consistent corner radius with stroke
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )
                    .shadow(
                        color: phase == .expanded ? Color.black.opacity(0.25) : .clear,
                        radius: phase == .expanded ? 15 : 0,
                        y: phase == .expanded ? 8 : 0
                    )

                // Content - no opacity transitions to avoid artifacts
                if phase == .expanded {
                    VStack(spacing: 10) {
                        // Vertical stack of player options
                        ForEach(1...4, id: \.self) { count in
                            playerOption(count)
                        }
                    }
                    .padding(14)
                } else {
                    // Collapsed content - matches pill styling
                    VStack(spacing: PillStyle.contentSpacing) {
                        Text("Players")
                            .font(.system(size: PillStyle.labelSize, weight: .semibold, design: .rounded))
                        HStack(spacing: 6) {
                            ForEach(0..<localCount, id: \.self) { _ in
                                Image(systemName: "person.fill")
                                    .font(.system(size: 22, weight: .bold))
                            }
                        }
                    }
                    .foregroundStyle(theme.textOnAccent)
                }
            }
            .frame(width: currentWidth, height: currentHeight)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .position(x: buttonFrame.midX, y: currentY)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: phase)
        }
        .ignoresSafeArea()
        .onAppear {
            localCount = playerCount
            expandPicker()
        }
    }

    private func playerOption(_ count: Int) -> some View {
        let isSelected = localCount == count
        return Button(action: {
            SoundManager.shared.play(.pop)
            HapticsManager.shared.light()
            // Update selection with animation
            withAnimation(.easeOut(duration: 0.15)) {
                localCount = count
            }
            // Brief pause to show selection, then close
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                confirmSelection()
            }
        }) {
            HStack {
                // Player icons in a row
                HStack(spacing: 4) {
                    ForEach(0..<count, id: \.self) { _ in
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .bold))
                    }
                }

                Spacer()

                // Player label
                Text(count == 1 ? "Solo" : "\(count)P")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .fixedSize()
            }
            .foregroundStyle(isSelected ? theme.accent : theme.textOnAccent.opacity(0.9))
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? theme.textOnAccent : theme.textOnAccent.opacity(0.15))
            )
            .animation(.easeOut(duration: 0.15), value: localCount)
        }
        .buttonStyle(.plain)
    }

    private func expandPicker() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            phase = .expanding
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                phase = .expanded
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.15)) {
                    showContent = true
                }
            }
        }
    }

    private func confirmSelection() {
        playerCount = localCount
        dismissPicker()
    }

    private func dismissPicker() {
        withAnimation(.easeOut(duration: 0.1)) {
            showContent = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = .expanding
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.15)) {
                phase = .collapsed
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            show = false
        }
    }
}

// MARK: - Grid Size Overlay Picker

/// Overlay picker for selecting grid size (stacked vertically)
struct MatchyGridOverlay: View {
    let theme: Theme
    let layout: LayoutController
    @Binding var show: Bool
    @Binding var gridSize: MatchyGridSize
    let buttonFrame: CGRect

    @State private var phase: AnimationPhase = .collapsed
    @State private var showContent = false
    @State private var localSize: MatchyGridSize = .small

    enum AnimationPhase {
        case collapsed
        case expanding
        case expanded
    }

    private var collapsedWidth: CGFloat { buttonFrame.width }
    private var collapsedHeight: CGFloat { buttonFrame.height }
    private let expandedHeight: CGFloat = 190

    private var currentWidth: CGFloat {
        collapsedWidth  // Always match button width
    }

    private var currentHeight: CGFloat {
        phase == .expanded ? expandedHeight : collapsedHeight
    }

    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }

    // Account for 3D button's layer offset (top layer is shifted up)
    private var layerOffset: CGFloat { layout.unit * 1.2 }  // Match pill layerOffset

    private var currentY: CGFloat {
        switch phase {
        case .collapsed:
            return buttonFrame.midY - layerOffset
        case .expanding, .expanded:
            // Start from button top and expand downward
            return buttonFrame.minY - layerOffset + currentHeight / 2
        }
    }

    private var dimOpacity: Double {
        phase == .expanded ? 0.4 : 0
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black
                .opacity(dimOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismissPicker() }
                .animation(.easeOut(duration: 0.2), value: phase)

            // The morphing picker
            ZStack {
                // Background - consistent corner radius with stroke
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )
                    .shadow(
                        color: phase == .expanded ? Color.black.opacity(0.25) : .clear,
                        radius: phase == .expanded ? 15 : 0,
                        y: phase == .expanded ? 8 : 0
                    )

                // Content - no opacity transitions to avoid artifacts
                if phase == .expanded {
                    VStack(spacing: 10) {
                        ForEach(MatchyGridSize.allCases, id: \.self) { size in
                            gridOption(size)
                        }
                    }
                    .padding(14)
                } else {
                    // Collapsed content - matches pill styling
                    VStack(spacing: PillStyle.contentSpacing) {
                        Text("Grid Size")
                            .font(.system(size: PillStyle.labelSize, weight: .semibold, design: .rounded))
                        Text(localSize.fullLabel)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(theme.textOnAccent)
                }
            }
            .frame(width: currentWidth, height: currentHeight)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .position(x: buttonFrame.midX, y: currentY)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: phase)
        }
        .ignoresSafeArea()
        .onAppear {
            localSize = gridSize
            expandPicker()
        }
    }

    private func gridOption(_ size: MatchyGridSize) -> some View {
        let isSelected = localSize == size
        return Button(action: {
            SoundManager.shared.play(.pop)
            HapticsManager.shared.light()
            // Update selection with animation
            withAnimation(.easeOut(duration: 0.15)) {
                localSize = size
            }
            // Brief pause to show selection, then close
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                confirmSelection()
            }
        }) {
            VStack(spacing: 2) {
                Text(size.fullLabel)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(size.description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .opacity(0.7)
            }
            .foregroundStyle(isSelected ? theme.accent : theme.textOnAccent.opacity(0.9))
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? theme.textOnAccent : theme.textOnAccent.opacity(0.15))
            )
            .animation(.easeOut(duration: 0.15), value: localSize)
        }
        .buttonStyle(.plain)
    }

    private func expandPicker() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            phase = .expanding
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                phase = .expanded
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeOut(duration: 0.15)) {
                    showContent = true
                }
            }
        }
    }

    private func confirmSelection() {
        gridSize = localSize
        dismissPicker()
    }

    private func dismissPicker() {
        withAnimation(.easeOut(duration: 0.1)) {
            showContent = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = .expanding
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeInOut(duration: 0.15)) {
                phase = .collapsed
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            show = false
        }
    }
}

// MARK: - Matchy Header (Pills + Matches)

/// Combined header with settings pills and matches display
struct MatchyHeader: View {
    let theme: Theme
    let layout: LayoutController
    @Binding var playerCount: Int
    @Binding var gridSize: MatchyGridSize
    let playerScores: [Int]
    let currentPlayer: Int
    let isPlaying: Bool
    let flipsCount: Int  // Number of attempts/flips

    // Overlay state managed by parent for proper z-ordering
    @Binding var showPlayersOverlay: Bool
    @Binding var showGridOverlay: Bool
    @Binding var playersPillFrame: CGRect
    @Binding var gridPillFrame: CGRect

    private var totalMatches: Int {
        playerScores.reduce(0, +)
    }

    private var pairCount: Int {
        gridSize.pairCount
    }

    var body: some View {
        VStack(spacing: 12) {
            // Settings pills row (3D style matching Classic/Boppy)
            HStack(spacing: 12) {
                // Players pill
                MatchyPillButton(
                    theme: theme,
                    layout: layout,
                    isDisabled: isPlaying
                ) {
                    showPlayersOverlay = true
                } content: {
                    VStack(spacing: PillStyle.contentSpacing) {
                        Text("Players")
                            .font(.system(size: PillStyle.labelSize, weight: .semibold, design: .rounded))
                        HStack(spacing: 6) {
                            ForEach(0..<playerCount, id: \.self) { _ in
                                Image(systemName: "person.fill")
                                    .font(.system(size: 22, weight: .bold))
                            }
                        }
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            playersPillFrame = geo.frame(in: .global)
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            playersPillFrame = newFrame
                        }
                    }
                )

                // Grid size pill
                MatchyPillButton(
                    theme: theme,
                    layout: layout,
                    isDisabled: isPlaying
                ) {
                    showGridOverlay = true
                } content: {
                    VStack(spacing: PillStyle.contentSpacing) {
                        Text("Grid Size")
                            .font(.system(size: PillStyle.labelSize, weight: .semibold, design: .rounded))
                        Text(gridSize.fullLabel)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            gridPillFrame = geo.frame(in: .global)
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            gridPillFrame = newFrame
                        }
                    }
                )
            }

            // Matches container - uses theme colors for adaptability
            // Fixed height to prevent layout jump when switching player counts
            VStack(spacing: 6) {
                if playerCount == 1 {
                    // Single player - show matches and flips side by side
                    HStack(spacing: 24) {
                        // Matches
                        VStack(spacing: 2) {
                            Text("Matches")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.textDark.opacity(0.6))
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Text("\(totalMatches)")
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .foregroundStyle(theme.textDark)
                        }

                        // Flips
                        VStack(spacing: 2) {
                            Text("Flips")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.textDark.opacity(0.6))
                                .textCase(.uppercase)
                                .tracking(0.5)
                            Text("\(flipsCount)")
                                .font(.system(size: 42, weight: .heavy, design: .rounded))
                                .foregroundStyle(theme.textDark.opacity(0.9))
                        }
                    }
                } else {
                    // Multiplayer - show all scores
                    Text("Matches")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textDark.opacity(0.6))
                        .textCase(.uppercase)
                        .tracking(0.5)

                    HStack(spacing: 10) {
                        ForEach(0..<playerCount, id: \.self) { index in
                            PlayerScoreBadge(
                                theme: theme,
                                playerIndex: index,
                                score: index < playerScores.count ? playerScores[index] : 0,
                                isCurrentTurn: isPlaying && index == currentPlayer
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: layout.unit * 16)  // Match ClassicScoreContainer height (~128pt)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.textDark.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(theme.textDark.opacity(0.2), lineWidth: 2)
                    )
            )
        }
        .frame(width: layout.scoreboardExpandedWidth)
    }
}

// MARK: - Player Score Badge

/// Compact score badge for multiplayer - horizontal layout with player on left
private struct PlayerScoreBadge: View {
    let theme: Theme
    let playerIndex: Int
    let score: Int
    let isCurrentTurn: Bool

    private static let playerColors: [String] = [
        "#4A90D9", // Blue
        "#E85D75", // Red/Pink
        "#5DBB63", // Green
        "#F5A623"  // Orange
    ]

    private var playerColor: Color {
        Color(hex: Self.playerColors[playerIndex % Self.playerColors.count])
    }

    var body: some View {
        HStack(spacing: 8) {
            // Player indicator on left
            VStack(spacing: 0) {
                Image(systemName: "person.fill")
                    .font(.system(size: 13, weight: .bold))
                Text("\(playerIndex + 1)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isCurrentTurn ? playerColor : theme.textDark.opacity(0.5))

            // Score on right
            Text("\(score)")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundStyle(isCurrentTurn ? playerColor : theme.textDark.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isCurrentTurn ? playerColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isCurrentTurn ? playerColor.opacity(0.4) : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.2), value: isCurrentTurn)
    }
}

// MARK: - Matchy Score Display

/// Shows player scores during Matchy gameplay
struct MatchyScoreDisplay: View {
    let theme: Theme
    let layout: LayoutController
    let playerCount: Int
    let playerScores: [Int]
    let currentPlayer: Int
    let isPlaying: Bool

    var body: some View {
        VStack(spacing: 6) {
            // "Matches" label - bigger and bolder
            Text("Matches")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textDark.opacity(0.8))

            // Player scores
            if playerCount == 1 {
                // Single player - just show the number
                Text("\(playerScores.first ?? 0)")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.textDark)
            } else {
                // Multiplayer - show all player scores
                HStack(spacing: 16) {
                    ForEach(0..<playerCount, id: \.self) { playerIndex in
                        PlayerScoreColumn(
                            theme: theme,
                            playerIndex: playerIndex,
                            score: playerIndex < playerScores.count ? playerScores[playerIndex] : 0,
                            isCurrentTurn: isPlaying && playerIndex == currentPlayer
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

/// Individual player score column
private struct PlayerScoreColumn: View {
    let theme: Theme
    let playerIndex: Int
    let score: Int
    let isCurrentTurn: Bool

    // Player colors for visual distinction
    private static let playerColors: [String] = [
        "#4A90D9", // Blue - Player 1
        "#E85D75", // Red/Pink - Player 2
        "#5DBB63", // Green - Player 3
        "#F5A623"  // Orange - Player 4
    ]

    private var playerColor: Color {
        let hex = Self.playerColors[playerIndex % Self.playerColors.count]
        return Color(hex: hex)
    }

    var body: some View {
        VStack(spacing: 2) {
            // Player indicator
            HStack(spacing: 2) {
                Image(systemName: "person.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("\(playerIndex + 1)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .foregroundStyle(isCurrentTurn ? playerColor : theme.textDark.opacity(0.5))

            // Score
            Text("\(score)")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(isCurrentTurn ? playerColor : theme.textDark.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isCurrentTurn ? playerColor.opacity(0.15) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isCurrentTurn ? playerColor.opacity(0.5) : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.3), value: isCurrentTurn)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: score)
    }
}

// MARK: - Turn Change Card

/// Overlay card that slides in to announce whose turn it is
struct MatchyTurnCard: View {
    let theme: Theme
    let currentPlayer: Int
    let onDismiss: () -> Void

    // How long the card stays visible before auto-dismissing
    private let displayDuration: Double = 1.5

    @State private var isShowing = false
    @State private var cardOffset: CGFloat = -400

    // Player colors (same as PlayerScoreBadge)
    private static let playerColors: [String] = [
        "#4A90D9", // Blue
        "#E85D75", // Red/Pink
        "#5DBB63", // Green
        "#F5A623"  // Orange
    ]

    private var playerColor: Color {
        Color(hex: Self.playerColors[currentPlayer % Self.playerColors.count])
    }

    var body: some View {
        ZStack {
            // Dimmed background (non-interactive)
            Color.black
                .opacity(isShowing ? 0.4 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // The turn card
            VStack(spacing: 16) {
                // Player icon
                Image(systemName: "person.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(playerColor)

                // Player number
                Text("Player \(currentPlayer + 1)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(playerColor)

                // "Your Turn" text
                Text("Your Turn!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.8))
            }
            .padding(.horizontal, 48)
            .padding(.vertical, 32)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.bgTop)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(playerColor.opacity(0.5), lineWidth: 2)
            )
            .offset(y: cardOffset)
        }
        .allowsHitTesting(false)  // Don't block touches
        .onAppear {
            // Slide in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                isShowing = true
                cardOffset = 0
            }

            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        // Slide out
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
            isShowing = false
            cardOffset = -400
        }

        // Call dismiss after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Winner Overlay (Multiplayer)

/// Overlay showing the winner(s) at the end of a multiplayer Matchy game
struct MatchyWinnerOverlay: View {
    let theme: Theme
    let playerScores: [Int]
    let onDismiss: () -> Void

    // Player colors (same as elsewhere)
    private static let playerColors: [String] = [
        "#4A90D9", // Blue
        "#E85D75", // Red/Pink
        "#5DBB63", // Green
        "#F5A623"  // Orange
    ]

    // Find winner(s) - could be a tie
    private var winners: [Int] {
        let maxScore = playerScores.max() ?? 0
        return playerScores.indices.filter { playerScores[$0] == maxScore }
    }

    private var isTie: Bool {
        winners.count > 1
    }

    private var winnerColor: Color {
        if isTie {
            return theme.accent  // Use theme accent for ties
        }
        return Color(hex: Self.playerColors[winners.first! % Self.playerColors.count])
    }

    var body: some View {
        ZStack {
            // Background
            theme.accent.opacity(0.95).ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Trophy icon
                Image(systemName: "trophy.fill")
                    .font(.system(size: 72, weight: .bold))
                    .foregroundStyle(Color(hex: "#FFD700"))  // Gold
                    .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 16)

                // Winner announcement
                if isTie {
                    Text("It's a Tie!")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                    // List tied players
                    HStack(spacing: 16) {
                        ForEach(winners, id: \.self) { playerIndex in
                            playerBadge(playerIndex)
                        }
                    }
                } else {
                    Text("Player \(winners.first! + 1)")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                    Text("Wins!")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                }

                // Show all scores
                scoresSection
                    .padding(.top, 16)

                Spacer()

                // OK button
                ThemedButton(
                    title: "OK",
                    action: onDismiss,
                    prominent: false,
                    theme: theme,
                    fill: theme.textOnAccent,
                    textColor: .white,
                    height: 90,
                    corner: 20,
                    font: .system(size: 35, weight: .black, design: .rounded)
                )
                .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
                .frame(maxWidth: 300)
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 28)
        }
        .transition(.opacity)
    }

    private func playerBadge(_ index: Int) -> some View {
        let color = Color(hex: Self.playerColors[index % Self.playerColors.count])
        return VStack(spacing: 4) {
            Image(systemName: "person.fill")
                .font(.system(size: 28, weight: .bold))
            Text("P\(index + 1)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.textOnAccent.opacity(0.2))
        )
    }

    private var scoresSection: some View {
        VStack(spacing: 8) {
            Text("Final Scores")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textOnAccent.opacity(0.7))
                .textCase(.uppercase)
                .tracking(1)

            HStack(spacing: 20) {
                ForEach(playerScores.indices, id: \.self) { index in
                    VStack(spacing: 2) {
                        Text("P\(index + 1)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: Self.playerColors[index % Self.playerColors.count]))
                        Text("\(playerScores[index])")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(theme.textOnAccent)
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.textOnAccent.opacity(0.1))
        )
    }
}

// MARK: - Previews

#Preview("Matchy Header - 1 Player") {
    @Previewable @State var players = 1
    @Previewable @State var grid: MatchyGridSize = .small
    @Previewable @State var showPlayers = false
    @Previewable @State var showGrid = false
    @Previewable @State var playersFrame: CGRect = .zero
    @Previewable @State var gridFrame: CGRect = .zero

    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        MatchyHeader(
            theme: .daylight,
            layout: .preview,
            playerCount: $players,
            gridSize: $grid,
            playerScores: [3],
            currentPlayer: 0,
            isPlaying: false,
            flipsCount: 7,
            showPlayersOverlay: $showPlayers,
            showGridOverlay: $showGrid,
            playersPillFrame: $playersFrame,
            gridPillFrame: $gridFrame
        )
        .padding()

        if showPlayers {
            MatchyPlayersOverlay(
                theme: .daylight,
                layout: .preview,
                show: $showPlayers,
                playerCount: $players,
                buttonFrame: playersFrame
            )
        }

        if showGrid {
            MatchyGridOverlay(
                theme: .daylight,
                layout: .preview,
                show: $showGrid,
                gridSize: $grid,
                buttonFrame: gridFrame
            )
        }
    }
}

#Preview("Matchy Header - 4 Players") {
    @Previewable @State var players = 4
    @Previewable @State var grid: MatchyGridSize = .large
    @Previewable @State var showPlayers = false
    @Previewable @State var showGrid = false
    @Previewable @State var playersFrame: CGRect = .zero
    @Previewable @State var gridFrame: CGRect = .zero

    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        MatchyHeader(
            theme: .daylight,
            layout: .preview,
            playerCount: $players,
            gridSize: $grid,
            playerScores: [2, 1, 0, 2],
            currentPlayer: 2,
            isPlaying: true,
            flipsCount: 12,
            showPlayersOverlay: $showPlayers,
            showGridOverlay: $showGrid,
            playersPillFrame: $playersFrame,
            gridPillFrame: $gridFrame
        )
        .padding()

        if showPlayers {
            MatchyPlayersOverlay(
                theme: .daylight,
                layout: .preview,
                show: $showPlayers,
                playerCount: $players,
                buttonFrame: playersFrame
            )
        }

        if showGrid {
            MatchyGridOverlay(
                theme: .daylight,
                layout: .preview,
                show: $showGrid,
                gridSize: $grid,
                buttonFrame: gridFrame
            )
        }
    }
}
