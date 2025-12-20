//
//  CountdownOverlay.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/9/25.
//


import SwiftUI

struct CountdownOverlay: View {
    let theme: Theme
    let count: Int
    
    var body: some View {
        ZStack {
            theme.bgBottom.opacity(0.75).ignoresSafeArea()
            Text("\(count)")
                .font(.system(size: 120, weight: .black, design: .rounded))
                .kerning(-2)
                .foregroundStyle(theme.text)  // Changed from theme.textOnAccent
                .shadow(color: .black.opacity(0.35), radius: 4, x: 0, y: 2)
        }
        .onAppear {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        .onChange(of: count) { _, _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

struct GameOverOverlay: View {
    let theme: Theme
    let onOK: () -> Void
    var isPerfectMatchy: Bool = false
    var copyRound: Int? = nil  // If set, shows "You reached Round X!"

    var body: some View {
        ZStack {
            theme.accent.opacity(0.95).ignoresSafeArea()
            VStack {
                Spacer(minLength: 0)

                if isPerfectMatchy {
                    // Perfect round celebration
                    Text("PERFECT!")
                        .font(.system(size: 56, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color(hex: "#FFD700"))  // Gold
                        .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 2)
                        .shadow(color: Color(hex: "#FFD700").opacity(0.5), radius: 16, x: 0, y: 0)

                    Text("No mistakes!")
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent.opacity(0.9))
                        .padding(.top, 8)
                } else {
                    Text("Game Over")
                        .font(.system(size: 60, weight: .heavy, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.textOnAccent)
                        .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 2)
                        .shadow(color: .white.opacity(0.22), radius: 2, x: 0, y: 0)

                    // Copy mode round reached
                    if let round = copyRound {
                        Text("You reached Round \(round)!")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textOnAccent.opacity(0.85))
                            .padding(.top, 12)
                    }
                }

                Spacer()
                ThemedButton(
                    title: "OK",
                    action: onOK,
                    prominent: false,
                    theme: theme,
                    fill: theme.textOnAccent,
                    textColor: .white,
                    height: 90,
                    corner: 20,
                    font: .system(size: 35, weight: .black, design: .rounded)
                )
                .shadow(color: .black.opacity(0.1), radius: 6, y: 2)
                .frame(maxWidth: 300)
                .padding(.bottom, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 28)
        }
        .transition(.opacity)
    }
}

struct EndCardOverlay: View {
    let theme: Theme
    @Binding var show: Bool
    let score: Int
    let isNewHigh: Bool
    let endCardLocked: Bool
    let onOK: () -> Void
    let showConfetti: Bool

    var body: some View {
        ZStack {
            theme.bgBottom.opacity(0.65).ignoresSafeArea()

            ThemedCard(theme: theme) {
                VStack(spacing: 14) {
                    HStack(spacing: 10) {
                        Text("Time's up")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(theme.text)
                        if isNewHigh {
                            NewHighBadge()
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    Text("Score: \(score)")
                        .font(.title2)
                        .foregroundStyle(theme.text)
                    ThemedButton(title: "OK", action: {
                        show = false
                        onOK()
                    }, prominent: true, theme: theme)
                    .disabled(endCardLocked)
                    .opacity(endCardLocked ? 0.6 : 1.0)
                }
            }
            .opacity(0.9)
            .frame(maxWidth: 300)
            .padding(.horizontal, 28)

            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .compositingGroup() 
                    .transition(.opacity)
            }
        }
        .transition(.opacity)
    }
}

struct DailyCompletedOverlay: View {
    let theme: Theme
    let score: Int
    var streak: Int = 0

    // Green color matching Matchy confirm button
    private let completedGreen = Color(hex: "#5DBB63")

    // For rendering shareable image
    @State private var showShareSheet = false

    // Today's date for sharing
    private var todayFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            // Main card content
            cardContent
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(theme.bgTop)
                        .shadow(color: theme.shadow.opacity(0.25), radius: 15, y: 6)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(theme.textDark.opacity(0.1), lineWidth: 2)
                )
                .overlay(alignment: .topLeading) {
                    // Share button - top left
                    Button(action: shareScore) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.textDark.opacity(0.5))
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .offset(x: 4, y: 4)
                }
                .overlay(alignment: .topTrailing) {
                    // Game Center button - top right
                    Button(action: {
                        HapticsManager.shared.light()
                        GameCenterManager.shared.showDailyLeaderboard()
                    }) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.textDark.opacity(0.5))
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .offset(x: -4, y: 4)
                }
        }
    }

    private var cardContent: some View {
        VStack(spacing: 12) {
            // Checkmark badge
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(completedGreen)

            // Score
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(theme.textDark)
                Text("points")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.6))
            }

            // Streak (if any)
            if streak > 0 {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: "#FF6B35"))
                    Text("\(streak) day streak!")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textDark.opacity(0.85))
                }
                .padding(.top, 4)
            }

            // Come back message
            Text("Come back tomorrow!")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.accent)
                .padding(.top, 8)
        }
    }

    // Shareable card with branding
    @MainActor
    private var shareableCard: some View {
        VStack(spacing: 16) {
            // Date header
            Text(todayFormatted)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textDark.opacity(0.6))
                .textCase(.uppercase)
                .tracking(1)

            // Main content (without "come back tomorrow")
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(completedGreen)

                VStack(spacing: 4) {
                    Text("\(score)")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(theme.textDark)
                    Text("points")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textDark.opacity(0.6))
                }

                if streak > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(hex: "#FF6B35"))
                        Text("\(streak) day streak!")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textDark.opacity(0.85))
                    }
                }
            }

            // Branding
            Text("The Daily Poppy")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(theme.accent)
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.bgTop)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(theme.textDark.opacity(0.15), lineWidth: 2)
        )
    }

    @MainActor
    private func shareScore() {
        HapticsManager.shared.light()
        SoundManager.shared.play(.pop)

        // Render the shareable card as an image
        let renderer = ImageRenderer(content: shareableCard)
        renderer.scale = 3.0 // High resolution

        guard let image = renderer.uiImage else { return }

        // Create share message with Universal Link
        let shareText = "I scored \(score) on The Daily Poppy! \(streak > 1 ? "🔥 \(streak) day streak! " : "")Can you beat me?\n\nhttps://islandtwigstudios.com/poppy"

        let activityVC = UIActivityViewController(
            activityItems: [shareText, image],
            applicationActivities: nil
        )

        // Present the share sheet from bottom
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Find the topmost presented controller
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }

            // iPad requires popover configuration - anchor to bottom
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.maxY, width: 0, height: 0)
                popover.permittedArrowDirections = .down
            }

            topVC.present(activityVC, animated: true)
        }
    }
}

