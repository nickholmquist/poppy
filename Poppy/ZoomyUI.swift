//
//  ZoomyUI.swift
//  Poppy
//
//  Zoomy mode UI components - dots cross through a contained play area
//

import SwiftUI

// MARK: - Zoomy Board View

struct ZoomyBoardView: View {
    let theme: Theme
    let layout: LayoutController
    let dots: [ZoomyDot]
    let lives: Int
    let score: Int
    let onTapDot: (UUID) -> Void

    // Dot colors - fun variety
    private let dotColors: [Color] = [
        Color(hex: "#FF6B6B"),  // Coral
        Color(hex: "#4ECDC4"),  // Teal
        Color(hex: "#FFE66D"),  // Yellow
        Color(hex: "#95E1D3"),  // Mint
        Color(hex: "#DDA0DD")   // Plum
    ]

    private var dotSize: CGFloat {
        layout.isIPad ? 70 : 54
    }

    // Container dimensions - larger to fill more of the screen
    private var containerWidth: CGFloat {
        layout.isIPad ? 550 : min(layout.boardWidth * 0.95, 380)
    }

    private var containerHeight: CGFloat {
        layout.isIPad ? 550 : min(layout.boardWidth * 1.2, 460)
    }

    private var containerCornerRadius: CGFloat {
        layout.isIPad ? 32 : 24
    }

