//
//  StartButton.swift
//  Poppy
//

import SwiftUI

struct StartButton: View {
    let theme: Theme
    let layout: LayoutController
    let title: String
    var textColor: Color = Theme.daylight.textDark
    let action: () -> Void

    private let art = "button_StartPop"
    @State private var down = false
    @State private var glowOpacity: Double = 0.0
    
    private var isIdleStart: Bool {
        title == "START"
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(art)
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .paperTint(theme.accent, opacity: 0.95, brightness: 0.06)

                Text(title)
                    .font(.system(size: layout.startButtonTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
                    .shadow(color: .white.opacity(0.35), radius: 0.5, x: 0, y: 0)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 12)
                    .offset(y: -7)
            }
            .offset(y: down ? 2 : 0)
            .animation(.interpolatingSpring(stiffness: 240, damping: 24), value: down)
            .background {
                if isIdleStart {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(theme.accent)
                        .opacity(glowOpacity)
                        .blur(radius: 15)
                        .scaleEffect(1.0)
                }
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in down = true }
                .onEnded { _ in down = false }
        )
        .onAppear {
            if isIdleStart {
                startInvitationPulse()
            }
        }
        .onChange(of: title) { _, newTitle in
            if newTitle == "START" {
                startInvitationPulse()
            } else {
                stopInvitationPulse()
            }
        }
    }
    
    private func startInvitationPulse() {
        withAnimation(
            .easeInOut(duration: 2.5)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.3
        }
    }
    
    private func stopInvitationPulse() {
        withAnimation(.easeOut(duration: 0.3)) {
            glowOpacity = 0.0
        }
    }
}
