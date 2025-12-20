//
//  GameSetupPicker.swift
//  Poppy v1.2
//
//  Unified picker for game mode and time selection
//  Morphs from pill button: expand horizontally → drop down into rectangle
//  Shows 8 modes in 2x4 grid with lock icons for Plus modes
//

import SwiftUI

struct GameSetupPicker: View {
    let theme: Theme
    let layout: LayoutController
    @Binding var show: Bool
    @Binding var selectedMode: GameMode
    @Binding var selectedTime: Int
    let buttonFrame: CGRect
    let onConfirm: () -> Void
    var onLockedModeTap: ((GameMode) -> Void)?

    // Animation phases
    @State private var phase: AnimationPhase = .collapsed
    @State private var localMode: GameMode?
    @State private var localTime: Int = 30
    @State private var showContent = false

    enum AnimationPhase {
        case collapsed      // Initial pill size
        case expandedWide   // Pill stretched horizontally
        case expandedFull   // Full rectangle dropped down
    }

    // MARK: - Layout Constants

    private var collapsedWidth: CGFloat { buttonFrame.width }
    private var collapsedHeight: CGFloat { buttonFrame.height }

    // Wider to fit 2-column grid
    private let expandedWidth: CGFloat = 300

    // Height calculation
    private var expandedHeight: CGFloat {
        let headerHeight: CGFloat = 36  // Reduced from 44
        let modeSectionLabel: CGFloat = 28
        let modeGridHeight: CGFloat = 4 * 72 + 3 * 8  // 4 rows of 72pt + 8pt gaps
        let timeSectionHeight: CGFloat = activeMode.showsTimePicker ? (28 + timeSectionGridHeight + 12) : 0
        let confirmHeight: CGFloat = 64
        return headerHeight + modeSectionLabel + modeGridHeight + timeSectionHeight + confirmHeight + 16
    }

    // Time grid height varies by mode
    private var timeSectionGridHeight: CGFloat {
        let durations = activeMode.availableDurations
        let rows = ceil(Double(durations.count) / 3.0)
        return CGFloat(rows) * 44 + CGFloat(max(0, Int(rows) - 1)) * 8
    }

    private var currentWidth: CGFloat {
        switch phase {
        case .collapsed: return collapsedWidth
        case .expandedWide, .expandedFull: return expandedWidth
        }
    }

    private var currentHeight: CGFloat {
        switch phase {
        case .collapsed, .expandedWide: return collapsedHeight
        case .expandedFull: return expandedHeight
        }
    }

    private var currentRadius: CGFloat {
        switch phase {
        case .collapsed, .expandedWide: return collapsedHeight / 2
        case .expandedFull: return 18
        }
    }

    private var currentY: CGFloat {
        switch phase {
        case .collapsed:
            return buttonFrame.midY
        case .expandedWide:
            return buttonFrame.minY + collapsedHeight / 2
        case .expandedFull:
            return buttonFrame.minY + expandedHeight / 2
        }
    }

    private var dimOpacity: Double {
        switch phase {
        case .collapsed: return 0
        case .expandedWide: return 0.25
        case .expandedFull: return 0.5
        }
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black
                .opacity(dimOpacity)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPicker()
                }
                .animation(.easeOut(duration: 0.25), value: phase)