    var body: some View {
        VStack(spacing: 8) {
            // Lives (left) and Score (right) - above container
            HStack {
                ZoomyLivesView(
                    theme: theme,
                    layout: layout,
                    lives: lives,
                    maxLives: 3
                )
                Spacer()
                ZoomyScoreLabel(
                    theme: theme,
                    layout: layout,
                    score: score
                )
            }
            .frame(width: containerWidth)

            // Play area container with clipped dots
            ZStack {
                // Container background
                RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
                    .fill(theme.bgTop.opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
                            .strokeBorder(theme.textDark.opacity(0.2), lineWidth: 2)
                    )

                // Dots layer - positions are relative to container
                ForEach(dots) { dot in
                    ZoomyDotView(
                        theme: theme,
                        color: dotColors[dot.colorIndex % dotColors.count],
                        size: dotSize,
                        layerOffset: layout.button3DLayerOffset,
                        isFast: dot.isFast,
                        onTap: { onTapDot(dot.id) }
                    )
                    .position(
                        x: dot.position.x * containerWidth,
                        y: dot.position.y * containerHeight
                    )
                }
            }
            .frame(width: containerWidth, height: containerHeight)
            .clipShape(RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// MARK: - Individual Zoomy Dot

private struct ZoomyDotView: View {
    let theme: Theme
    let color: Color
    let size: CGFloat
    let layerOffset: CGFloat
    let isFast: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    // Fast dots are slightly smaller but have a glow
    private var actualSize: CGFloat {
        isFast ? size * 0.85 : size
    }

    // Darker version for depth
    private var depthColor: Color {
        color.opacity(0.6)
    }

    var body: some View {
        ZStack {
            // Fast dot glow effect
            if isFast {
                Circle()
                    .fill(color.opacity(0.3))
                    .frame(width: actualSize * 1.4, height: actualSize * 1.4)
                    .blur(radius: 8)
            }

            // Bottom layer (depth/shadow)
            Circle()
                .fill(depthColor)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(width: actualSize, height: actualSize)

            // Top layer (surface) - moves down when pressed
            Circle()
                .fill(color)
                .overlay(
                    Circle()
                        .stroke(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(width: actualSize, height: actualSize)
                .offset(y: isPressed ? 0 : -layerOffset)
        }
        .frame(width: size, height: size + layerOffset, alignment: .top)
        .contentShape(Circle().scale(1.3))  // Larger hit area
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
                        onTap()
                    }
                }
        )
        .animation(.spring(response: 0.15, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - Zoomy Score Label (compact, for above container)

struct ZoomyScoreLabel: View {
    let theme: Theme
    let layout: LayoutController
    let score: Int

    var body: some View {
        HStack(spacing: 6) {
            Text("Score")
                .font(.system(size: layout.isIPad ? 20 : 18, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textDark.opacity(0.7))
            Text("\(score)")
                .font(.system(size: layout.isIPad ? 32 : 28, weight: .black, design: .rounded))
                .foregroundStyle(theme.textDark)
        }
    }
}

// MARK: - Zoomy Score Card

struct ZoomyScoreCard: View {
    let theme: Theme
    let layout: LayoutController
    let best: Int

    private var cardHeight: CGFloat {
        layout.button3DHeight  // Same height as HelpButton face
    }

    private var cornerRadius: CGFloat {
        layout.cornerRadiusMedium
    }

    var body: some View {
        // Flat card (non-tappable, no shadow)
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                )

            // Content - inline centered high score
            HStack(spacing: 6) {
                Text("High Score")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent.opacity(0.8))
                Text("\(best)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent)
            }
        }
        .frame(height: cardHeight)
    }
}

// MARK: - Zoomy Header

struct ZoomyHeader: View {
    let theme: Theme
    let layout: LayoutController
    let best: Int
    let isPlaying: Bool
    let onInfoTap: () -> Void

    // Help button is square, same height as card
    private var helpButtonSize: CGFloat { layout.button3DHeight }
    private var gapWidth: CGFloat { layout.unit }  // Tighter gap (8pt)
    private var layerOffset: CGFloat { layout.button3DLayerOffset }
    // Card takes remaining width after help button and gap
    private var cardWidth: CGFloat {
        layout.scoreboardExpandedWidth - helpButtonSize - gapWidth
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: gapWidth) {
            ZoomyScoreCard(
                theme: theme,
                layout: layout,
                best: best
            )
            .frame(width: cardWidth)

            HelpButton(theme: theme, layout: layout, isPlaying: isPlaying, onTap: onInfoTap)
        }
        .frame(width: layout.scoreboardExpandedWidth, height: layout.button3DTotalHeight)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Zoomy Header Row (Daily + High Score side by side)

struct ZoomyHeaderRow: View {
    let theme: Theme
    let layout: LayoutController
    let best: Int
    let isDailyCompleted: Bool
    let dailyStreak: Int
    let isDisabled: Bool
    let onDailyTap: () -> Void

    private var rowHeight: CGFloat { layout.button3DHeight }
    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }
    private var layerOffset: CGFloat { layout.button3DLayerOffset }
    private var spacing: CGFloat { layout.spacingNormal }

    // Each card takes half the width minus spacing
    private var cardWidth: CGFloat {
        (layout.scoreboardExpandedWidth - spacing) / 2
    }

    private let strokeColor = Color(hex: "#3a3a3a")
    private let completedGreen = Color(hex: "#5DBB63")

    @State private var isDailyPressed = false

    private var isDailyVisuallyPressed: Bool {
        isDailyPressed || isDisabled
    }

    var body: some View {
        HStack(spacing: spacing) {
            // Daily Banner (left) - 3D tappable
            dailyCard

            // High Score (right) - flat display
            highScoreCard
        }
        .frame(width: layout.scoreboardExpandedWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Daily Card (3D tappable)

    private var dailyCard: some View {
        ZStack(alignment: .top) {
            // Bottom layer (depth)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(strokeColor, lineWidth: 2)
                )
                .frame(height: rowHeight)
                .offset(y: layerOffset)

            // Top layer (moving surface)
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isDailyVisuallyPressed ? theme.accent.darker(by: 0.05) : theme.accent)

                HStack {
                    // Completion indicator (far left)
                    ZStack {
                        if isDailyCompleted {
                            Circle()
                                .fill(completedGreen)
                                .frame(width: 18, height: 18)
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        } else {
                            Circle()
                                .strokeBorder(theme.textOnAccent.opacity(0.5), lineWidth: 2)
                                .frame(width: 18, height: 18)
                        }
                    }

                    Spacer()

                    // Daily label (centered)
                    Text("Daily")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent.opacity(isDisabled ? 0.5 : 1.0))

                    Spacer()

                    // Streak (far right) or empty space for balance
                    if dailyStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(theme.textOnAccent.opacity(0.7))
                            Text("\(dailyStreak)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.textOnAccent.opacity(0.85))
                        }
                    } else {
                        // Empty space to balance the completion dot
                        Color.clear.frame(width: 18, height: 18)
                    }
                }
                .padding(.horizontal, 12)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: 2)
            }
            .frame(height: rowHeight)
            .offset(y: isDailyVisuallyPressed ? layerOffset : 0)
        }
        .frame(width: cardWidth, height: rowHeight + layerOffset, alignment: .top)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isDailyPressed && !isDisabled {
                        isDailyPressed = true
                        HapticsManager.shared.medium()
                    }
                }
                .onEnded { _ in
                    if isDailyPressed {
                        onDailyTap()
                        isDailyPressed = false
                    }
                }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDailyVisuallyPressed)
    }

    // MARK: - High Score Card (flat, but aligned with Daily's 3D bottom)

