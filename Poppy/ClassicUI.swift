//
//  ClassicUI.swift
//  Poppy
//
//  UI components for Classic and Boppy modes
//  - Full-width High Score card with overlay
//  - Segmented duration picker (6 buttons)
//

import SwiftUI

// MARK: - Shared Pill Styling Constants

/// Shared styling constants for pills and overlays to stay in sync
enum PillStyle {
    static let labelSize: CGFloat = 18
    static let valueSize: CGFloat = 32
    static let contentSpacing: CGFloat = 6
}

// MARK: - Help Button (3D Square)

/// Small 3D square button with "?" for showing game instructions
struct HelpButton: View {
    let theme: Theme
    let layout: LayoutController
    let isPlaying: Bool
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var debouncedIsPlaying = false

    private var buttonSize: CGFloat { layout.button3DHeight }
    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }
    private var layerOffset: CGFloat { layout.button3DLayerOffset }

    // Stay pressed during gameplay (use debounced state to prevent flicker)
    private var isVisuallyPressed: Bool {
        isPressed || debouncedIsPlaying
    }

    private var currentOffset: CGFloat {
        isVisuallyPressed ? layerOffset : 0
    }

    private var topLayerColor: Color {
        isVisuallyPressed ? theme.accent.darker(by: 0.05) : theme.accent
    }

    var body: some View {
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
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(width: buttonSize, height: buttonSize)
                .offset(y: layerOffset)

            // Top layer (main button)
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(topLayerColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )

                Image(systemName: "questionmark")
                    .font(.system(size: buttonSize * 0.4, weight: .bold))
                    .foregroundStyle(theme.textOnAccent)
            }
            .frame(width: buttonSize, height: buttonSize)
            .offset(y: currentOffset)
        }
        .frame(width: buttonSize, height: buttonSize + layerOffset, alignment: .top)
        .contentShape(Rectangle())
        .accessibilityLabel("How to play")
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isVisuallyPressed)
        .onAppear { debouncedIsPlaying = isPlaying }
        .onChange(of: isPlaying) { _, newValue in
            if newValue {
                // Delay press to ignore short pulses (e.g., during difficulty switch animations)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    if isPlaying {
                        debouncedIsPlaying = true
                    }
                }
            } else {
                // Delay release to prevent flicker during mode transitions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if !isPlaying {
                        debouncedIsPlaying = false
                    }
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && !isPlaying {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    guard !isPlaying else { return }
                    SoundManager.shared.play(.pop)
                    HapticsManager.shared.light()
                    onTap()
                    isPressed = false
                }
        )
    }
}

// MARK: - Classic Header (Combined Time/Score Selector)

/// Header for Classic and Boppy modes - single pill showing time and high score
struct ClassicHeader: View {
    let theme: Theme
    let layout: LayoutController
    let gameMode: GameMode
    let highScores: [Int: Int]  // Duration -> Score mapping
    @Binding var selectedDuration: Int
    let isPlaying: Bool
    var timeRemaining: Double = 0  // Countdown time during gameplay
    let onInfoTap: () -> Void

    // Overlay state managed by parent for proper z-ordering
    @Binding var showTimeScoreOverlay: Bool
    @Binding var timeScorePillFrame: CGRect

    private var currentHighScore: Int {
        highScores[selectedDuration] ?? 0
    }

