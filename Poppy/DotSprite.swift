// DotSprite.swift
import SwiftUI

struct DotSprite: View {
    let theme: Theme
    let isActive: Bool     // lit target
    let isPressed: Bool    // pushed in
    let bounceID: Int      // Trigger for bounce animation
    let idleFlashID: Int   // Trigger for idle tap flash - NEW

    // Tweakables
    private let glowOpacity: Double = 0.12
    private let glowBlur: CGFloat   = 26

    // Inner shadow for pressed - follows the bottom rim curve
    private let innerOpacity: Double = 0.45
    private let innerOffsetY: CGFloat = 8
    private let innerBlur: CGFloat = 4

    // Ground contact shadow - tight to the base, no vertical offset
    private let groundShadowBlur: CGFloat = 4
    private let groundShadowOpacity: Double = 0.30
    
    // Baseline alignment - pressed buttons need to sit lower to match raised buttons' rim
    private let pressedBaselineOffset: CGFloat = 5
    
    // Tint opacity states
    private let activeTintOpacity: Double = 0.95
    private let inactiveTintOpacity: Double = 0.20
    
    // Idle state tracking for color flash
    @State private var currentTintOpacity: Double = 0.15
    
    // Breathing animation state
    @State private var breathingIntensity: Double = 0.0
    @State private var breathingDelay: Double = 0.0
    
    // Idle tap flash - NEW
    @State private var idleFlash: Bool = false

    var body: some View {
        ZStack {
            // Soft accent glow only when active AND not pressed
            // Now pulses with breathing animation
            Circle()
                .fill(theme.accent)
                .opacity(isActive && !isPressed ? (glowOpacity + breathingIntensity * 0.08) : 0)
                .blur(radius: glowBlur)

            // Base art - ALWAYS full opacity
            Image(isPressed ? "button_Pressed" : "button_Raised")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                // Pressed inner shadow polish
                .overlay { pressedInnerShadow }
                // Accent tint OVERLAY - masked to button shape
                .overlay {
                    if !isPressed {
                        Image(isPressed ? "button_Pressed" : "button_Raised")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(theme.accent)
                            .opacity(idleFlash ? 0.7 : currentTintOpacity)  // Flash on idle tap
                            .blendMode(.multiply)
                    }
                }
        }
        // Offset pressed buttons down to align with raised buttons' baseline
        .offset(y: isPressed ? pressedBaselineOffset : 0)
        // bounce scale and tint management
        .modifier(BounceModifier(
            bounceID: bounceID,
            isPressed: isPressed,
            isActive: isActive,
            currentTintOpacity: $currentTintOpacity,
            activeTintOpacity: activeTintOpacity,
            inactiveTintOpacity: inactiveTintOpacity
        ))
        .onAppear {
            // Random delay so dots don't sync
            breathingDelay = Double.random(in: 0...3.5)
            startBreathing()
        }
        .onChange(of: isActive) { _, active in
            if active {
                // Restart breathing when becoming active
                startBreathing()
            }
        }
        .onChange(of: idleFlashID) { oldVal, newVal in
            // Trigger flash when idleFlashID changes (idle tap detected)
            if newVal != oldVal && !isActive && !isPressed {
                triggerIdleFlash()
            }
        }
    }

    // MARK: Inner shadow overlay for pressed state
    @ViewBuilder
    private var pressedInnerShadow: some View {
        if isPressed {
            // Bottom rim shadow - follows the curve at the bottom edge
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.35),
                            Color.black.opacity(0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(maxHeight: 15)
                .offset(y: 18)  // Position at the very bottom
                .blur(radius: 3)
                .clipShape(Circle())
                .blendMode(.multiply)
        }
    }
    
    // MARK: Breathing Animation
    private func startBreathing() {
        // Wait for random delay, then start infinite breathing
        DispatchQueue.main.asyncAfter(deadline: .now() + breathingDelay) {
            withAnimation(
                .easeInOut(duration: 3.5)
                .repeatForever(autoreverses: true)
            ) {
                breathingIntensity = 1.0
            }
        }
    }
    
    // MARK: Idle Flash Animation
    private func triggerIdleFlash() {
        // Quick accent flash
        withAnimation(.easeOut(duration: 0.15)) {
            idleFlash = true
        }
        
        // Fade back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.3)) {
                idleFlash = false
            }
        }
    }
}

// MARK: - Bounce and tint management
private struct BounceModifier: ViewModifier {
    let bounceID: Int
    let isPressed: Bool
    let isActive: Bool
    @Binding var currentTintOpacity: Double
    let activeTintOpacity: Double
    let inactiveTintOpacity: Double
    
    @State private var scale: CGFloat = 1.0
    @State private var lastBounceID: Int = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                // Set initial tint opacity based on state
                currentTintOpacity = isActive ? activeTintOpacity : inactiveTintOpacity
            }
            .onChange(of: isActive) { _, newActive in
                // Only update tint if button is not in a pressed transition
                if !isPressed {
                    currentTintOpacity = newActive ? activeTintOpacity : inactiveTintOpacity
                }
            }
            .onChange(of: isPressed) { oldVal, newVal in
                // When unpressing, set the tint to match the new active state
                if oldVal && !newVal {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        currentTintOpacity = isActive ? activeTintOpacity : inactiveTintOpacity
                    }
                }
            }
            .onChange(of: bounceID) { _, newVal in
                if newVal != lastBounceID && !isPressed {
                    lastBounceID = newVal
                    performPopBounce()
                    // No tint flash here - bounceAll and bounceIndividual are combined
                    // so we can't distinguish idle taps from POP
                }
            }
            .onChange(of: isPressed) { oldVal, newVal in
                if newVal {
                    // Press down
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 0.85
                    }
                } else if oldVal && !newVal {
                    // Release - quick bounce back
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        performPopBounce()
                    }
                    
                    // After releasing, smoothly transition tint to match active state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        currentTintOpacity = isActive ? activeTintOpacity : inactiveTintOpacity
                    }
                }
            }
    }

    private func performPopBounce() {
        // Stage 1: Compress slightly (like loading a spring)
        withAnimation(.spring(response: 0.12, dampingFraction: 0.8)) {
            scale = 0.94
        }
        
        // Stage 2: Pop up with moderate overshoot
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.interpolatingSpring(mass: 0.45, stiffness: 280, damping: 13)) {
                scale = 1.10
            }
        }
        
        // Stage 3: Settle back with gentle bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.spring(response: 0.40, dampingFraction: 0.70)) {
                scale = 1.0
            }
        }
    }
}

// Small convenience
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                             transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