    private var highScoreCard: some View {
        VStack(spacing: 0) {
            // Spacer at top to push card down, aligning bottom with Daily's 3D offset
            Spacer().frame(height: layerOffset)

            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(strokeColor, lineWidth: 2)
                    )

                HStack {
                    Text("Best")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent.opacity(0.8))

                    Spacer()

                    Text("\(best)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
            }
            .frame(width: cardWidth, height: rowHeight)
        }
    }
}

// MARK: - Lives Display

struct ZoomyLivesView: View {
    let theme: Theme
    let layout: LayoutController
    let lives: Int
    let maxLives: Int

    private let strokeColor = Color(hex: "#3a3a3a")

    var body: some View {
        HStack(spacing: layout.livesSpacing) {
            ForEach(0..<maxLives, id: \.self) { index in
                ZStack {
                    if index < lives {
                        // Filled heart with accent color
                        Image(systemName: "heart.fill")
                            .font(.system(size: layout.livesHeartSize, weight: .regular))
                            .foregroundStyle(theme.accent)
                        // Stroke overlay - thinner stroke
                        Image(systemName: "heart")
                            .font(.system(size: layout.livesHeartSize, weight: .light))
                            .foregroundStyle(strokeColor)
                    } else {
                        // Empty heart outline - thinner stroke
                        Image(systemName: "heart")
                            .font(.system(size: layout.livesHeartSize, weight: .light))
                            .foregroundStyle(strokeColor.opacity(0.4))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: lives)
            }
        }
    }
}

// MARK: - Tappy Header (High Score + Help Button)

struct TappyHeader: View {
    let theme: Theme
    let layout: LayoutController
    let best: Int
    let isPlaying: Bool
    let onInfoTap: () -> Void

    private var cardHeight: CGFloat { layout.button3DHeight }
    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }

    // Help button is square, same height as card
    private var helpButtonSize: CGFloat { layout.button3DHeight }
    private var gapWidth: CGFloat { layout.unit }  // Tighter gap (8pt)
    private var layerOffset: CGFloat { layout.button3DLayerOffset }
    // Card takes remaining width after help button and gap
    private var cardWidth: CGFloat {
        layout.scoreboardExpandedWidth - helpButtonSize - gapWidth
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: gapWidth) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )

                HStack(spacing: 6) {
                    Text("High Score")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent.opacity(0.8))
                    Text("\(best)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                }
            }
            .frame(width: cardWidth, height: cardHeight)

            HelpButton(theme: theme, layout: layout, isPlaying: isPlaying, onTap: onInfoTap)
        }
        .frame(width: layout.scoreboardExpandedWidth, height: layout.button3DTotalHeight)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tappy Display Pill (flat style - not tappable)

struct TappyDisplayPill<Content: View>: View {
    let theme: Theme
    let layout: LayoutController
    @ViewBuilder let content: () -> Content

    private var height: CGFloat { layout.unit * 12 }  // Match Classic pill height
    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }

    var body: some View {
        ZStack {
            // Single flat layer (no 3D offset since not interactive)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                )

            // Content
            content()
                .foregroundStyle(theme.textOnAccent)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tappy Score Container (Round + Time with center-out timer - matches Seeky)

struct TappyScoreContainer: View {
    let theme: Theme
    let layout: LayoutController
    let round: Int
    let timeRemaining: Int
    let timeProgress: Double  // 1.0 = full, 0.0 = empty
    let isUrgent: Bool
    let isRunning: Bool

    @State private var pulseOpacity: CGFloat = 1.0

    private var containerHeight: CGFloat { layout.headerCardHeight }  // Standardized height
    private var cornerRadius: CGFloat { 20 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background container
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.15), lineWidth: 2)
                    )

                // Timer fill - drains from both edges toward center
                if isRunning && timeProgress > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius * min(1, timeProgress * 2), style: .continuous)
                        .fill(theme.accent)
                        .frame(width: geo.size.width * timeProgress)
                        .frame(maxWidth: .infinity) // Centers the fill
                        .opacity(isUrgent ? pulseOpacity : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: timeProgress)
                }

                // Score content - dark text (base layer)
                scoreContent(textColor: theme.textDark)

                // Score content - light text (revealed by timer fill mask)
                if isRunning && timeProgress > 0 {
                    scoreContent(textColor: theme.textOnAccent)
                        .mask(
                            RoundedRectangle(cornerRadius: cornerRadius * min(1, timeProgress * 2), style: .continuous)
                                .frame(width: geo.size.width * timeProgress)
                                .frame(maxWidth: .infinity)
                        )
                        .animation(.easeInOut(duration: 0.1), value: timeProgress)
                }
            }
        }
        .frame(width: layout.scoreboardExpandedWidth, height: containerHeight)
        .frame(maxWidth: .infinity)
        .onChange(of: isUrgent) { _, urgent in
            if urgent {
                startUrgencyPulse()
            } else {
                stopUrgencyPulse()
            }
        }
        .onAppear {
            if isUrgent {
                startUrgencyPulse()
            }
        }
    }

    // MARK: - Score Content

    @ViewBuilder
    private func scoreContent(textColor: Color) -> some View {
        // Inline layout: Round | Time
        HStack(spacing: layout.unit * 4) {
            // Round - inline
            HStack(spacing: 12) {
                Text("Round")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.7))
                Text(isRunning ? "\(round)" : "--")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(textColor)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: round)
            }

            // Divider
            Rectangle()
                .fill(textColor.opacity(0.3))
                .frame(width: 2, height: 28)

            // Time - inline
            HStack(spacing: 12) {
                Text("Time")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.7))
                Text("\(timeRemaining)s")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isUrgent && textColor == theme.textDark ? Color(hex: "#E85D75") : textColor)
            }
        }
    }

    // MARK: - Urgency Pulse

    private func startUrgencyPulse() {
        withAnimation(
            .easeInOut(duration: 0.5)
            .repeatForever(autoreverses: true)
        ) {
            pulseOpacity = 0.5
        }
    }

    private func stopUrgencyPulse() {
        withAnimation(.easeOut(duration: 0.2)) {
            pulseOpacity = 1.0
        }
    }
}

