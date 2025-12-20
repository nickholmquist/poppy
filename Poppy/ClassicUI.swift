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

// MARK: - Classic Header (Two Side-by-Side Pills)

/// Header for Classic and Boppy modes - two taller pills side by side
struct ClassicHeader: View {
    let theme: Theme
    let layout: LayoutController
    let gameMode: GameMode
    let highScores: [Int: Int]  // Duration -> Score mapping
    @Binding var selectedDuration: Int
    let isPlaying: Bool
    var timeRemaining: Double = 0  // Countdown time during gameplay

    // Overlay state managed by parent for proper z-ordering
    @Binding var showHighScoreOverlay: Bool
    @Binding var showDurationOverlay: Bool
    @Binding var highScorePillFrame: CGRect
    @Binding var durationPillFrame: CGRect

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
    private var layerOffset: CGFloat { layout.unit * 1.2 }
    private var pillHeight: CGFloat { layout.unit * 12 }  // Taller pills (~96pt)

    @State private var highScorePressed = false
    @State private var durationPressed = false

    var body: some View {
        HStack(spacing: 12) {
            // High Score Pill
            highScorePill

            // Duration Pill
            durationPill
        }
        .frame(width: layout.scoreboardExpandedWidth)
        .frame(maxWidth: .infinity)
    }

    // MARK: - High Score Pill

