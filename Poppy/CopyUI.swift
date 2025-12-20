//
//  CopyUI.swift
//  Poppy
//
//  Copy mode specific UI components
//  - Difficulty selector (Classic 4-dot / Challenge 10-dot)
//  - Watch/Your Turn status indicator
//  - 4-dot Simon-style board
//

import SwiftUI

// MARK: - Copy Header (replaces scoreboard for Copy mode)

struct CopyHeader: View {
    let theme: Theme
    let layout: LayoutController
    @Binding var difficulty: CopyDifficulty
    let classicBest: Int
    let challengeBest: Int
    let currentRound: Int
    let isShowingSequence: Bool
    let isPlaying: Bool      // Actually in gameplay (for status text)
    let isRunning: Bool      // Disable toggle (includes transitions)

    // Status text based on game state
    private var statusText: String {
        if isPlaying {
            return isShowingSequence ? "Watch..." : "Your turn!"
        } else {
            return "Are you ready?"
        }
    }

    // Status text color
    private var statusColor: Color {
        if isPlaying && isShowingSequence {
            return theme.accent
        }
        return theme.textDark
    }

    var body: some View {
        VStack(spacing: layout.unit * 2.5) {
            // Best round card (now first)
            CopyBestCard(
                theme: theme,
                layout: layout,
                classicBest: classicBest,
                challengeBest: challengeBest
            )

            // Difficulty rocker toggle - always visible, disabled during gameplay (now second)
            CopyDifficultyRocker(
                theme: theme,
                layout: layout,
                difficulty: $difficulty
            )
            .allowsHitTesting(!isRunning)
            .padding(.top, layout.unit * 2)  // Move toggle down by 2 units

            // Status display - always visible
            VStack(spacing: 12) {
                // Round indicator - always visible
                HStack(spacing: 8) {
                    Text("Round")
                        .font(.system(size: layout.baseText * 1.5, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textDark)
                    Text("\(currentRound)")
                        .font(.system(size: layout.baseText * 1.5, weight: .black, design: .rounded))
                        .foregroundStyle(theme.textDark)
                }

                // Status text - always visible
                Text(statusText)
                    .font(.system(size: layout.baseText * 2, weight: .heavy, design: .rounded))
                    .foregroundStyle(statusColor)
                    .animation(.easeOut(duration: 0.15), value: statusText)
            }
            .padding(.top, layout.unit * 1)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeOut(duration: 0.2), value: isRunning)
    }
}

// MARK: - Difficulty Toggle (Split Button Style - Both Popped)

struct CopyDifficultyRocker: View {
    let theme: Theme
    let layout: LayoutController
    @Binding var difficulty: CopyDifficulty

    // Match the scoreboard width
    private var totalWidth: CGFloat { layout.scoreboardExpandedWidth }
    private var buttonHeight: CGFloat { layout.unit * 7 }  // Taller for more square shape
    private var cornerRadius: CGFloat { layout.unit * 2 }  // Rounded corners
    private var layerOffset: CGFloat { layout.unit * 0.8 }
    private var strokeWidth: CGFloat { 2.0 }

    var body: some View {
        HStack(spacing: 0) {
            // Classic (left half)
            DifficultyHalfButton(
                label: "Classic",
                isLeftHalf: true,
                isSelected: difficulty == .classic,
                cornerRadius: cornerRadius,
                strokeWidth: strokeWidth,
                layerOffset: layerOffset,
                height: buttonHeight,
                theme: theme,
                layout: layout
            ) {
                guard difficulty != .classic else { return }
                HapticsManager.shared.light()
                SoundManager.shared.play(.pop)
                difficulty = .classic
                CopyDifficulty.classic.save()
            }

            // Challenge (right half)
            DifficultyHalfButton(
                label: "Challenge",
                isLeftHalf: false,
                isSelected: difficulty == .challenge,
                cornerRadius: cornerRadius,
                strokeWidth: strokeWidth,
                layerOffset: layerOffset,
                height: buttonHeight,
                theme: theme,
                layout: layout
            ) {
                guard difficulty != .challenge else { return }
                HapticsManager.shared.light()
                SoundManager.shared.play(.pop)
                difficulty = .challenge
                CopyDifficulty.challenge.save()
            }
        }
        .frame(width: totalWidth, height: buttonHeight + layerOffset)
    }
}

// MARK: - Difficulty Half Button (Both Always Popped Up)

private struct DifficultyHalfButton: View {
    let label: String
    let isLeftHalf: Bool
    let isSelected: Bool
    let cornerRadius: CGFloat
    let strokeWidth: CGFloat
    let layerOffset: CGFloat
    let height: CGFloat
    let theme: Theme
    let layout: LayoutController
    let action: () -> Void