// MARK: - Tappy Lives Display (hearts below container - matches Seeky)

struct TappyLivesDisplay: View {
    let theme: Theme
    let layout: LayoutController
    let lives: Int

    private var heartSize: CGFloat { layout.livesHeartSize * 1.2 }
    private let strokeColor = Color(hex: "#3a3a3a")

    var body: some View {
        HStack(spacing: layout.livesSpacing * 1.2) {
            ForEach(0..<3, id: \.self) { index in
                ZStack {
                    if index < lives {
                        // Filled heart with accent color
                        Image(systemName: "heart.fill")
                            .font(.system(size: heartSize, weight: .regular))
                            .foregroundStyle(theme.accent)
                        // Stroke overlay - thinner stroke
                        Image(systemName: "heart")
                            .font(.system(size: heartSize, weight: .light))
                            .foregroundStyle(strokeColor)
                    } else {
                        // Empty heart outline - thinner stroke
                        Image(systemName: "heart")
                            .font(.system(size: heartSize, weight: .light))
                            .foregroundStyle(strokeColor.opacity(0.4))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: lives)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Seeky Header (High Score + Help Button)

struct SeekyHeader: View {
    let theme: Theme
    let layout: LayoutController
    let best: Int
    let isPlaying: Bool
    let onInfoTap: () -> Void

    private var cardHeight: CGFloat { layout.button3DHeight }
    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }

    // Help button is square, same height as card
    private var helpButtonSize: CGFloat { layout.button3DHeight }
    private var gapWidth: CGFloat { layout.unit }  // Tighter gap (8pt)
    private var layerOffset: CGFloat { layout.button3DLayerOffset }
    // Card takes remaining width after help button and gap
    private var cardWidth: CGFloat {
        layout.scoreboardExpandedWidth - helpButtonSize - gapWidth
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: gapWidth) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(theme.accent)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )

                HStack(spacing: 6) {
                    Text("High Score")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent.opacity(0.8))
                    Text("\(best)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                }
            }
            .frame(width: cardWidth, height: cardHeight)

            HelpButton(theme: theme, layout: layout, isPlaying: isPlaying, onTap: onInfoTap)
        }
        .frame(width: layout.scoreboardExpandedWidth, height: layout.button3DTotalHeight)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Seeky Score Container (matches ClassicScoreContainer with center-out timer)

struct SeekyScoreContainer: View {
    let theme: Theme
    let layout: LayoutController
    let score: Int
    let timeRemaining: Int
    let timeProgress: Double  // 1.0 = full, 0.0 = empty
    let isUrgent: Bool
    let isRunning: Bool
    let lives: Int

    @State private var pulseOpacity: CGFloat = 1.0

    private var containerHeight: CGFloat { layout.headerCardHeight }  // Standardized height
    private var cornerRadius: CGFloat { 20 }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background container
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.black.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.black.opacity(0.15), lineWidth: 2)
                    )

                // Timer fill - drains from both edges toward center
                if isRunning && timeProgress > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius * min(1, timeProgress * 2), style: .continuous)
                        .fill(theme.accent)
                        .frame(width: geo.size.width * timeProgress)
                        .frame(maxWidth: .infinity) // Centers the fill
                        .opacity(isUrgent ? pulseOpacity : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: timeProgress)
                }

                // Score content - dark text (base layer)
                scoreContent(textColor: theme.textDark)

                // Score content - light text (revealed by timer fill mask)
                if isRunning && timeProgress > 0 {
                    scoreContent(textColor: theme.textOnAccent)
                        .mask(
                            RoundedRectangle(cornerRadius: cornerRadius * min(1, timeProgress * 2), style: .continuous)
                                .frame(width: geo.size.width * timeProgress)
                                .frame(maxWidth: .infinity)
                        )
                        .animation(.easeInOut(duration: 0.1), value: timeProgress)
                }
            }
        }
        .frame(width: layout.scoreboardExpandedWidth, height: containerHeight)
        .frame(maxWidth: .infinity)
        .onChange(of: isUrgent) { _, urgent in
            if urgent {
                startUrgencyPulse()
            } else {
                stopUrgencyPulse()
            }
        }
        .onAppear {
            if isUrgent {
                startUrgencyPulse()
            }
        }
    }

    // MARK: - Score Content

    @ViewBuilder
    private func scoreContent(textColor: Color) -> some View {
        // Inline layout: Score | Time
        HStack(spacing: layout.unit * 4) {
            // Score - inline
            HStack(spacing: 12) {
                Text("Score")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.7))
                Text("\(score)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(textColor)
            }

            // Divider
            Rectangle()
                .fill(textColor.opacity(0.3))
                .frame(width: 2, height: 28)

            // Time - inline
            HStack(spacing: 12) {
                Text("Time")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.7))
                Text("\(timeRemaining)s")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isUrgent && textColor == theme.textDark ? Color(hex: "#E85D75") : textColor)
            }
        }
    }

    // MARK: - Urgency Pulse

    private func startUrgencyPulse() {
        withAnimation(
            .easeInOut(duration: 0.5)
            .repeatForever(autoreverses: true)
        ) {
            pulseOpacity = 0.5
        }
    }

    private func stopUrgencyPulse() {
        withAnimation(.easeOut(duration: 0.2)) {
            pulseOpacity = 1.0
        }
    }
}

