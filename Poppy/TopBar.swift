//
//  TopBar.swift
//  Poppy
//
//  Top navigation bar with theme, menu, and time buttons
//
//  âš ï¸ SIZING: All dimensions come from LayoutController.swift
//  Do not hardcode any sizes, spacing, or dimensions in this file.
//

import SwiftUI

struct TopBar: View {
    let theme: Theme
    let layout: LayoutController
    let isPlaying: Bool
    let isThemeLocked: Bool  // NEW: Whether theme changes are locked
    let currentTutorialStep: TutorialStep?
    let onThemeTap: () -> Void
    let onMenuTap: () -> Void
    let onTimeTap: () -> Void
    let onButtonFrameChange: ((CGRect) -> Void)?
    let onThemeButtonFrameChange: ((CGRect) -> Void)?
    let onMenuButtonFrameChange: ((CGRect) -> Void)?
    
    init(theme: Theme,
         layout: LayoutController,
         isPlaying: Bool,
         isThemeLocked: Bool = false,  // NEW: Default false
         currentTutorialStep: TutorialStep? = nil,
         onThemeTap: @escaping () -> Void,
         onMenuTap: @escaping () -> Void,
         onTimeTap: @escaping () -> Void,
         onButtonFrameChange: ((CGRect) -> Void)? = nil,
         onThemeButtonFrameChange: ((CGRect) -> Void)? = nil,
         onMenuButtonFrameChange: ((CGRect) -> Void)? = nil) {
        self.theme = theme
        self.layout = layout
        self.isPlaying = isPlaying
        self.isThemeLocked = isThemeLocked  // NEW
        self.currentTutorialStep = currentTutorialStep
        self.onThemeTap = onThemeTap
        self.onMenuTap = onMenuTap
        self.onTimeTap = onTimeTap
        self.onButtonFrameChange = onButtonFrameChange
        self.onThemeButtonFrameChange = onThemeButtonFrameChange
        self.onMenuButtonFrameChange = onMenuButtonFrameChange
    }

    var body: some View {
        HStack {
            // Left: Theme dot button
            Button(action: {
                guard !isThemeLocked else { return }  // Don't respond when locked
                SoundManager.shared.play(.themeChange)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onThemeTap()
            }) {
                Circle()
                    .fill(theme.accent)
                    .frame(width: layout.topBarButtonSize, height: layout.topBarButtonSize)
                    .overlay(
                        Circle()
                            .stroke(Color(white: 0.2).opacity(0.7), lineWidth: layout.topBarButtonStrokeWidth)
                    )
                    .shadow(color: theme.shadow.opacity(0.3), radius: 7, x: 0, y: 2)
                    .contentShape(Circle())
                    .opacity(isThemeLocked ? 0.5 : 1.0)  // Dim when locked
                    .accessibilityLabel("Change theme")
            }
            .disabled(isThemeLocked)  // Disable button when locked
            .animation(.easeInOut(duration: 0.2), value: isThemeLocked)  // Smooth opacity transition
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
            
            Spacer()
            
            // Center: Set Time button
            SetTimeButton(
                theme: theme,
                layout: layout,
                isEnabled: !isPlaying,
                onTap: onTimeTap
            )
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
            
            Spacer()
            
            // Right: Menu button
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
        .padding(.top, layout.topBarPaddingTop)
        .padding(.horizontal, layout.topBarPaddingHorizontal)
    }
}
