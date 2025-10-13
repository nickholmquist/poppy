//
//  TopBar.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/9/25.
//

import SwiftUI

struct TopBar: View {
    let theme: Theme
    let compact: Bool
    let onThemeTap: () -> Void

    var body: some View {
        ZStack {
            HStack {
                Button(action: {
                    // Haptic feedback on tap
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
            }

            Text("Poppy")
                .font(.system(size: compact ? 34 : 30, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.textDark)
        }
        .padding(.top, compact ? 4 : 0)
        .padding(.horizontal, 30)
        .zIndex(5)
    }
}
