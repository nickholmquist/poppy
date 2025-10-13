import SwiftUI

struct DotSprite: View {
    let theme: Theme
    let isActive: Bool     // lit target
    let isPressed: Bool    // pushed in
    let bounceID: Int      // Trigger for bounce animation

    // Tweakables
    private let glowOpacity: Double = 0.12
    private let glowBlur: CGFloat   = 26
    private let haloOpacity: Double = 0.12
    private let haloBlur: CGFloat   = 10
    private let haloYOffset: CGFloat = -2

    // Inner shadow for pressed
    private let innerDepth: CGFloat = 12   // how far the inner shadow creeps upward
    private let innerBlur: CGFloat  = 14
    private let innerOpacity: Double = 0.45

    // Rim shadow for raised
    private let dropShadowY: CGFloat = -5
    private let dropShadowBlur: CGFloat = 5
    private let dropShadowOpacity: Double = 0.25
    
    // Track tap flash for idle dots
    @State private var showTapGlow = false

    var body: some View {
        ZStack {
            // Soft accent glow for active dots OR when tapped in idle
            Circle()
                .fill(theme.accent)
                .opacity((isActive || showTapGlow) ? (showTapGlow ? 0.25 : glowOpacity) : 0) // Stronger glow on tap
                .blur(radius: glowBlur)
                .animation(.easeInOut(duration: 0.15), value: showTapGlow)

            // Base art - use correct image based on pressed state
            Image(isPressed ? "button_Pressed" : "button_Raised")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
                // Active dots or tap flash: use paperTint
                .if(isActive) { v in
                    v.paperTint(theme.accent, opacity: 0.95, brightness: 0.06)
                }
                // Tap flash for idle dots: strong overlay
                .if(!isActive && showTapGlow) { v in
                    v.overlay(
                        Circle()
                            .fill(theme.accent.opacity(0.6))
                            .blendMode(.normal)
                    )
                }
                // For INACTIVE dots (and not flashing): add a subtle overlay
                .if(!isActive && !showTapGlow) { v in
                    v.overlay(
                        Circle()
                            .fill(theme.accent.opacity(0.15))
                            .blendMode(.multiply)
                    )
                }
                .animation(.easeInOut(duration: 0.15), value: showTapGlow) // Animate the color change
                // Extra polish per state
                .overlay { pressedInnerShadow }
                .shadow(color: .black.opacity(isPressed ? 0 : dropShadowOpacity),
                        radius: dropShadowBlur, x: 0, y: isPressed ? 0 : dropShadowY)
        }
        // Subtle halo so the light feels centered a bit higher - ONLY for raised active dots
        .overlay(
            Circle()
                .stroke(theme.accent.opacity(isActive && !isPressed ? 0.45 : 0.0), lineWidth: 6)
                .blur(radius: 6)
                .offset(y: -1)
                .scaleEffect(isActive && !isPressed ? 1.0 : 0.98)
                .animation(isActive && !isPressed ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .none,
                           value: isActive)
        )
        .compositingGroup() // keeps blend masks tidy
        .modifier(BounceModifier(bounceID: bounceID, isPressed: isPressed))
        .onChange(of: isPressed) { oldValue, newValue in
            // When pressed in idle mode (not active), flash the glow
            print("DEBUG: isPressed changed from \(oldValue) to \(newValue), isActive: \(isActive)")
            if newValue && !isActive {
                print("DEBUG: Setting showTapGlow = true")
                showTapGlow = true
                // Fade out after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    print("DEBUG: Setting showTapGlow = false")
                    showTapGlow = false
                }
            }
        }
        .onChange(of: bounceID) { oldValue, newValue in
            // When bounceID changes in idle mode (not active), flash the glow
            print("DEBUG: bounceID changed from \(oldValue) to \(newValue), isActive: \(isActive)")
            if !isActive && newValue != oldValue {
                print("DEBUG: Setting showTapGlow = true from bounceID")
                showTapGlow = true
                // Fade out after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    print("DEBUG: Setting showTapGlow = false from bounceID")
                    showTapGlow = false
                }
            }
        }
    }

    // MARK: Inner shadow overlay for pressed state
    @ViewBuilder
    private var pressedInnerShadow: some View {
        if isPressed {
            // Two-part inner shadow:
            // 1) A radial bloom that originates just below the circle to
            //    simulate the lower rim darkening
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: .black.opacity(innerOpacity), location: 0.0),
                    .init(color: .black.opacity(innerOpacity * 0.35), location: 0.35),
                    .init(color: .clear, location: 1.0)
                ]),
                center: UnitPoint(x: 0.5, y: 1.12), // below center so it climbs up
                startRadius: 0,
                endRadius: 120
            )
            .blendMode(.multiply)
            .blur(radius: innerBlur)
            .mask(
                Circle()
                    .inset(by: 2) // tuck inside the edge
                    .mask(
                        // Limit effect mostly to the lower half
                        LinearGradient(colors: [.white, .clear],
                                       startPoint: .bottom,
                                       endPoint: .top)
                    )
            )

            // 2) A tight inner rim to sell the bevel at the very bottom edge
            Circle()
                .stroke(.black.opacity(0.35), lineWidth: 2)
                .blur(radius: 2)
                .offset(y: 2) // push the rim toward the bottom
                .blendMode(.multiply)
                .mask(Circle().inset(by: 3))
        }
    }
}

// Separate modifier to handle bounce animation
struct BounceModifier: ViewModifier {
    let bounceID: Int
    let isPressed: Bool
    
    @State private var scale: CGFloat = 1.0
    @State private var lastBounceID: Int = 0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(.default, value: scale) // Add explicit animation
            .onChange(of: bounceID) { oldValue, newValue in
                print("BounceModifier: bounceID changed from \(oldValue) to \(newValue), isPressed: \(isPressed), scale: \(scale)")
                if newValue != lastBounceID && !isPressed {
                    lastBounceID = newValue
                    performBounce()
                }
            }
            .onChange(of: isPressed) { oldValue, newValue in
                if newValue {
                    // Squish down
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 0.85
                        print("Squishing to 0.85")
                    }
                } else if oldValue && !newValue {
                    // Bounce up when released
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        performBounce()
                    }
                }
            }
    }
    
    private func performBounce() {
        print("performBounce() START - scale: \(scale)")
        scale = 1.15
        print("performBounce() SET to 1.15 - scale: \(scale)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            scale = 1.0
            print("performBounce() SETTLE to 1.0 - scale: \(scale)")
        }
    }
}

// Small convenience so the conditional read is clean
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool,
                             transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}