            // The morphing picker
            ZStack {
                // Background shape
                RoundedRectangle(cornerRadius: currentRadius, style: .continuous)
                    .fill(theme.bgTop)
                    .overlay(
                        RoundedRectangle(cornerRadius: currentRadius, style: .continuous)
                            .strokeBorder(theme.textDark.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(
                        color: phase == .expandedFull ? theme.shadow.opacity(0.25) : .clear,
                        radius: phase == .expandedFull ? 15 : 0,
                        y: phase == .expandedFull ? 8 : 0
                    )

                // Content
                ZStack {
                    // Collapsed/Wide: just the title centered
                    if phase != .expandedFull {
                        Text(displayText)
                            .font(.system(size: layout.setTimeButtonFontSize, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textDark)
                    }

                    // Expanded: full picker content
                    if phase == .expandedFull && showContent {
                        VStack(spacing: 0) {
                            // Header - reduced height to bring content closer
                            Text(displayText)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.textDark)
                                .frame(height: 32)
                                .padding(.top, 4)

                            // Mode section
                            sectionLabel("Mode")

                            // 2x4 mode grid
                            modeGrid
                                .padding(.horizontal, 12)

                            // Time section - only for modes with time selection
                            if activeMode.showsTimePicker {
                                sectionLabel("Duration")
                                    .padding(.top, 8)

                                timeGrid
                                    .padding(.horizontal, 12)
                                    .padding(.bottom, 4)
                            }

                            // Confirm button
                            Button(action: confirmSelection) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(theme.textOnAccent)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                                            .fill(theme.accent)
                                    )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 12)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                        }
                        .transition(.opacity)
                    }
                }
                .frame(width: currentWidth, height: currentHeight)
                .clipped()
            }
            .frame(width: currentWidth, height: currentHeight)
            .position(x: buttonFrame.midX, y: currentY)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: phase)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: activeMode.showsTimePicker)
        }
        .ignoresSafeArea()
        .onAppear {
            localMode = selectedMode
            localTime = selectedTime
            expandPicker()
        }
    }

    // MARK: - Display

    // Use selectedMode before localMode is initialized to avoid flash
    private var activeMode: GameMode {
        localMode ?? selectedMode
    }

    private var displayText: String {
        if activeMode.showsTimePicker {
            return "\(activeMode.displayName) \u{00B7} \(localTime)s"
        }
        return activeMode.displayName
    }

    // MARK: - Subviews

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textDark.opacity(0.75))
                .tracking(1)
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 28)
    }

    // 2x4 grid of mode cards
    private var modeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 8) {
            ForEach(GameMode.allCases) { mode in
                modeCard(mode)
            }
        }
    }

    private func modeCard(_ mode: GameMode) -> some View {
        let isSelected = activeMode == mode
        let isLocked = !UnlockManager.shared.isModeUnlocked(mode)

        return ZStack {
            // Content - ZStack centers by default
            VStack(spacing: 4) {
                Image(systemName: mode.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isLocked ? theme.textDark.opacity(0.35) : (isSelected ? theme.accent : theme.textDark.opacity(0.7)))

                Text(mode.displayName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(isLocked ? theme.textDark.opacity(0.45) : theme.textDark)
                    .lineLimit(1)
            }

            // Vertical PLUS banner on left side (only show if locked)
            if isLocked {
                HStack {
                    ZStack {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 12,
                            bottomLeadingRadius: 12,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 0
                        )
                        .fill(theme.accent.opacity(0.5))
                        .frame(width: 18)

                        Text("PLUS")
                            .font(.system(size: 8, weight: .black, design: .rounded))
                            .foregroundStyle(theme.accent)
                            .rotationEffect(.degrees(-90))
                            .fixedSize()
                    }
                    Spacer()
                }
            }

            // Lock icon pinned to top-right (full opacity)
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(theme.textDark.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(6)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? theme.accent.opacity(0.15) : theme.textDark.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(isSelected ? theme.accent : Color.clear, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture {
            if isLocked {
                SoundManager.shared.play(.pop)
                HapticsManager.shared.medium()
                dismissPicker()
                // Delay to let picker close first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onLockedModeTap?(mode)
                }
            } else {
                selectMode(mode)
            }
        }
    }

    private var timeGrid: some View {
        let durations = activeMode.availableDurations

        return LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 8) {
            ForEach(durations, id: \.self) { time in
                Button(action: {
                    selectTime(time)
                }) {
                    Text("\(time)s")
                        .font(.system(size: 18, weight: localTime == time ? .black : .semibold, design: .rounded))
                        .foregroundStyle(theme.textDark.opacity(localTime == time ? 1.0 : 0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(localTime == time ? theme.accent.opacity(0.2) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(localTime == time ? theme.accent : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func expandPicker() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            phase = .expandedWide
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                phase = .expandedFull
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showContent = true
                }
            }
        }
    }

    private func selectMode(_ mode: GameMode) {
        guard mode != activeMode else { return }
        SoundManager.shared.play(.menu)
        HapticsManager.shared.light()

        // Update time to mode's default if current time isn't available
        if mode.showsTimePicker && !mode.availableDurations.contains(localTime) {
            localTime = mode.defaultDuration
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            localMode = mode
        }
    }

    private func selectTime(_ time: Int) {
        guard time != localTime else { return }
        SoundManager.shared.play(.timeSelect)
        HapticsManager.shared.light()
        localTime = time
    }

    private func confirmSelection() {
        SoundManager.shared.play(.popUp)
        HapticsManager.shared.medium()

        selectedMode = activeMode
        selectedTime = localTime
        activeMode.save()

        onConfirm()
        dismissPicker()
    }

    private func dismissPicker() {
        HapticsManager.shared.light()

        // Step 1: Hide content
        withAnimation(.easeOut(duration: 0.1)) {
            showContent = false
        }

        // Step 2: Collapse height first (up)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeInOut(duration: 0.2)) {
                phase = .expandedWide
            }
        }

        // Step 3: Wait for height to finish, THEN collapse width (in)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            withAnimation(.easeInOut(duration: 0.15)) {
                phase = .collapsed
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            show = false
        }
    }

}

// MARK: - Preview

#Preview {
    @Previewable @State var show = true
    @Previewable @State var mode: GameMode = .classic
    @Previewable @State var time: Int = 30

    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()

        let buttonFrame = CGRect(x: 147, y: 80, width: 100, height: 36)

        if show {
            GameSetupPicker(
                theme: .daylight,
                layout: .preview,
                show: $show,
                selectedMode: $mode,
                selectedTime: $time,
                buttonFrame: buttonFrame,
                onConfirm: { }
            )
        }
    }
}
