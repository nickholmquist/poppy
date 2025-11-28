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
    var body: some View {
        ZStack {
            theme.accent.opacity(0.95).ignoresSafeArea()
            VStack {
                Spacer(minLength: 0)
                Text("Game Over")
                    .font(.system(size: 60, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(theme.textOnAccent)
                    .shadow(color: .black.opacity(0.45), radius: 8, x: 0, y: 2)
                    .shadow(color: .white.opacity(0.22), radius: 2, x: 0, y: 0)
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