    // Display time: countdown during play, selected duration otherwise
    private var displayTime: String {
        if isPlaying && timeRemaining > 0 {
            return "\(Int(ceil(timeRemaining)))s"
        }
        return "\(selectedDuration)s"
    }

    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }
    private var layerOffset: CGFloat { layout.button3DLayerOffset }
    private var pillHeight: CGFloat { layout.button3DHeight }

    // Help button is square, same height as pill
    private var helpButtonSize: CGFloat { pillHeight }
    private var gapWidth: CGFloat { layout.unit }  // Tighter gap (8pt)
    // Pill takes remaining width after help button and gap
    private var pillWidth: CGFloat {
        layout.scoreboardExpandedWidth - helpButtonSize - gapWidth
    }

    @State private var isPressed = false

    // Top layer at 0 when popped, moves down to layerOffset when pressed
    private var currentOffset: CGFloat {
        (isPressed || isPlaying || showTimeScoreOverlay) ? layerOffset : 0
    }

    // Pressed/disabled color - darken slightly while keeping saturation
    private var topLayerColor: Color {
        (isPressed || isPlaying || showTimeScoreOverlay) ? theme.accent.darker(by: 0.05) : theme.accent
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: gapWidth) {
            timeScorePill
                .frame(width: pillWidth)

            HelpButton(theme: theme, layout: layout, isPlaying: isPlaying, onTap: onInfoTap)
        }
        .frame(width: layout.scoreboardExpandedWidth, height: layout.button3DTotalHeight)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Combined Time/Score Pill

    private var timeScorePill: some View {
        ZStack(alignment: .top) {
            // Bottom layer (depth) - pushed down by layerOffset
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
                .frame(height: pillHeight)
                .offset(y: layerOffset)

            // Top layer (main) - at top when popped, moves down when pressed
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(topLayerColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )

                // Content: Inline centered layout
                HStack(spacing: 24) {
                    // Time
                    Text(displayTime)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.15), value: displayTime)

                    // Divider
                    Rectangle()
                        .fill(theme.textOnAccent.opacity(0.3))
                        .frame(width: 2, height: pillHeight * 0.4)

                    // High Score
                    HStack(spacing: 6) {
                        Text("High Score")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent.opacity(0.8))
                        Text("\(currentHighScore)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent)
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(height: pillHeight)
            .offset(y: currentOffset)
        }
        .frame(height: layout.button3DTotalHeight, alignment: .top)
        .frame(maxWidth: .infinity)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showTimeScoreOverlay)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPlaying && !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    if !isPlaying {
                        // Open overlay - leave isPressed true so button stays down
                        SoundManager.shared.play(.pop)
                        HapticsManager.shared.light()
                        showTimeScoreOverlay = true
                    } else {
                        isPressed = false
                    }
                }
        )
        .onChange(of: showTimeScoreOverlay) { _, isShowing in
            if !isShowing {
                // Small delay so button appears pressed before popping up
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isPressed = false
                }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    timeScorePillFrame = geo.frame(in: .global)
                }
                .onChange(of: geo.frame(in: .global)) { _, newFrame in
                    timeScorePillFrame = newFrame
                }
            }
        )
    }
}

// MARK: - Classic Score Container (with integrated timer)

/// Score display container with timer fill that drains from center outward
struct ClassicScoreContainer: View {
    let theme: Theme
    let layout: LayoutController
    let score: Int
    let timeRemaining: Int
    let timeProgress: Double  // 1.0 = full, 0.0 = empty
    let isUrgent: Bool
    let isRunning: Bool
    let highScoreFlash: Bool
    let scoreBump: Bool
    var showTimer: Bool = false  // Whether to show time alongside score

    @State private var pulseOpacity: CGFloat = 1.0