// MARK: - Seeky Lives Row (for between timer and dots)

struct SeekyLivesDisplay: View {
    let theme: Theme
    let layout: LayoutController
    let lives: Int

    private var heartSize: CGFloat { layout.livesHeartSize * 1.2 }  // Slightly bigger
    private let strokeColor = Color(hex: "#3a3a3a")

    var body: some View {
        HStack(spacing: layout.livesSpacing * 1.2) {
            ForEach(0..<3, id: \.self) { index in
                ZStack {
                    if index < lives {
                        // Filled heart with accent color
                        Image(systemName: "heart.fill")
                            .font(.system(size: heartSize, weight: .regular))
                            .foregroundStyle(theme.accent)
                        // Stroke overlay - thinner stroke
                        Image(systemName: "heart")
                            .font(.system(size: heartSize, weight: .light))
                            .foregroundStyle(strokeColor)
                    } else {
                        // Empty heart outline - thinner stroke
                        Image(systemName: "heart")
                            .font(.system(size: heartSize, weight: .light))
                            .foregroundStyle(strokeColor.opacity(0.4))
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: lives)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Previews

#Preview("Zoomy Board") {
    let sampleDots = [
        ZoomyDot(position: CGPoint(x: 0.3, y: 0.3), velocity: CGPoint(x: 0.5, y: 0.5), colorIndex: 0, isFast: false, exitEdge: 2),
        ZoomyDot(position: CGPoint(x: 0.7, y: 0.5), velocity: CGPoint(x: -0.5, y: 0.3), colorIndex: 1, isFast: true, exitEdge: 3),
        ZoomyDot(position: CGPoint(x: 0.5, y: 0.7), velocity: CGPoint(x: 0.2, y: -0.8), colorIndex: 2, isFast: false, exitEdge: 0)
    ]

    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        ZoomyBoardView(
            theme: .daylight,
            layout: .preview,
            dots: sampleDots,
            lives: 3,
            score: 42,
            onTapDot: { _ in }
        )
        .frame(width: 350, height: 500)
    }
}

#Preview("Lives View") {
    VStack(spacing: 20) {
        ZoomyLivesView(theme: .daylight, layout: .preview, lives: 3, maxLives: 3)
        ZoomyLivesView(theme: .daylight, layout: .preview, lives: 2, maxLives: 3)
        ZoomyLivesView(theme: .daylight, layout: .preview, lives: 1, maxLives: 3)
        ZoomyLivesView(theme: .daylight, layout: .preview, lives: 0, maxLives: 3)
    }
    .padding()
    .background(Color(hex: "#F9F6EC"))
}
