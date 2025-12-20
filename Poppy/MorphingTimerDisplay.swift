//
//  MorphingTimerDisplay.swift
//  Poppy
//
//  Simple progress bar timer display
//  Always in expanded bar form - no more morphing to ring
//
//  ⚠️ SIZING: All dimensions come from LayoutController.swift
//  Do not hardcode any sizes, spacing, or dimensions in this file.
//

import SwiftUI

struct MorphingTimerDisplay: View {
    let theme: Theme
    let layout: LayoutController
    let progress: Double       // 0.0 (empty) to 1.0 (full)
    let isExpanded: Bool       // Kept for compatibility but always shows bar
    let isUrgent: Bool         // true when <5 seconds

    @State private var pulseOpacity: CGFloat = 1.0

    private var barColor: Color {
        if isUrgent {
            return Color(hex: "#FF6B6B")  // Red when urgent
        }
        return theme.accent
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: layout.progressBarHeight / 2, style: .continuous)
                    .fill(theme.textDark.opacity(0.15))

                // Progress fill
                RoundedRectangle(cornerRadius: layout.progressBarHeight / 2, style: .continuous)
                    .fill(barColor)
                    .frame(width: max(0, geo.size.width * progress))
                    .opacity(isUrgent ? pulseOpacity : 1.0)
            }
        }
        .frame(width: layout.progressBarWidth, height: layout.progressBarHeight)
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
            .easeInOut(duration: 0.5)
            .repeatForever(autoreverses: true)
        ) {
            pulseOpacity = 0.6
        }
    }

    private func stopUrgencyPulse() {
        withAnimation(.easeOut(duration: 0.2)) {
            pulseOpacity = 1.0
        }
    }
}

// MARK: - Previews

#Preview("Progress Bar") {
    struct ProgressTest: View {
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
                            isExpanded: true,
                            isUrgent: false
                        )

                        VStack(spacing: 16) {
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

    return ProgressTest()
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
                isExpanded: true,
                isUrgent: true
            )
        }
    }
}
