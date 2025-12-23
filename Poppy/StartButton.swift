//
//  StartButton.swift
//  Poppy
//
//  Large action button with layered design
//
//  ⚠️ SIZING: All dimensions come from LayoutController.swift
//  Do not hardcode any sizes, spacing, or dimensions in this file.
//

import SwiftUI

struct StartButton: View {
    let theme: Theme
    let layout: LayoutController
    let title: String
    var textColor: Color = Theme.daylight.textDark
    let action: () -> Void
    var isDisabled: Bool = false

    @State private var isPressed = false
    @State private var glowOpacity: Double = 0.0
    @State private var scale: CGFloat = 1.0
    
    private var isIdleStart: Bool {
        title == "START"
    }
    
    private var currentTint: Color {
        if isVisuallyPressed {
            return theme.accent.darker(by: 0.05)
        } else {
            return theme.accent
        }
    }
    
    private var buttonWidth: CGFloat {
        layout.startButtonWidth * 0.84  // Middle ground between full width and 68%
    }
    
    private var isVisuallyPressed: Bool {
        isPressed || isDisabled
    }

    var body: some View {
        ZStack {
            // ------------------------------------------------
            // 1. BOTTOM LAYER (Static Base)
            // ------------------------------------------------
            RoundedRectangle(cornerRadius: layout.startButtonCornerRadius, style: .continuous)
                .fill(Color(hex: "#7d7d7d"))
                .paperTint(theme.accent, opacity: 0.95, brightness: 0.06)
                .overlay(
                    RoundedRectangle(cornerRadius: layout.startButtonCornerRadius, style: .continuous)
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(
                    width: buttonWidth,
                    height: layout.startButtonHeight
                )
            
            // ------------------------------------------------
            // 2. TOP LAYER (The Moving Surface)
            // ------------------------------------------------
            ZStack {
                // A. Fill + Tint
                RoundedRectangle(cornerRadius: layout.startButtonCornerRadius, style: .continuous)
                    .fill(Color(hex: "#d7d7d7"))
                    .paperTint(currentTint, opacity: 1.0, brightness: 0.06)
                
                // B. Text (Middle)
                Text(title)
                    .font(.system(size: layout.startButtonTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor.opacity(isDisabled ? 0.5 : 1.0))
                    .shadow(color: .white.opacity(0.35), radius: 0.5, x: 0, y: 0)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 12)
                    .id(title)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
                
                // C. Border (Top)
                RoundedRectangle(cornerRadius: layout.startButtonCornerRadius, style: .continuous)
                    .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
            }
            .frame(
                width: buttonWidth,
                height: layout.startButtonHeight
            )
            .clipShape(RoundedRectangle(cornerRadius: layout.startButtonCornerRadius, style: .continuous))
            .drawingGroup()
            .offset(y: isVisuallyPressed ? 0 : -layout.startButtonLayerOffset)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isVisuallyPressed)
        }
        // ------------------------------------------------
        // 3. INTERACTION LOGIC & ANIMATIONS
        // ------------------------------------------------
        .scaleEffect(scale) // Bounce Scale applied here
        .contentShape(Rectangle())
        .accessibilityAddTraits(.isButton)
        .background {
            if isIdleStart {
                RoundedRectangle(cornerRadius: layout.startButtonCornerRadius, style: .continuous)
                    .fill(theme.accent)
                    .opacity(glowOpacity)
                    .blur(radius: layout.startButtonGlowRadius)
                    .scaleEffect(1.05)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed && !isDisabled {
                        isPressed = true
                        HapticsManager.shared.medium()
                        // NOTE: Removed the scale animation here.
                        // It will now purely "slide" down via the .offset modifier above.
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        action()
                        isPressed = false
                        
                        // Bounce ONLY on release (pop up)
                        if !isDisabled {
                            performPopBounce()
                        }
                    }
                }
        )
        .onChange(of: isDisabled) { _, disabled in
            // Bounce when the button unlocks (pops up)
            if !disabled {
                performPopBounce()
            }
        }
        .onAppear {
            if isIdleStart { startInvitationPulse() }
        }
        .onChange(of: title) { _, newTitle in
            if newTitle == "START" {
                startInvitationPulse()
            } else {
                stopInvitationPulse()
            }
        }
    }
    
    // NEW: Tuned for "Subtle" Bounce
    private func performPopBounce() {
        // 1. Very slight compression (Anticipation)
        withAnimation(.spring(response: 0.1, dampingFraction: 0.8)) {
            scale = 0.98 // Was 0.94 - now barely noticeable
        }
        
        // 2. Subtle Pop Overshoot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.interpolatingSpring(mass: 0.3, stiffness: 300, damping: 15)) {
                scale = 1.03 // Was 1.10 - just a 3% pop
            }
        }
        
        // 3. Settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
    }
    
    private func startInvitationPulse() {
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = layout.startButtonGlowOpacity
        }
    }
    
    private func stopInvitationPulse() {
        withAnimation(.easeOut(duration: 0.3)) {
            glowOpacity = 0.0
        }
    }
}

