//
//  TopBar.swift
//  Poppy
//

import SwiftUI

struct TopBar: View {
    let theme: Theme
    let layout: LayoutController
    let onThemeTap: () -> Void
    let onMenuTap: () -> Void

    var body: some View {
        ZStack {
            HStack {
                Button(action: {
                    SoundManager.shared.play(.themeChange)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onThemeTap()
                }) {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .stroke(Color(white: 0.2).opacity(0.7), lineWidth: 2.5)
                        )
                        .shadow(color: theme.shadow.opacity(0.3), radius: 7, x: 0, y: 2)
                        .contentShape(Circle())
                        .accessibilityLabel("Change theme")
                }
                
                Spacer()
                
                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onMenuTap()
                }) {
                    Circle()
                        .fill(theme.textDark.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .shadow(color: theme.shadow.opacity(0.3), radius: 7, x: 0, y: 2)
                        .contentShape(Circle())
                        .accessibilityLabel("Open menu")
                }
            }

            Text("Poppy")
                .font(.system(size: layout.topBarTitleSize, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.textDark)
        }
        .padding(.top, layout.topBarPaddingTop)
        .padding(.horizontal, layout.topBarPaddingHorizontal)
        .zIndex(5)
    }
}
