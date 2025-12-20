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

    // Container dimensions
    private var containerWidth: CGFloat {
        layout.isIPad ? 500 : min(layout.boardWidth * 0.92, 360)
    }

    private var containerHeight: CGFloat {
        layout.isIPad ? 500 : min(layout.boardWidth * 1.1, 420)
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

    private var layerOffset: CGFloat {
        actualSize * 0.12
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
        .frame(width: size, height: size + layerOffset)
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

    private var cardWidth: CGFloat {
        layout.scoreboardExpandedWidth
    }

    private var cardHeight: CGFloat {
        layout.unit * 14  // Slightly taller than other flat cards
    }

    private var cornerRadius: CGFloat {
        layout.cornerRadiusMedium
    }

    var body: some View {
        // Single flat layer (no 3D offset since not interactive)
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                )

            // Content - centered high score
            VStack(spacing: PillStyle.contentSpacing) {
                Text("High Score")
                    .font(.system(size: PillStyle.labelSize, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent.opacity(0.85))

                Text("\(best)")
                    .font(.system(size: PillStyle.valueSize, weight: .black, design: .rounded))
                    .foregroundStyle(theme.textOnAccent)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Zoomy Header

struct ZoomyHeader: View {
    let theme: Theme
    let layout: LayoutController
    let best: Int

    var body: some View {
        ZoomyScoreCard(
            theme: theme,
            layout: layout,
            best: best
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Lives Display

struct ZoomyLivesView: View {
    let theme: Theme
    let layout: LayoutController
    let lives: Int
    let maxLives: Int

    var body: some View {
        HStack(spacing: layout.livesSpacing) {
            ForEach(0..<maxLives, id: \.self) { index in
                Image(systemName: index < lives ? "heart.fill" : "heart")
                    .font(.system(size: layout.livesHeartSize, weight: .semibold))
                    .foregroundStyle(index < lives ? Color(hex: "#FF6B6B") : theme.textDark.opacity(0.3))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: lives)
            }
        }
    }
}

// MARK: - Tappy Header (Survival Rounds)

struct TappyHeader: View {
    let theme: Theme
    let layout: LayoutController
    let round: Int
    let best: Int
    let isRunning: Bool

    var body: some View {
        // Pills row only - lives and timer moved to stats section
        HStack(spacing: 12) {
            // High Score pill (left) - display only
            TappyDisplayPill(theme: theme, layout: layout) {
                VStack(spacing: PillStyle.contentSpacing) {
                    Text("High Score")
                        .font(.system(size: PillStyle.labelSize, weight: .bold, design: .rounded))
                        .opacity(0.85)
                    Text("\(best)")
                        .font(.system(size: PillStyle.valueSize, weight: .black, design: .rounded))
                }
            }

            // Round pill (right) - shows current round
            TappyDisplayPill(theme: theme, layout: layout) {
                VStack(spacing: PillStyle.contentSpacing) {
                    Text("Round")
                        .font(.system(size: PillStyle.labelSize, weight: .bold, design: .rounded))
                        .opacity(0.85)
                    Text(isRunning ? "\(round)" : "--")
                        .font(.system(size: PillStyle.valueSize, weight: .black, design: .rounded))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: round)
                }
            }
        }
        .frame(width: layout.scoreboardExpandedWidth)
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

// MARK: - Tappy Stats Section (lives above center-out timer bar)

struct TappyStatsSection: View {
    let theme: Theme
    let layout: LayoutController
    let lives: Int
    let timeRemaining: Double
    let timeLimit: Double
    let isActive: Bool

    @State private var pulseOpacity: CGFloat = 1.0

    private var barHeight: CGFloat { 24 }  // Thicker than before (was 12)
    private var cornerRadius: CGFloat { barHeight / 2 }

    private var progress: Double {
        guard isActive, timeLimit > 0 else { return 1.0 }
        return timeRemaining / timeLimit
    }

    private var isUrgent: Bool {
        isActive && progress < 0.25
    }

    private var barColor: Color {
        guard isActive else { return theme.accent }
        if progress < 0.25 {
            return Color(hex: "#FF6B6B")  // Red - critical
        } else if progress < 0.5 {
            return Color(hex: "#FFB347")  // Orange - warning
        } else {
            return theme.accent
        }
    }

    var body: some View {
        VStack(spacing: layout.unit * 2) {
            // Lives row
            HStack(spacing: layout.livesSpacing * 1.5) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: index < lives ? "heart.fill" : "heart")
                        .font(.system(size: layout.livesHeartSize * 1.3, weight: .semibold))
                        .foregroundStyle(index < lives ? Color(hex: "#FF6B6B") : theme.textDark.opacity(0.3))
                }
            }

            // Timer bar with center-out fill
            GeometryReader { geo in
                ZStack {
                    // Background track
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.black.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.15), lineWidth: 2)
                        )

                    // Progress fill - center-out
                    if progress > 0 {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(barColor)
                            .frame(width: geo.size.width * progress)
                            .frame(maxWidth: .infinity)  // Centers the fill
                            .opacity(isUrgent ? pulseOpacity : 1.0)
                            .animation(.linear(duration: 0.05), value: progress)
                    }
                }
            }
            .frame(width: layout.scoreboardExpandedWidth, height: barHeight)
            .frame(maxWidth: .infinity)
        }
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

// MARK: - Seeky Header

struct SeekyHeader: View {
    let theme: Theme
    let layout: LayoutController
    let best: Int

    private var cardHeight: CGFloat { layout.unit * 12 }  // Taller card
    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }

    var body: some View {
        // Flat High Score card (not a button, no 3D offset)
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                )

            VStack(spacing: 4) {
                Text("High Score")
                    .font(.system(size: 16, weight: .bold, design: .rounded))  // Match Classic
                    .foregroundStyle(theme.textOnAccent.opacity(0.8))
                Text("\(best)")
                    .font(.system(size: 28, weight: .black, design: .rounded))  // Match Classic
                    .foregroundStyle(theme.textOnAccent)
            }
        }
        .frame(width: layout.scoreboardExpandedWidth, height: cardHeight)
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

    private var containerHeight: CGFloat { layout.unit * 14 }
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
        // Side-by-side layout: Score and Time
        HStack(spacing: layout.unit * 6) {
            // Score
            VStack(spacing: 4) {
                Text("Score")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.7))
                    .fixedSize()

                Text("\(score)")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(textColor)
                    .fixedSize()
            }

            // Time
            VStack(spacing: 4) {
                Text("Time")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.7))
                    .fixedSize()

                Text("\(timeRemaining)s")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(isUrgent && textColor == theme.textDark ? Color(hex: "#E85D75") : textColor)
                    .fixedSize()
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

    var body: some View {
        HStack(spacing: layout.livesSpacing * 1.2) {
            ForEach(0..<3, id: \.self) { index in
                Image(systemName: index < lives ? "heart.fill" : "heart")
                    .font(.system(size: heartSize, weight: .semibold))
                    .foregroundStyle(index < lives ? Color(hex: "#FF6B6B") : theme.textDark.opacity(0.3))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: lives)
            }
        }
        .padding(.top, layout.unit * 1.5)  // Move down a bit
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
