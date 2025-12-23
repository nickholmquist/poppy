//
//  TopBar.swift
//  Poppy
//
//  Top navigation bar with theme, menu, and game setup buttons
//
//  SIZING: All dimensions come from LayoutController.swift
//  Do not hardcode any sizes, spacing, or dimensions in this file.
//

import SwiftUI

// MARK: - Daily Calendar Button

/// Small calendar button for top bar that shows Daily mode status
struct DailyCalendarButton: View {
    let theme: Theme
    let layout: LayoutController
    let isCompleted: Bool
    let isDisabled: Bool
    let onTap: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    private var buttonSize: CGFloat { layout.topBarButtonSize }

    // Show pulse when daily not yet completed today
    private var shouldPulse: Bool {
        !isCompleted && !isDisabled
    }

    var body: some View {
        Button(action: {
            guard !isDisabled else { return }
            SoundManager.shared.play(.pop)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onTap()
        }) {
            ZStack {
                // Subtle glow/pulse ring (only when not completed)
                if shouldPulse {
                    Circle()
                        .fill(theme.textDark.opacity(0.15))
                        .frame(width: buttonSize, height: buttonSize)
                        .scaleEffect(pulseScale)
                }

                // Calendar icon background
                Circle()
                    .fill(theme.textDark.opacity(0.6))
                    .frame(width: buttonSize, height: buttonSize)
                    .shadow(color: theme.shadow.opacity(0.3), radius: 7, x: 0, y: 2)

                // Calendar icon
                Image(systemName: "calendar")
                    .font(.system(size: buttonSize * 0.5, weight: .semibold))
                    .foregroundStyle(theme.bgTop)

                // Checkmark overlay when completed
                if isCompleted {
                    Circle()
                        .fill(Color(hex: "#5DBB63"))
                        .frame(width: buttonSize * 0.4, height: buttonSize * 0.4)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: buttonSize * 0.2, weight: .bold))
                                .foregroundStyle(.white)
                        )
                        .offset(x: buttonSize * 0.3, y: -buttonSize * 0.3)
                }
            }
            .contentShape(Circle())
            .opacity(isDisabled ? 0.5 : 1.0)
            .accessibilityLabel(isCompleted ? "Daily challenge completed" : "Play daily challenge")
        }
        .onAppear {
            if shouldPulse {
                startPulse()
            }
        }
        .onChange(of: isCompleted) { _, completed in
            if completed {
                stopPulse()
            } else {
                startPulse()
            }
        }
    }

    private func startPulse() {
        withAnimation(
            .easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.3
        }
    }

    private func stopPulse() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale = 1.0
        }
    }
}

struct TopBar: View {
    let theme: Theme
    let layout: LayoutController
    let isPlaying: Bool
    let isThemeLocked: Bool
    let isSetupPickerOpen: Bool
    let gameMode: GameMode
    let selectedTime: Int
    let showModeHint: Bool
    let isDailyCompleted: Bool
    let onThemeTap: () -> Void
    let onThemeLongPress: () -> Void
    let onMenuTap: () -> Void
    let onSetupTap: () -> Void
    let onDailyTap: () -> Void
    let onButtonFrameChange: ((CGRect) -> Void)?
    let onThemeButtonFrameChange: ((CGRect) -> Void)?
    let onMenuButtonFrameChange: ((CGRect) -> Void)?

    init(theme: Theme,
         layout: LayoutController,
         isPlaying: Bool,
         isThemeLocked: Bool = false,
         isSetupPickerOpen: Bool = false,
         gameMode: GameMode = .classic,
         selectedTime: Int = 30,
         showModeHint: Bool = false,
         isDailyCompleted: Bool = false,
         onThemeTap: @escaping () -> Void,
         onThemeLongPress: @escaping () -> Void = {},
         onMenuTap: @escaping () -> Void,
         onSetupTap: @escaping () -> Void,
         onDailyTap: @escaping () -> Void = {},
         onButtonFrameChange: ((CGRect) -> Void)? = nil,
         onThemeButtonFrameChange: ((CGRect) -> Void)? = nil,
         onMenuButtonFrameChange: ((CGRect) -> Void)? = nil) {
        self.theme = theme
        self.layout = layout
        self.isPlaying = isPlaying
        self.isThemeLocked = isThemeLocked
        self.isSetupPickerOpen = isSetupPickerOpen
        self.gameMode = gameMode
        self.selectedTime = selectedTime
        self.showModeHint = showModeHint
        self.isDailyCompleted = isDailyCompleted
        self.onThemeTap = onThemeTap
        self.onThemeLongPress = onThemeLongPress
        self.onMenuTap = onMenuTap
        self.onSetupTap = onSetupTap
        self.onDailyTap = onDailyTap
        self.onButtonFrameChange = onButtonFrameChange
        self.onThemeButtonFrameChange = onThemeButtonFrameChange
        self.onMenuButtonFrameChange = onMenuButtonFrameChange
    }

