//
//  SetTimeButton.swift
//  Poppy
//
//  Pill-shaped button for time selection
//
//  âš ï¸ SIZING: All dimensions come from LayoutController.swift
//  Do not hardcode any sizes, spacing, or dimensions in this file.
//

import SwiftUI

struct SetTimeButton: View {
    let theme: Theme
    let layout: LayoutController
    let isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            if isEnabled {
                SoundManager.shared.play(.pop)
                HapticsManager.shared.light()
                onTap()
            }
        }) {
            Text("Set Time")
                .font(.system(size: layout.setTimeButtonFontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textDark)
                .padding(.horizontal, layout.setTimeButtonPaddingH)
                .padding(.vertical, layout.setTimeButtonPaddingV)
                .background(
                    Capsule()
                        .strokeBorder(theme.textDark.opacity(0.3), lineWidth: layout.setTimeButtonStrokeWidth)
                )
                .opacity(isEnabled ? 1.0 : 0.6)
                .animation(.easeInOut(duration: 0.3), value: isEnabled)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Previews

#Preview("Button States") {
    GeometryReader { geo in
        let layout = LayoutController(geo)
        
        ZStack {
            Color(hex: "#F9F6EC")
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Enabled")
                    .font(.caption)
                SetTimeButton(
                    theme: .daylight,
                    layout: layout,
                    isEnabled: true,
                    onTap: { }
                )
                
                Text("Disabled")
                    .font(.caption)
                SetTimeButton(
                    theme: .daylight,
                    layout: layout,
                    isEnabled: false,
                    onTap: { }
                )
            }
        }
    }
}