struct TimePickerOverlay: View {
    let theme: Theme
    @Binding var show: Bool
    @Binding var selected: Int?
    let onConfirm: (Int) -> Void

    var body: some View {
        ZStack {
            theme.bgBottom.opacity(0.65).ignoresSafeArea()
                .onTapGesture { show = false }

            ThemedCard(theme: theme) {
                VStack(spacing: 14) {
                    Text("Set Time")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.textDark)

                    let options = [10, 20, 30, 40, 50, 60]
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 3), spacing: 10) {
                        ForEach(options, id: \.self) { s in
                            ThemedButton(
                                title: "\(s)s",
                                action: { selected = s },
                                prominent: s == selected,
                                theme: theme,
                                textColor: theme.textDark
                            )
                        }
                    }

                    HStack(spacing: 10) {
                        ThemedButton(title: "Cancel", action: { show = false }, theme: theme, textColor: theme.textDark)
                        ThemedButton(title: "Confirm", action: {
                            if let s = selected {
                                onConfirm(s)
                            }
                            show = false
                        }, prominent: true, theme: theme)
                        .disabled(selected == nil)
                        .opacity(selected == nil ? 0.6 : 1.0)
                    }
                }
            }
            .opacity(0.9)
            .frame(maxWidth: 320)
            .padding(.horizontal, 24)
        }
        .transaction { tx in tx.animation = nil }
    }
}