    var body: some View {
        ZStack {
            // Center: Game Setup button (mode + time) - absolutely centered
            // Hidden when picker is open (picker draws its own collapsed state)
            GameSetupButton(
                theme: theme,
                layout: layout,
                mode: gameMode,
                time: selectedTime,
                isEnabled: !isPlaying,
                showHint: showModeHint,
                onTap: onSetupTap
            )
            .opacity(isSetupPickerOpen ? 0 : 1)
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear {
                        onButtonFrameChange?(geo.frame(in: .global))
                    }
                    .onChange(of: geo.frame(in: .global)) { _, newFrame in
                        onButtonFrameChange?(newFrame)
                    }
                }
            )

            // Left and right buttons
            HStack {
                // Left side: Theme dot + Daily calendar button
                HStack(spacing: layout.spacingNormal) {
                    // Theme dot button
                    Circle()
                        .fill(theme.accent)
                        .frame(width: layout.topBarButtonSize, height: layout.topBarButtonSize)
                        .shadow(color: theme.shadow.opacity(0.3), radius: 7, x: 0, y: 2)
                        .contentShape(Circle())
                        .opacity(isThemeLocked ? 0.5 : 1.0)
                        .accessibilityLabel("Change theme")
                        .onTapGesture {
                            guard !isThemeLocked else { return }
                            SoundManager.shared.play(.themeChange)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onThemeTap()
                        }
                        .onLongPressGesture(minimumDuration: 0.4) {
                            guard !isThemeLocked else { return }
                            SoundManager.shared.play(.menu)
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onThemeLongPress()
                        }
                        .animation(.easeInOut(duration: 0.2), value: isThemeLocked)
                        .background(
                            GeometryReader { geo in
                                Color.clear.onAppear {
                                    onThemeButtonFrameChange?(geo.frame(in: .global))
                                }
                                .onChange(of: geo.frame(in: .global)) { _, newFrame in
                                    onThemeButtonFrameChange?(newFrame)
                                }
                            }
                        )

                    // Daily calendar button
                    DailyCalendarButton(
                        theme: theme,
                        layout: layout,
                        isCompleted: isDailyCompleted,
                        isDisabled: isPlaying,
                        onTap: onDailyTap
                    )
                }

                Spacer()

                // Right side: Game Center button (conditional) + Menu button
                HStack(spacing: layout.spacingNormal) {
                    // Game Center button - only for modes with leaderboards
                    if gameMode.hasGameCenter {
                        Button(action: {
                            SoundManager.shared.play(.pop)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            GameCenterManager.shared.showLeaderboards()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(theme.textDark.opacity(0.6))
                                    .frame(width: layout.topBarButtonSize, height: layout.topBarButtonSize)
                                    .shadow(color: theme.shadow.opacity(0.3), radius: 7, x: 0, y: 2)

                                Image(systemName: "trophy.fill")
                                    .font(.system(size: layout.topBarButtonSize * 0.45, weight: .semibold))
                                    .foregroundStyle(theme.bgTop)
                            }
                            .contentShape(Circle())
                            .accessibilityLabel("Game Center leaderboards")
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    // Menu button
                    Button(action: {
                        SoundManager.shared.play(.menu)
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onMenuTap()
                    }) {
                        Circle()
                            .fill(theme.textDark.opacity(0.6))
                            .frame(width: layout.topBarButtonSize, height: layout.topBarButtonSize)
                            .shadow(color: theme.shadow.opacity(0.3), radius: 7, x: 0, y: 2)
                            .contentShape(Circle())
                            .accessibilityLabel("Open menu")
                    }
                    .background(
                        GeometryReader { geo in
                            Color.clear.onAppear {
                                onMenuButtonFrameChange?(geo.frame(in: .global))
                            }
                            .onChange(of: geo.frame(in: .global)) { _, newFrame in
                                onMenuButtonFrameChange?(newFrame)
                            }
                        }
                    )
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: gameMode.hasGameCenter)
            }
        }
        .padding(.top, layout.topBarPaddingTop)
        .padding(.horizontal, layout.topBarPaddingHorizontal)
    }
}