    @State private var isPressed = false

    // Both are always popped up, press animation only when tapping
    private var currentOffset: CGFloat {
        isPressed ? 0 : -layerOffset
    }

    // Selected = accent, Unselected = grey
    private var fillColor: Color {
        isSelected ? theme.accent : Color(hex: "#c0c0c0")
    }

    // Depth layer should be darker than surface
    private var depthColor: Color {
        isSelected ? Color(hex: "#8B5A5B") : Color(hex: "#909090")  // Darker versions
    }

    // For the depth layer, we overlay black to darken
    private var depthOverlay: some View {
        Group {
            if isSelected {
                theme.accent.overlay(Color.black.opacity(0.35))
            } else {
                Color(hex: "#909090")
            }
        }
    }

    private var textColor: Color {
        isSelected ? theme.textOnAccent : Color(hex: "#3a3a3a")
    }

    var body: some View {
        ZStack {
            // Bottom depth layer (stays in place)
            depthLayer

            // Top surface layer (moves down when pressed)
            surfaceLayer
                .offset(y: currentOffset)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        HapticsManager.shared.light()
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        SoundManager.shared.play(.pop)
                        action()
                    }
                }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }

    @ViewBuilder
    private var depthLayer: some View {
        if isLeftHalf {
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(isSelected ? theme.accent : Color(hex: "#909090"))

                // Darken overlay
                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(Color.black.opacity(0.35))

                // Stroke
                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: strokeWidth)
            }
            .frame(height: height)
        } else {
            ZStack {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: cornerRadius
                )
                .fill(isSelected ? theme.accent : Color(hex: "#909090"))

                // Darken overlay
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: cornerRadius
                )
                .fill(Color.black.opacity(0.35))

                // Stroke
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: cornerRadius
                )
                .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: strokeWidth)
            }
            .frame(height: height)
        }
    }

    @ViewBuilder
    private var surfaceLayer: some View {
        ZStack {
            if isLeftHalf {
                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(fillColor)

                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: strokeWidth)

                // Center divider line on right edge
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(hex: "#3a3a3a"))
                        .frame(width: strokeWidth)
                }
            } else {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: cornerRadius
                )
                .fill(fillColor)

                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: cornerRadius
                )
                .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: strokeWidth)
            }

            // Label
            Text(label)
                .font(.system(size: layout.baseText, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
        }
        .frame(height: height)
    }
}

// MARK: - Best Round Card

struct CopyBestCard: View {
    let theme: Theme
    let layout: LayoutController
    let classicBest: Int
    let challengeBest: Int

    private var cardWidth: CGFloat {
        layout.scoreboardExpandedWidth
    }

    private var cardHeight: CGFloat {
        layout.unit * 16  // Taller to fit both scores
    }

