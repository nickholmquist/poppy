//
//  StatsRow.swift
//  Poppy
//

import SwiftUI

struct StatsRow: View {
    let theme: Theme
    let layout: LayoutController
    let score: Int
    let remainingSeconds: Int
    let isRunning: Bool
    let onTimeTap: () -> Void
    let scoreBump: Bool
    let highScoreJustBeaten: Bool
    
    @State private var celebrationFlash: Bool = false
    @State private var celebrationPulse: Bool = false
    @State private var urgencyFlash: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .center, spacing: 2) {
                Text("Score")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.9))

                Text("\(score)")
                    .font(.system(size: layout.statsScoreSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(celebrationFlash ? Color(hex: "#FFD700") : theme.textDark)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .scaleEffect(celebrationPulse ? 1.25 : (scoreBump ? 1.06 : 1.0))
                    .animation(.spring(response: 0.22, dampingFraction: 0.6), value: scoreBump)
                    .animation(.spring(response: 0.3, dampingFraction: 0.55), value: celebrationPulse)
                    .shadow(
                        color: celebrationFlash ? Color(hex: "#FFD700").opacity(0.6) : .clear,
                        radius: 12,
                        x: 0,
                        y: 0
                    )
                    .onChange(of: highScoreJustBeaten) { _, beaten in
                        if beaten {
                            triggerCelebration()
                        }
                    }
            }
            .frame(maxWidth: 140, alignment: .leading)

            Spacer()

            VStack(alignment: .center, spacing: 2) {
                Text("Time")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.9))

                Text("\(remainingSeconds)s")
                    .font(.system(size: layout.statsScoreSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        remainingSeconds <= 5 && isRunning
                        ? theme.accent.opacity(urgencyFlash ? 1.0 : 1.0)
                            : theme.textDark
                    )
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .transaction { $0.animation = nil }
                    .contentShape(Rectangle())
                    .onTapGesture { if !isRunning { onTimeTap() } }
                    .onChange(of: remainingSeconds) { _, newVal in
                        if newVal <= 5 && newVal > 0 && isRunning {
                            if !urgencyFlash {
                                startUrgencyBreathing()
                            }
                        } else {
                            stopUrgencyBreathing()
                        }
                    }

                Text("Tap to set")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.85))
                    .opacity(isRunning ? 0 : 1)
                    .allowsHitTesting(!isRunning)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 140, alignment: .trailing)
        }
    }
    
    private func triggerCelebration() {
        withAnimation(.easeOut(duration: 0.15)) {
            celebrationFlash = true
            celebrationPulse = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.4)) {
                celebrationFlash = false
                celebrationPulse = false
            }
        }
    }
    
    private func startUrgencyBreathing() {
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            urgencyFlash = true
        }
    }
    
    private func stopUrgencyBreathing() {
        withAnimation(.easeOut(duration: 0.3)) {
            urgencyFlash = false
        }
    }
}
