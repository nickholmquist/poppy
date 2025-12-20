//
//  GameSetupButton.swift
//  Poppy v1.2
//
//  Pill-shaped button showing current game mode and time selection
//  Replaces SetTimeButton in the top bar
//
//  SIZING: All dimensions come from LayoutController.swift
//

import SwiftUI

struct GameSetupButton: View {
    let theme: Theme
    let layout: LayoutController
    let mode: GameMode
    let time: Int
    let isEnabled: Bool
    let showHint: Bool
    let onTap: () -> Void

    @State private var glowAnimation = false

    init(theme: Theme, layout: LayoutController, mode: GameMode, time: Int, isEnabled: Bool, showHint: Bool = false, onTap: @escaping () -> Void) {
        self.theme = theme
        self.layout = layout
        self.mode = mode
        self.time = time
        self.isEnabled = isEnabled
        self.showHint = showHint
        self.onTap = onTap
    }

    private var displayText: String {
        if mode.showsTimePicker {
            return "\(mode.displayName) \u{00B7} \(time)s"
        }
        return mode.displayName
    }

    var body: some View {
        Button(action: {
            if isEnabled {
                SoundManager.shared.play(.pop)
                HapticsManager.shared.light()
                onTap()
            }
        }) {
            Text(displayText)
                .font(.system(size: layout.setTimeButtonFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textDark)
                .padding(.horizontal, layout.setTimeButtonPaddingH)
                .padding(.vertical, layout.setTimeButtonPaddingV)
                .background(
                    ZStack {
                        // Pulsing glow on stroke for new users
                        if showHint && isEnabled {
                            Capsule()
                                .strokeBorder(theme.accent, lineWidth: glowAnimation ? 4 : 2)
                                .blur(radius: glowAnimation ? 8 : 2)
                                .opacity(glowAnimation ? 1.0 : 0.3)
                                .scaleEffect(glowAnimation ? 1.08 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: glowAnimation)
                        }
                        Capsule()
                            .strokeBorder(showHint && isEnabled ? theme.accent : theme.textDark.opacity(0.3), lineWidth: 2)
                    }
                )
                .opacity(isEnabled ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.3), value: isEnabled)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onAppear {
            if showHint {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowAnimation = true
                }
            }
        }
        .onChange(of: showHint) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                    glowAnimation = true
                }
            } else {
                glowAnimation = false
            }
        }
    }
}

// MARK: - Previews

#Preview("Button States") {
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Classic Mode")
                .font(.caption)
            GameSetupButton(
                theme: .daylight,
                layout: .preview,
                mode: .classic,
                time: 30,
                isEnabled: true,
                onTap: { }
            )

            Text("Copy Mode (no time)")
                .font(.caption)
            GameSetupButton(
                theme: .daylight,
                layout: .preview,
                mode: .copy,
                time: 30,
                isEnabled: true,
                onTap: { }
            )

            Text("Disabled")
                .font(.caption)
            GameSetupButton(
                theme: .daylight,
                layout: .preview,
                mode: .classic,
                time: 30,
                isEnabled: false,
                onTap: { }
            )
        }
    }
}