    var body: some View {
        ZStack {
            // Card background - use accent color directly
            RoundedRectangle(cornerRadius: layout.scoreboardCornerRadius, style: .continuous)
                .fill(theme.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: layout.scoreboardCornerRadius, style: .continuous)
                        .stroke(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(width: cardWidth, height: cardHeight)

            // Content
            VStack(spacing: 8) {
                // Header - matches scoreboardTitleSize
                Text("High Scores")
                    .font(.system(size: layout.scoreboardTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent)
                    .padding(.bottom, 4)

                // Two scores side by side
                HStack(spacing: 0) {
                    // Classic (left)
                    VStack(spacing: 0) {
                        Text("Classic")
                            .font(.system(size: layout.baseText * 0.85, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent.opacity(0.85))
                        Text("\(classicBest)")
                            .font(.system(size: layout.baseText * 2, weight: .black, design: .rounded))
                            .foregroundStyle(theme.textOnAccent)
                        Text(classicBest == 1 ? "round" : "rounds")
                            .font(.system(size: layout.baseText * 0.75, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.textOnAccent.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)

                    // Divider
                    Rectangle()
                        .fill(theme.textOnAccent.opacity(0.3))
                        .frame(width: 1, height: layout.unit * 8)

                    // Challenge (right)
                    VStack(spacing: 0) {
                        Text("Challenge")
                            .font(.system(size: layout.baseText * 0.85, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent.opacity(0.85))
                        Text("\(challengeBest)")
                            .font(.system(size: layout.baseText * 2, weight: .black, design: .rounded))
                            .foregroundStyle(theme.textOnAccent)
                        Text(challengeBest == 1 ? "round" : "rounds")
                            .font(.system(size: layout.baseText * 0.75, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.textOnAccent.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, layout.unit * 2)

            // Game Center button - top right corner
            Button(action: {
                SoundManager.shared.play(.pop)
                HapticsManager.shared.light()
                GameCenterManager.shared.showLeaderboards()
            }) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: layout.isIPad ? 20 : 16, weight: .semibold))
                    .foregroundStyle(theme.textOnAccent.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .frame(width: cardWidth, height: cardHeight)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Watch/Your Turn Status Indicator

struct CopyStatusIndicator: View {
    let theme: Theme
    let layout: LayoutController
    let isShowingSequence: Bool
    let sequenceLength: Int
    let currentIndex: Int

    var body: some View {
        VStack(spacing: 8) {
            // Status text
            Text(isShowingSequence ? "Watch..." : "Your turn!")
                .font(.system(size: layout.baseText * 1.4, weight: .bold, design: .rounded))
                .foregroundStyle(isShowingSequence ? theme.accent : theme.textDark)
                .animation(.easeOut(duration: 0.2), value: isShowingSequence)

            // Sequence length indicator (subtle)
            if isShowingSequence {
                Text("\(currentIndex + 1) of \(sequenceLength)")
                    .font(.system(size: layout.baseText * 0.85, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.5))
            }
        }
        .frame(height: layout.unit * 5)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 4-Dot Simon Board

struct SimonBoard: View {
    let theme: Theme
    let layout: LayoutController
    let activeIndex: Int?  // Which dot is lit (-1 or nil = none)
    let pressedIndex: Int?  // Which dot is currently pressed (from game logic)
    let onTap: (Int) -> Void

    // Classic Simon colors (bright, when active) - vibrant and visible
    private let simonColors: [Color] = [
        Color(hex: "#FF6B6B"),  // Red (top-left) - bright coral red
        Color(hex: "#4DABF7"),  // Blue (top-right) - bright sky blue
        Color(hex: "#51CF66"),  // Green (bottom-left) - bright lime green
        Color(hex: "#FFE066")   // Yellow (bottom-right) - bright sunny yellow
    ]

    // Lighter versions for inactive state (still visible)
    private let simonColorsDark: [Color] = [
        Color(hex: "#C94C4C"),  // Muted red
        Color(hex: "#3A8AC4"),  // Muted blue
        Color(hex: "#3DA84A"),  // Muted green
        Color(hex: "#D4B84A")   // Muted yellow
    ]

    // Slightly darker for pressed state
    private let simonColorsPressed: [Color] = [
        Color(hex: "#A63D3D"),  // Pressed red
        Color(hex: "#2D6E9E"),  // Pressed blue
        Color(hex: "#2E8438"),  // Pressed green
        Color(hex: "#B89E3D")   // Pressed yellow
    ]

    // Bottom circle colors (shadow/base) - darker but not too dark
    private let simonColorsBottom: [Color] = [
        Color(hex: "#8B3535"),  // Bottom red
        Color(hex: "#245A82"),  // Bottom blue
        Color(hex: "#256B2D"),  // Bottom green
        Color(hex: "#9A8432")   // Bottom yellow
    ]

    private var dotSize: CGFloat {
        min(layout.boardWidth * 0.32, 110)  // Smaller dots
    }

    private var spacing: CGFloat {
        layout.unit * 2.5
    }

    // The "pop" offset - how much the top circle is raised
    private var layerOffset: CGFloat {
        layout.unit * 1.2
    }

    var body: some View {
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                simonDot(index: 0)
                simonDot(index: 1)
            }
            HStack(spacing: spacing) {
                simonDot(index: 2)
                simonDot(index: 3)
            }
        }
    }

    private func simonDot(index: Int) -> some View {
        SimonDotView(
            index: index,
            isActive: activeIndex == index,
            isGamePressed: pressedIndex == index,
            dotSize: dotSize,
            layerOffset: layerOffset,
            colors: simonColors,
            colorsDark: simonColorsDark,
            colorsPressed: simonColorsPressed,
            colorsBottom: simonColorsBottom,
            onTap: onTap
        )
    }
}

// Separate view to handle local press state
private struct SimonDotView: View {
    let index: Int
    let isActive: Bool
    let isGamePressed: Bool  // From game logic (showing sequence)
    let dotSize: CGFloat
    let layerOffset: CGFloat
    let colors: [Color]
    let colorsDark: [Color]
    let colorsPressed: [Color]
    let colorsBottom: [Color]
    let onTap: (Int) -> Void

    @State private var isLocalPressed = false

    // Either game logic or local touch causes pressed state
    private var isPressed: Bool {
        isGamePressed || isLocalPressed
    }

    // Top circle color based on state
    private var topColor: Color {
        if isPressed {
            return colorsPressed[index]
        } else if isActive {
            return colors[index]
        } else {
            return colorsDark[index]
        }
    }

    // Current offset - pressed pushes down to 0
    private var currentOffset: CGFloat {
        isPressed ? 0 : -layerOffset
    }

    private var totalHeight: CGFloat {
        dotSize + layerOffset
    }

    var body: some View {
        ZStack {
            // Soft glow when active (centered on top circle position)
            if isActive && !isPressed {
                Circle()
                    .fill(colors[index])
                    .blur(radius: 20)
                    .opacity(0.5)
                    .frame(width: dotSize, height: dotSize)
                    .position(x: dotSize / 2, y: layerOffset + dotSize / 2)
            }

            // Bottom circle (shadow/base) - fixed at bottom, never moves
            Circle()
                .fill(colorsBottom[index])
                .overlay(
                    Circle()
                        .stroke(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(width: dotSize, height: dotSize)
                .position(x: dotSize / 2, y: totalHeight - dotSize / 2)

            // Cylinder side lines - only visible when not pressed
            if !isPressed {
                let lineHeight = layerOffset
                let strokeWidth: CGFloat = 2.0

                // Left vertical line
                Rectangle()
                    .fill(Color(hex: "#3a3a3a"))
                    .frame(width: strokeWidth, height: lineHeight)
                    .position(x: strokeWidth / 2 + 1, y: layerOffset / 2 + dotSize / 2)

                // Right vertical line
                Rectangle()
                    .fill(Color(hex: "#3a3a3a"))
                    .frame(width: strokeWidth, height: lineHeight)
                    .position(x: dotSize - strokeWidth / 2 - 1, y: layerOffset / 2 + dotSize / 2)
            }

            // Top circle - moves down when pressed
            Circle()
                .fill(topColor)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(width: dotSize, height: dotSize)
                .position(x: dotSize / 2, y: dotSize / 2 + (isPressed ? layerOffset : 0))
                .animation(.easeOut(duration: 0.09), value: isPressed)
        }
        .frame(width: dotSize, height: totalHeight)
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isLocalPressed {
                        isLocalPressed = true
                        HapticsManager.shared.light()
                    }
                }
                .onEnded { _ in
                    if isLocalPressed {
                        isLocalPressed = false
                        onTap(index)
                    }
                }
        )
    }
}


// MARK: - Previews

#Preview("Copy Header") {
    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        GeometryReader { geo in
            let layout = LayoutController(geo)

            VStack {
                CopyHeader(
                    theme: .daylight,
                    layout: layout,
                    difficulty: .constant(.classic),
                    classicBest: 7,
                    challengeBest: 4,
                    currentRound: 3,
                    isShowingSequence: false,
                    isPlaying: false,
                    isRunning: false
                )
                Spacer()
            }
            .padding(.top, 60)
        }
    }
}

#Preview("Simon Board") {
    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        GeometryReader { geo in
            let layout = LayoutController(geo)

            SimonBoard(
                theme: .daylight,
                layout: layout,
                activeIndex: 0,
                pressedIndex: nil,
                onTap: { _ in }
            )
        }
    }
}

#Preview("Difficulty Rocker") {
    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        GeometryReader { geo in
            let layout = LayoutController(geo)

            VStack {
                CopyDifficultyRocker(
                    theme: .daylight,
                    layout: layout,
                    difficulty: .constant(.classic)
                )
                Spacer()
            }
            .padding(.top, 100)
        }
    }
}
