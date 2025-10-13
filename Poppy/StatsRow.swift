//
//  StatsRow.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/9/25.
//


import SwiftUI

struct StatsRow: View {
    let theme: Theme
    let compact: Bool
    let score: Int
    let remainingSeconds: Int
    let isRunning: Bool
    let onTimeTap: () -> Void
    let scoreBump: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .center, spacing: 2) {
                Text("Score")
                    .font(.headline)
                    .foregroundStyle(theme.textDark.opacity(0.9))

                Text("\(score)")
                    .font(.system(size: compact ? 36 : 35, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.textDark)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .scaleEffect(scoreBump ? 1.06 : 1.0)
                    .animation(.spring(response: 0.22, dampingFraction: 0.6), value: scoreBump)
            }
            .frame(maxWidth: 140, alignment: .leading)

            Spacer()

            VStack(alignment: .center, spacing: 2) {
                Text("Time")
                    .font(.headline)
                    .foregroundStyle(theme.textDark.opacity(0.9))

                Text("\(remainingSeconds)s")
                    .font(.system(size: compact ? 36 : 35, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.textDark)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .transaction { $0.animation = nil }
                    .contentShape(Rectangle())
                    .onTapGesture { if !isRunning { onTimeTap() } }

                Text("Tap to set")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.85))
                    .opacity(isRunning ? 0 : 1)
                    .allowsHitTesting(!isRunning)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 140, alignment: .trailing)
        }
    }
}
