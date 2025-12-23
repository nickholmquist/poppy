//
//  EndGameButton.swift
//  Poppy
//
//  End game button + popup overlay confirmation
//

import SwiftUI

struct EndGameButton: View {
    let theme: Theme
    let layout: LayoutController
    @Binding var showConfirmation: Bool

    @State private var isPressed = false

    private var buttonWidth: CGFloat {
        layout.startButtonWidth * 0.84  // Match START button width
    }

    private var cornerRadius: CGFloat {
        layout.startButtonCornerRadius
    }

    private var layerOffset: CGFloat {
        layout.startButtonLayerOffset
    }

    private var strokeWidth: CGFloat {
        layout.startButtonStrokeWidth
    }

    var body: some View {
        ZStack {
            // Bottom layer (depth) - darker gray for inactive
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(hex: "#6d6d6d"))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: strokeWidth)
                )
                .frame(width: buttonWidth, height: layout.startButtonHeight)

            // Top layer (surface)
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color(hex: "#c0c0c0"))  // Slightly darker than active

                Text("END")
                    .font(.system(size: layout.startButtonTitleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#3a3a3a"))
                    .shadow(color: .white.opacity(0.35), radius: 0.5, x: 0, y: 0)

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: strokeWidth)
            }
            .frame(width: buttonWidth, height: layout.startButtonHeight)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .offset(y: isPressed ? 0 : -layerOffset)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        HapticsManager.shared.light()
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        SoundManager.shared.play(.pop)
                        showConfirmation = true
                    }
                }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }
}

// MARK: - End Game Confirmation Overlay

struct EndGameOverlay: View {
    let theme: Theme
    let layout: LayoutController
    @Binding var show: Bool
    let onConfirm: () -> Void

    @State private var phase: AnimationPhase = .appearing

    enum AnimationPhase {
        case appearing
        case visible
        case dismissing
    }

    private var cornerRadius: CGFloat { layout.cornerRadiusMedium }
    private var layerOffset: CGFloat { layout.button3DLayerOffset }

    private var dimOpacity: Double {
        phase == .visible ? 0.4 : 0
    }

    private var cardScale: CGFloat {
        phase == .visible ? 1.0 : 0.8
    }

    private var cardOpacity: Double {
        phase == .visible ? 1.0 : 0
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black
                .opacity(dimOpacity)
                .ignoresSafeArea()
                .onTapGesture { dismiss(confirmed: false) }
                .animation(.easeOut(duration: 0.2), value: phase)

            // Centered confirmation card
            confirmationCard
                .scaleEffect(cardScale)
                .opacity(cardOpacity)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: phase)
        }
        .ignoresSafeArea()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                phase = .visible
            }
        }
    }

    private var confirmationCard: some View {
        VStack(spacing: 24) {
            // Title
            Text("End Match?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textDark)

            // Buttons row
            HStack(spacing: 20) {
                // Cancel (X) - Red
                ConfirmButton(
                    cornerRadius: cornerRadius,
                    layerOffset: layerOffset,
                    fillColor: Color(hex: "#E85D75"),
                    depthColor: Color(hex: "#a84455"),
                    iconName: "xmark"
                ) {
                    SoundManager.shared.play(.pop)
                    dismiss(confirmed: false)
                }

                // Confirm (checkmark) - Green
                ConfirmButton(
                    cornerRadius: cornerRadius,
                    layerOffset: layerOffset,
                    fillColor: Color(hex: "#5DBB63"),
                    depthColor: Color(hex: "#3d8c4a"),
                    iconName: "checkmark"
                ) {
                    SoundManager.shared.play(.popUp)
                    HapticsManager.shared.medium()
                    dismiss(confirmed: true)
                }
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius + 4, style: .continuous)
                .fill(theme.background)
                .shadow(color: Color.black.opacity(0.25), radius: 20, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius + 4, style: .continuous)
                .strokeBorder(Color.black.opacity(0.1), lineWidth: 1)
        )
    }

    private func dismiss(confirmed: Bool) {
        phase = .dismissing

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            show = false
            if confirmed {
                onConfirm()
            }
        }
    }
}

// MARK: - Confirmation Button (3D style)

private struct ConfirmButton: View {
    let cornerRadius: CGFloat
    let layerOffset: CGFloat
    let fillColor: Color
    let depthColor: Color
    let iconName: String
    let action: () -> Void

    @State private var isPressed = false

    private let buttonSize: CGFloat = 80

    var body: some View {
        ZStack(alignment: .top) {
            // Bottom layer (depth)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(depthColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(width: buttonSize, height: buttonSize)
                .offset(y: layerOffset)

            // Top layer (surface)
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: 2)
                    )

                Image(systemName: iconName)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: buttonSize, height: buttonSize)
            .offset(y: isPressed ? layerOffset : 0)
        }
        .frame(width: buttonSize, height: buttonSize + layerOffset, alignment: .top)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        HapticsManager.shared.light()
                    }
                }
                .onEnded { _ in
                    if isPressed {
                        isPressed = false
                        action()
                    }
                }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }
}

#Preview("End Game Overlay") {
    @Previewable @State var showOverlay = true

    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()

        if showOverlay {
            EndGameOverlay(
                theme: .daylight,
                layout: .preview,
                show: $showOverlay
            ) {
                print("End game confirmed")
            }
        }
    }
}

#Preview("End Button") {
    @Previewable @State var showConfirm = false

    VStack {
        EndGameButton(
            theme: .daylight,
            layout: .preview,
            showConfirmation: $showConfirm
        )
    }
    .padding()
    .background(Color(hex: "#F9F6EC"))
}
