//
//  ThemeTransitionOverlay.swift
//  Poppy
//
//  Watercolor theme transition mask
//

import SwiftUI
import CoreHaptics

struct ThemeTransitionMask: View {
    @Binding var isAnimating: Bool
    
    @State private var progress: CGFloat = 0
    @State private var hapticEngine: CHHapticEngine?
    
    var body: some View {
        GeometryReader { geo in
            // Circular wipe mask that expands from theme dot position
            Circle()
                .scale(progress * 15.0) // Large enough to cover entire screen
                .blur(radius: 40)  // Tighter transition edge for more dramatic wipe
                .offset(
                    x: 50 - geo.size.width / 2,  // Position at theme dot (top-left)
                    y: 50 - geo.size.height / 2
                )
        }
        .onAppear {
            // Setup haptic engine and trigger pattern
            setupHaptics()
            triggerSparkleHaptics()
            
            withAnimation(.easeOut(duration: 15.0)) {  // Fixed from 10.0 to 1.0 second
                progress = 2.5
            }
            
            // Clean up after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isAnimating = false
            }
        }
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("Haptic engine creation error: \(error)")
        }
    }
    
    private func triggerSparkleHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events: [CHHapticEvent] = []
        
        // 12 transient pulses - starts strong, trails off softly like magic dissipating
        let timings: [Double] = [0.0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5, 0.55]
        let intensities: [Float] = [0.6, 0.55, 0.5, 0.45, 0.4, 0.35, 0.3, 0.25, 0.2, 0.15, 0.1, 0.05]
        let sharpness: Float = 0.4 // Consistent softness
        
        for i in 0..<12 {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensities[i]),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: timings[i]
            )
            events.append(event)
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
}

// Helper extension to calculate diagonal distance
extension CGSize {
    var diagonal: CGFloat {
        sqrt(width * width + height * height)
    }
}
