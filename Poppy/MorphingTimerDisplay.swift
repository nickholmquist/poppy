//
//  MorphingTimerDisplay.swift
//  Poppy
//
//  Timer display with smooth morphing animation from bar to ring
//
//  ⚠️ SIZING: All dimensions come from LayoutController.swift
//  Do not hardcode any sizes, spacing, or dimensions in this file.
//

import SwiftUI

struct MorphingTimerDisplay: View {
    let theme: Theme
    let layout: LayoutController
    let progress: Double       // 0.0 (empty) to 1.0 (full)
    let isExpanded: Bool       // true = bar, false = ring
    let isUrgent: Bool         // true when <5 seconds
    
    @State private var glowIntensity: CGFloat = 1.0
    
    // Compute morph amount: 0.0 = bar (expanded), 1.0 = ring (collapsed)
    private var morphProgress: CGFloat {
        isExpanded ? 0.0 : 1.0
    }
    
    var body: some View {
        ZStack {
            // Glow effect when urgent (only visible in ring mode)
            if isUrgent && !isExpanded {
                MorphingTimerShape(morphProgress: 1.0)
                    .trim(from: 0, to: progress)
                    .stroke(
                        theme.accent,
                        style: StrokeStyle(
                            lineWidth: layout.ringStrokeWidth,
                            lineCap: .round
                        )
                    )
                    .blur(radius: 12 * glowIntensity)
                    .opacity(0.6 * glowIntensity)
            }
            
            // Main morphing timer
            MorphingTimerShape(morphProgress: morphProgress)
                .trim(from: 0, to: progress)
                .stroke(
                    theme.accent,
                    style: StrokeStyle(
                        lineWidth: isExpanded ? layout.progressBarHeight : layout.ringStrokeWidth,
                        lineCap: .round
                    )
                )
                // SMOOTH easeInOut animation - NO SPRING BOUNCE
                .animation(.easeInOut(duration: 0.5), value: morphProgress)
        }
        .frame(
            width: isExpanded ? layout.progressBarWidth : layout.ringDiameter,
            height: isExpanded ? layout.progressBarHeight : layout.ringDiameter
        )
        .onChange(of: isUrgent) { _, urgent in
            if urgent {
                startUrgencyPulse()
            } else {
                stopUrgencyPulse()
            }
        }
        .onAppear {
            if isUrgent {
                startUrgencyPulse()
            }
        }
    }
    
    // MARK: - Urgency Pulse
    
    private func startUrgencyPulse() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 1.5
        }
    }
    
    private func stopUrgencyPulse() {
        withAnimation(.easeOut(duration: 0.3)) {
            glowIntensity = 1.0
        }
    }
}

// MARK: - Previews

#Preview("Morphing Animation") {
    struct MorphTest: View {
        @State private var isExpanded = true
        @State private var progress: Double = 0.6
        
        var body: some View {
            GeometryReader { geo in
                let layout = LayoutController(geo)
                
                ZStack {
                    Color(hex: "#F9F6EC")
                        .ignoresSafeArea()
                    
                    VStack(spacing: 40) {
                        MorphingTimerDisplay(
                            theme: .daylight,
                            layout: layout,
                            progress: progress,
                            isExpanded: isExpanded,
                            isUrgent: false
                        )
                        
                        VStack(spacing: 16) {
                            Button("Toggle Shape") {
                                withAnimation {
                                    isExpanded.toggle()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            HStack {
                                Text("Progress:")
                                Slider(value: $progress, in: 0...1)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
    
    return MorphTest()
}

#Preview("Urgent State") {
    GeometryReader { geo in
        let layout = LayoutController(geo)
        
        ZStack {
            Color(hex: "#F9F6EC")
                .ignoresSafeArea()
            
            MorphingTimerDisplay(
                theme: .daylight,
                layout: layout,
                progress: 0.15,
                isExpanded: false,
                isUrgent: true
            )
        }
    }
}
