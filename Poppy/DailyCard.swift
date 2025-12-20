//
//  DailyCard.swift
//  Poppy
//
//  Daily mode info card - replaces scoreboard when Daily is selected
//  Shows date, streak, duration, and completion status
//

import SwiftUI

struct DailyCard: View {
    let theme: Theme
    let layout: LayoutController
    @ObservedObject var highs: HighscoreStore
    let isRunning: Bool

    // Today's daily info
    private var todayDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: Date())
    }

    private var todayDuration: Int {
        HighscoreStore.dailyDurationForToday()
    }

    private var hasPlayed: Bool {
        highs.hasPlayedDailyToday()
    }

    private var streak: Int {
        highs.dailyStreak
    }

    // Card dimensions
    private var cardWidth: CGFloat {
        layout.scoreboardExpandedWidth
    }

    private var cardHeight: CGFloat {
        layout.unit * 18
    }

    private var cornerRadius: CGFloat {
        layout.scoreboardCornerRadius
    }

    // Icon color - matches textOnAccent for good contrast on all themes
    private var iconColor: Color {
        theme.textOnAccent.opacity(0.6)
    }

    var body: some View {
        ZStack {
            // Single layer card (no 3D effect)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(theme.accent)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(width: cardWidth, height: cardHeight)

            // Content
            VStack(spacing: 10) {
                // Date - title size
                Text(todayDateFormatted)
                    .font(.system(size: layout.scoreboardTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent)

                // Today's Goal
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: layout.baseText * 1.1, weight: .semibold))
                        .foregroundStyle(iconColor)
                    Text("Today's Goal: \(todayDuration)s")
                        .font(.system(size: layout.baseText, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent.opacity(0.8))
                }

                // Completion status and Streak row
                HStack(spacing: 16) {
                    // Completion status
                    HStack(spacing: 6) {
                        Image(systemName: hasPlayed ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: layout.baseText * 1.2, weight: .semibold))
                            .foregroundStyle(iconColor)

                        Text(hasPlayed ? "Completed" : "Not played")
                            .font(.system(size: layout.baseText * 0.9, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent.opacity(hasPlayed ? 0.8 : 0.5))
                    }

                    // Streak
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: layout.baseText * 1.1, weight: .semibold))
                            .foregroundStyle(iconColor)
                        Text("\(streak) day\(streak == 1 ? "" : "s")")
                            .font(.system(size: layout.baseText, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent.opacity(0.8))
                    }
                }
                .padding(.top, 4)
            }
            .frame(width: cardWidth, height: cardHeight)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .opacity(isRunning ? 0.5 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isRunning)
    }
}

#Preview("Daily Card - Not Played") {
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()

        GeometryReader { geo in
            let layout = LayoutController(geo)

            DailyCard(
                theme: .daylight,
                layout: layout,
                highs: HighscoreStore(),
                isRunning: false
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 100)
        }
    }
}

#Preview("Daily Card - Completed") {
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()

        GeometryReader { geo in
            let layout = LayoutController(geo)
            let store = HighscoreStore()

            DailyCard(
                theme: .daylight,
                layout: layout,
                highs: store,
                isRunning: false
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 100)
            .onAppear {
                // Simulate played today
                store.registerDailyScore(42)
            }
        }
    }
}
