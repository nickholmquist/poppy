//
//  StartButton.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/6/25.
//


import SwiftUI

struct StartButton: View {
    let theme: Theme
    let title: String
    var textColor: Color = Theme.daylight.textDark
    var tintOpacity: Double = 0.95
    var brightnessLift: Double = 0.06
    let action: () -> Void

    private let art = "button_StartPop"
    @State private var down = false

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(art)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .paperTint(theme.accent, opacity: tintOpacity, brightness: brightnessLift)

                Text(title)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                    .shadow(color: .white.opacity(0.35), radius: 0.5, x: 0, y: 0)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 12)
            }
            .offset(y: down ? 2 : 0)
            .animation(.interpolatingSpring(stiffness: 240, damping: 24), value: down)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in down = true }
                .onEnded { _ in down = false }
        )
    }
}