    private var highScorePill: some View {
        ZStack {
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

            // Top layer (main)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .offset(y: (highScorePressed || isPlaying || showHighScoreOverlay) ? 0 : -layerOffset)

            // Content
            VStack(spacing: PillStyle.contentSpacing) {
                Text("High Score")
                    .font(.system(size: PillStyle.labelSize, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent.opacity(0.8))

                Text("\(currentHighScore)")
                    .font(.system(size: PillStyle.valueSize, weight: .black, design: .rounded))
                    .foregroundStyle(theme.textOnAccent)
            }
            .offset(y: (highScorePressed || isPlaying || showHighScoreOverlay) ? 0 : -layerOffset)
        }
        .frame(height: pillHeight)
        .frame(maxWidth: .infinity)
        .saturation(isPlaying ? 0.3 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPlaying)
        .animation(.easeOut(duration: 0.1), value: highScorePressed)
        .animation(nil, value: showHighScoreOverlay)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPlaying && !highScorePressed {
                        highScorePressed = true
                    }
                }
                .onEnded { _ in
                    highScorePressed = false
                    if !isPlaying {
                        SoundManager.shared.play(.pop)
                        HapticsManager.shared.light()
                        showHighScoreOverlay = true
                    }
                }
        )
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    highScorePillFrame = geo.frame(in: .global)
                }
                .onChange(of: geo.frame(in: .global)) { _, newFrame in
                    highScorePillFrame = newFrame
                }
            }
        )
    }

    // MARK: - Duration Pill

    private var durationPill: some View {
        ZStack {
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

            // Top layer (main)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .offset(y: (durationPressed || isPlaying || showDurationOverlay) ? 0 : -layerOffset)

            // Content
            VStack(spacing: PillStyle.contentSpacing) {
                Text("Time")
                    .font(.system(size: PillStyle.labelSize, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent.opacity(0.8))

                Text(displayTime)
                    .font(.system(size: PillStyle.valueSize, weight: .black, design: .rounded))
                    .foregroundStyle(theme.textOnAccent)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.15), value: displayTime)
            }
            .offset(y: (durationPressed || isPlaying || showDurationOverlay) ? 0 : -layerOffset)
        }
        .frame(height: pillHeight)
        .frame(maxWidth: .infinity)
        .saturation(isPlaying ? 0.3 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isPlaying)
        .animation(.easeOut(duration: 0.1), value: durationPressed)
        .animation(nil, value: showDurationOverlay)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPlaying && !durationPressed {
                        durationPressed = true
                    }
                }
                .onEnded { _ in
                    durationPressed = false
                    if !isPlaying {
                        SoundManager.shared.play(.pop)
                        HapticsManager.shared.light()
                        showDurationOverlay = true
                    }
                }
        )
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    durationPillFrame = geo.frame(in: .global)
                }
                .onChange(of: geo.frame(in: .global)) { _, newFrame in
                    durationPillFrame = newFrame
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

    private var containerHeight: CGFloat { layout.unit * 16 }  // Taller container (~128pt)
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
            // Side-by-side layout for Daily mode
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
                        .scaleEffect(scoreBump ? 1.06 : 1.0, anchor: .center)
                        .animation(.spring(response: 0.22, dampingFraction: 0.6), value: scoreBump)
                        .shadow(
                            color: highScoreFlash ? Color(hex: "#FFD700").opacity(0.6) : .clear,
                            radius: highScoreFlash ? 12 : 0
                        )
                }

                // Time
                VStack(spacing: 4) {
                    Text("Time")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(textColor.opacity(0.7))
                        .fixedSize()

                    Text("\(timeRemaining)s")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(textColor)
                        .fixedSize()
                }
            }
        } else {
            // Centered score only for Classic/Boppy
            VStack(spacing: 6) {
                Text("Score")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor.opacity(0.7))
                    .fixedSize()

                Text("\(score)")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(textColor)
                    .fixedSize()
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
    private var layerOffset: CGFloat { layout.unit * 0.6 }

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

// MARK: - High Score Overlay

struct HighScoreOverlay: View {
    let theme: Theme
    let layout: LayoutController
    let gameMode: GameMode
    let highScores: [Int: Int]
    let currentDuration: Int
    @Binding var show: Bool
    let buttonFrame: CGRect

    @State private var phase: AnimationPhase = .collapsed

    enum AnimationPhase {
        case collapsed
        case expanded
    }

    private var availableDurations: [Int] {
        gameMode.availableDurations
    }

    private var collapsedWidth: CGFloat { buttonFrame.width }
    private var collapsedHeight: CGFloat { buttonFrame.height }

    // Height based on number of durations
    private var expandedHeight: CGFloat {
        let rowHeight: CGFloat = 44
        let spacing: CGFloat = 8
        let padding: CGFloat = 28
        let titleHeight: CGFloat = 36
        let closeButtonHeight: CGFloat = 48  // 36 button + 12 padding
        return titleHeight + CGFloat(availableDurations.count) * rowHeight + CGFloat(availableDurations.count - 1) * spacing + closeButtonHeight + padding
    }

    private var currentHeight: CGFloat {
        phase == .expanded ? expandedHeight : collapsedHeight
    }

    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }

    // Account for 3D button's layer offset (top layer is shifted up)
    private var layerOffset: CGFloat { layout.unit * 1.2 }

    private var currentY: CGFloat {
        switch phase {
        case .collapsed:
            return buttonFrame.midY - layerOffset
        case .expanded:
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
                        Text("High Scores")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent)
                            .padding(.bottom, 4)

                        // Score rows
                        ForEach(availableDurations, id: \.self) { duration in
                            scoreRow(duration: duration)
                        }

                        // Close button
                        Button(action: {
                            SoundManager.shared.play(.pop)
                            HapticsManager.shared.light()
                            dismissOverlay()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(theme.accent)
                                .frame(width: 36, height: 36)
                                .background(
                                    Circle()
                                        .fill(theme.textOnAccent.opacity(0.85))
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(14)
                } else {
                    // Collapsed content (matches pill exactly)
                    VStack(spacing: PillStyle.contentSpacing) {
                        Text("High Score")
                            .font(.system(size: PillStyle.labelSize, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent.opacity(0.8))

                        Text("\(highScores[currentDuration] ?? 0)")
                            .font(.system(size: PillStyle.valueSize, weight: .black, design: .rounded))
                            .foregroundStyle(theme.textOnAccent)
                    }
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
            expandOverlay()
        }
    }

    private func scoreRow(duration: Int) -> some View {
        let score = highScores[duration] ?? 0
        let isCurrentDuration = duration == currentDuration

        return HStack {
            Text("\(duration)s")
                .font(.system(size: 16, weight: .bold, design: .rounded))

            Spacer()

            Text("\(score)")
                .font(.system(size: 20, weight: .black, design: .rounded))
        }
        .foregroundStyle(theme.textOnAccent.opacity(isCurrentDuration ? 1.0 : 0.7))
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(theme.textOnAccent.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(theme.textOnAccent, lineWidth: isCurrentDuration ? 2 : 0)
        )
    }

    private func expandOverlay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                phase = .expanded
            }
        }
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

// MARK: - Duration Picker Overlay

struct DurationPickerOverlay: View {
    let theme: Theme
    let layout: LayoutController
    let gameMode: GameMode
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
    private var collapsedHeight: CGFloat { buttonFrame.height }

    // Height based on number of durations
    private var expandedHeight: CGFloat {
        let rowHeight: CGFloat = 48
        let spacing: CGFloat = 8
        let padding: CGFloat = 28
        return CGFloat(availableDurations.count) * rowHeight + CGFloat(availableDurations.count - 1) * spacing + padding
    }

    private var currentHeight: CGFloat {
        phase == .expanded ? expandedHeight : collapsedHeight
    }

    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }

    // Account for 3D button's layer offset (top layer is shifted up)
    private var layerOffset: CGFloat { layout.unit * 1.2 }

    private var currentY: CGFloat {
        switch phase {
        case .collapsed:
            return buttonFrame.midY - layerOffset
        case .expanded:
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
                        ForEach(availableDurations, id: \.self) { duration in
                            durationOption(duration)
                        }
                    }
                    .padding(14)
                } else {
                    // Collapsed content (matches pill exactly)
                    VStack(spacing: PillStyle.contentSpacing) {
                        Text("Time")
                            .font(.system(size: PillStyle.labelSize, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent.opacity(0.8))

                        Text("\(localDuration)s")
                            .font(.system(size: PillStyle.valueSize, weight: .black, design: .rounded))
                            .foregroundStyle(theme.textOnAccent)
                    }
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

    private func durationOption(_ duration: Int) -> some View {
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
            Text("\(duration) seconds")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? theme.accent : theme.textOnAccent.opacity(0.9))
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
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
    @Previewable @State var showHighScore = false
    @Previewable @State var showDuration = false
    @Previewable @State var hsFrame: CGRect = .zero
    @Previewable @State var durFrame: CGRect = .zero

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
                showHighScoreOverlay: $showHighScore,
                showDurationOverlay: $showDuration,
                highScorePillFrame: $hsFrame,
                durationPillFrame: $durFrame
            )
            .padding(.top, 100)

            Spacer()
        }

        if showHighScore {
            HighScoreOverlay(
                theme: .daylight,
                layout: .preview,
                gameMode: .classic,
                highScores: [10: 12, 20: 28, 30: 47, 40: 55, 50: 62, 60: 71],
                currentDuration: duration,
                show: $showHighScore,
                buttonFrame: hsFrame
            )
        }

        if showDuration {
            DurationPickerOverlay(
                theme: .daylight,
                layout: .preview,
                gameMode: .classic,
                selectedDuration: $duration,
                show: $showDuration,
                buttonFrame: durFrame
            )
        }
    }
}