    private var containerHeight: CGFloat { layout.headerCardHeight }  // Standardized height
    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }

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
                scoreContent(textColor: highScoreFlash ? Color(hex: "#FFD700") : theme.textDark)

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
        if showTimer {
            // Side-by-side inline layout for Daily mode
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
                        .scaleEffect(scoreBump ? 1.06 : 1.0, anchor: .center)
                        .animation(.spring(response: 0.22, dampingFraction: 0.6), value: scoreBump)
                        .shadow(
                            color: highScoreFlash ? Color(hex: "#FFD700").opacity(0.6) : .clear,
                            radius: highScoreFlash ? 12 : 0
                        )
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
                        .foregroundStyle(textColor)
                }
            }
        } else {
            // Centered inline score for Classic/Boppy
            HStack(spacing: 12) {
                Text("Score")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.7))
                Text("\(score)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(textColor)
                    .scaleEffect(scoreBump ? 1.06 : 1.0, anchor: .center)
                    .animation(.spring(response: 0.22, dampingFraction: 0.6), value: scoreBump)
                    .shadow(
                        color: highScoreFlash ? Color(hex: "#FFD700").opacity(0.6) : .clear,
                        radius: highScoreFlash ? 12 : 0
                    )
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

// MARK: - Classic Divider

/// A subtle divider line between the score section and the dots board
struct ClassicDivider: View {
    let theme: Theme
    let layout: LayoutController

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(theme.textDark.opacity(0.15))
            .frame(width: layout.scoreboardExpandedWidth, height: 2)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Pill Button (3D tappable style)

struct ClassicPillButton<Content: View>: View {
    let theme: Theme
    let layout: LayoutController
    let isDisabled: Bool
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content

    @State private var isPressed = false

    private var height: CGFloat { layout.unit * 6.5 }  // ~52pt
    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }
    private var layerOffset: CGFloat { layout.button3DLayerOffset }  // Universal 3D offset

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
                    .offset(y: (isPressed || isDisabled) ? 0 : -layerOffset)

                // Content
                content()
                    .foregroundStyle(theme.textOnAccent)
                    .offset(y: (isPressed || isDisabled) ? 0 : -layerOffset)
            }
            .frame(height: height)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .saturation(isDisabled ? 0.3 : 1.0)
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

// MARK: - Time/Score Selector Overlay

struct TimeScoreSelectorOverlay: View {
    let theme: Theme
    let layout: LayoutController
    let gameMode: GameMode
    let highScores: [Int: Int]
    @Binding var selectedDuration: Int
    @Binding var show: Bool
    let buttonFrame: CGRect

    @State private var phase: AnimationPhase = .collapsed
    @State private var localDuration: Int = 30

    enum AnimationPhase {
        case collapsed
        case expanded
    }

    private var availableDurations: [Int] {
        gameMode.availableDurations
    }

    private var collapsedWidth: CGFloat { buttonFrame.width }
    // Use the visual button height (not the frame which includes layer offset)
    private var collapsedHeight: CGFloat { layout.button3DHeight }

    // Height based on number of durations
    private var expandedHeight: CGFloat {
        let rowHeight: CGFloat = 52
        let spacing: CGFloat = 8
        let padding: CGFloat = 28
        let titleHeight: CGFloat = 36
        return titleHeight + CGFloat(availableDurations.count) * rowHeight + CGFloat(availableDurations.count - 1) * spacing + padding
    }

    private var currentHeight: CGFloat {
        phase == .expanded ? expandedHeight : collapsedHeight
    }

    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }
    private var layerOffset: CGFloat { layout.button3DLayerOffset }

    // Position overlay to match the pressed button's top layer position
    private var currentY: CGFloat {
        let pressedOffset = layerOffset  // Match pressed button position
        switch phase {
        case .collapsed:
            return buttonFrame.minY + pressedOffset + collapsedHeight / 2
        case .expanded:
            return buttonFrame.minY + pressedOffset + currentHeight / 2
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
                .onTapGesture { dismissOverlay() }
                .animation(.easeOut(duration: 0.2), value: phase)

            // The morphing overlay
            ZStack {
                // Background
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

                // Content
                if phase == .expanded {
                    VStack(spacing: 8) {
                        // Title
                        Text("Select Duration")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent)
                            .padding(.bottom, 4)

                        // Duration rows with scores
                        ForEach(availableDurations, id: \.self) { duration in
                            durationRow(duration: duration)
                        }
                    }
                    .padding(14)
                } else {
                    // Collapsed content (matches pill exactly - inline layout)
                    HStack(spacing: 24) {
                        // Time value
                        Text("\(localDuration)s")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent)

                        // Divider
                        Rectangle()
                            .fill(theme.textOnAccent.opacity(0.3))
                            .frame(width: 2, height: collapsedHeight * 0.4)

                        // High Score - inline
                        HStack(spacing: 6) {
                            Text("High Score")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.textOnAccent.opacity(0.8))
                            Text("\(highScores[localDuration] ?? 0)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(theme.textOnAccent)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .frame(width: collapsedWidth, height: currentHeight)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .position(x: buttonFrame.midX, y: currentY)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: phase)
        }
        .ignoresSafeArea()
        .onAppear {
            localDuration = selectedDuration
            expandOverlay()
        }
    }

    private func durationRow(duration: Int) -> some View {
        let score = highScores[duration] ?? 0
        let isSelected = localDuration == duration

        return Button(action: {
            SoundManager.shared.play(.timeSelect)
            HapticsManager.shared.light()
            withAnimation(.easeOut(duration: 0.15)) {
                localDuration = duration
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                confirmSelection()
            }
        }) {
            HStack {
                Text("\(duration) seconds")
                    .font(.system(size: 20, weight: isSelected ? .black : .heavy, design: .rounded))

                Spacer()

                // High score for this duration
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("\(score)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundStyle(isSelected ? theme.accent.opacity(0.7) : theme.textOnAccent.opacity(0.6))
            }
            .foregroundStyle(isSelected ? theme.accent : theme.textOnAccent)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? theme.textOnAccent : theme.textOnAccent.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
    }

    private func expandOverlay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                phase = .expanded
            }
        }
    }

    private func confirmSelection() {
        selectedDuration = localDuration
        dismissOverlay()
    }

    private func dismissOverlay() {
        withAnimation(.easeInOut(duration: 0.2)) {
            phase = .collapsed
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            show = false
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var duration = 30
    @Previewable @State var showTimeScore = false
    @Previewable @State var pillFrame: CGRect = .zero

    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()

        VStack {
            ClassicHeader(
                theme: .daylight,
                layout: .preview,
                gameMode: .classic,
                highScores: [10: 12, 20: 28, 30: 47, 40: 55, 50: 62, 60: 71],
                selectedDuration: $duration,
                isPlaying: false,
                onInfoTap: { print("Info tapped") },
                showTimeScoreOverlay: $showTimeScore,
                timeScorePillFrame: $pillFrame
            )
            .padding(.top, 100)

            Spacer()
        }

        if showTimeScore {
            TimeScoreSelectorOverlay(
                theme: .daylight,
                layout: .preview,
                gameMode: .classic,
                highScores: [10: 12, 20: 28, 30: 47, 40: 55, 50: 62, 60: 71],
                selectedDuration: $duration,
                show: $showTimeScore,
                buttonFrame: pillFrame
            )
        }
    }
}
