//
//  DotSprite.swift
//  Poppy
//
//  Individual dot button with layered design and animations
//
//  SIZING: All dimensions come from LayoutController.swift
//  Do not hardcode any sizes, spacing, or dimensions in this file.
//

import SwiftUI

struct DotSprite: View {
    let theme: Theme
    let layout: LayoutController
    let isActive: Bool     // lit target
    let isPressed: Bool    // pushed in
    let bounceID: Int      // Trigger for bounce animation
    let idleFlashID: Int   // Trigger for idle tap flash
    var matchyColorHex: String? = nil  // Matchy mode color (nil = not in matchy or face-down)
    var matchySymbol: String? = nil    // Matchy mode symbol (nil = not in matchy or face-down)
    var seekyBaseColor: Color? = nil   // Seeky mode color override (nil = use theme accent)

    // Breathing animation state
    @State private var breathingIntensity: Double = 0.0
    @State private var breathingDelay: Double = 0.0
    
    // Idle tap flash
    @State private var idleFlash: Bool = false
    
    // Dynamic spacing - press down when tapped
    private var currentSpacing: CGFloat {
        isPressed ? 0 : -layout.dotLayerOffset
    }

    // The accent color to use (seekyBaseColor overrides theme.accent for Seeky mode)
    private var accentColor: Color {
        seekyBaseColor ?? theme.accent
    }

    // Determine dot fill color based on state
    private var dotFillColor: Color {
        // Matchy mode: show color if revealed, otherwise neutral grey
        if let hex = matchyColorHex {
            return Color(hex: hex)
        }

        // Normal modes
        if isPressed {
            return Color(hex: "#909090")  // Pressed: noticeably darker grey
        }
        if isActive {
            return accentColor  // Active: full bright accent (or Seeky color)
        }
        if idleFlash {
            return accentColor.darker(by: 0.05)  // Idle flash: slightly darker (matches pressed UI elements)
        }
        return Color(hex: "#d7d7d7")  // Inactive: light grey
    }

    var body: some View {
        GeometryReader { geo in
            let dotSize = geo.size.width - (layout.dotPadding * 2)
            let radius = dotSize / 2
            let spacing = abs(currentSpacing)
            
            ZStack {
                // Soft accent glow only when active AND not pressed
                Circle()
                    .fill(accentColor)
                    .opacity(isActive && !isPressed ? (layout.dotGlowOpacity + breathingIntensity * 0.08) : 0)
                    .blur(radius: layout.dotGlowRadius)
                    .padding(layout.dotPadding)

                // Bottom circle (darker) - shows accent tint ONLY when active
                Circle()
                    .fill(isActive ?
                          Color(hex: "#656565") :   // We'll overlay accent on top
                          Color(hex: "#7d7d7d"))    // Inactive: grey
                    .overlay(
                        // Active overlay - creates darker tinted shadow
                        Group {
                            if isActive {
                                Circle()
                                    .fill(accentColor)
                                    .opacity(0.4)  // Subtle tint over dark grey base
                            }
                        }
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )
                    .shadow(color: theme.shadow.opacity(0.25), radius: 4, x: 0, y: 2)
                    .padding(layout.dotPadding)
                
                // Cylinder side lines - connect top and bottom circles
                if spacing > 0.5 {  // Only show when dot is raised
                    // Scale inset values relative to dot size for iPad compatibility
                    let baseInset: CGFloat = layout.dotStrokeWidth
                    let additionalInset: CGFloat = dotSize * 0.06  // 6% of dot size for extra safety
                    let lineInset = baseInset + additionalInset
                    
                    // Horizontal positioning - scale with dot size
                    let horizontalAdjust: CGFloat = dotSize * 0.015
                    
                    // Calculate line height with proper insets
                    let lineHeight = max(0, spacing - (lineInset * 2))
                    
                    // Only render if line height is meaningful
                    if lineHeight > 0.5 {
                        // Left vertical line - using Rectangle for clean rendering
                        Rectangle()
                            .fill(Color(hex: "#3a3a3a"))
                            .frame(width: layout.dotStrokeWidth, height: lineHeight)
                            .position(
                                x: layout.dotPadding - horizontalAdjust,
                                y: radius + layout.dotPadding + lineInset + (lineHeight / 2)
                            )
                        
                        // Right vertical line - using Rectangle for clean rendering
                        Rectangle()
                            .fill(Color(hex: "#3a3a3a"))
                            .frame(width: layout.dotStrokeWidth, height: lineHeight)
                            .position(
                                x: dotSize + layout.dotPadding - horizontalAdjust,
                                y: radius + layout.dotPadding + lineInset + (lineHeight / 2)
                            )
                    }
                }
                
                // Top circle (lighter) - shows active/inactive/pressed states clearly
                Circle()
                    .fill(dotFillColor)
                    .animation(.easeInOut(duration: 0.2), value: matchyColorHex)
                    .overlay(
                        // Matchy symbol overlay
                        Group {
                            if let symbol = matchySymbol {
                                Image(systemName: symbol)
                                    .font(.system(size: dotSize * 0.38, weight: .bold))
                                    .foregroundStyle(Color(hex: "#3a3a3a").opacity(0.5))
                            }
                        }
                    )
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )
                    .padding(layout.dotPadding)
                    .offset(y: currentSpacing)
                    .animation(.easeOut(duration: 0.09), value: currentSpacing)
            }
        }
        // bounce scale management
        .modifier(BounceModifier(
            layout: layout,
            bounceID: bounceID,
            isPressed: isPressed,
            isActive: isActive
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

// MARK: - Bounce management
private struct BounceModifier: ViewModifier {
    let layout: LayoutController
    let bounceID: Int
    let isPressed: Bool
    let isActive: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastBounceID: Int = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: bounceID) { _, newVal in
                if newVal != lastBounceID && !isPressed {
                    lastBounceID = newVal
                    performPopBounce()
                }
            }
            .onChange(of: isPressed) { oldVal, newVal in
                if !newVal && oldVal {
                    // Release - bounce back after slight delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        performPopBounce()
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
