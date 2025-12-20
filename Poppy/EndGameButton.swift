//
//  EndGameButton.swift
//  Poppy
//
//  End game button that takes over START button position
//  Splits into red/green confirmation when tapped
//

import SwiftUI

struct EndGameButton: View {
    let theme: Theme
    let layout: LayoutController
    let onConfirmEnd: () -> Void

    @State private var isPressed = false
    @State private var showConfirmation = false

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
        VStack(spacing: 12) {
            // "End Match?" label slides up during confirmation
            if showConfirmation {
                Text("End Match?")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textDark)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 4)
            }

            // Main button area - instant swap, no opacity transition
            ZStack {
                if showConfirmation {
                    splitConfirmationView
                } else {
                    endButtonView
                }
            }
        }
        .animation(nil, value: showConfirmation)
    }

    // MARK: - END Button (inactive style)

    private var endButtonView: some View {
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

    // MARK: - Split Confirmation View

    private var splitConfirmationView: some View {
        HStack(spacing: 0) {
            // Cancel (X) - Red left half
            SplitHalfButton(
                cornerRadius: cornerRadius,
                strokeWidth: strokeWidth,
                isLeftHalf: true,
                fillColor: Color(hex: "#E85D75"),
                depthColor: Color(hex: "#a84455"),
                iconName: "xmark",
                layerOffset: layerOffset
            ) {
                SoundManager.shared.play(.pop)
                showConfirmation = false
            }

            // Confirm (checkmark) - Green right half
            SplitHalfButton(
                cornerRadius: cornerRadius,
                strokeWidth: strokeWidth,
                isLeftHalf: false,
                fillColor: Color(hex: "#5DBB63"),
                depthColor: Color(hex: "#3d8c4a"),
                iconName: "checkmark",
                layerOffset: layerOffset
            ) {
                SoundManager.shared.play(.popUp)
                HapticsManager.shared.medium()
                showConfirmation = false
                onConfirmEnd()
            }
        }
        .frame(width: buttonWidth, height: layout.startButtonHeight)
    }
}

// MARK: - Split Half Button with Layered Press Animation

private struct SplitHalfButton: View {
    let cornerRadius: CGFloat
    let strokeWidth: CGFloat
    let isLeftHalf: Bool
    let fillColor: Color
    let depthColor: Color
    let iconName: String
    let layerOffset: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Bottom depth layer (stays in place)
            depthLayer

            // Top surface layer (moves down when pressed)
            surfaceLayer
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
                        action()
                    }
                }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
    }

    @ViewBuilder
    private var depthLayer: some View {
        if isLeftHalf {
            UnevenRoundedRectangle(
                topLeadingRadius: cornerRadius,
                bottomLeadingRadius: cornerRadius,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .fill(depthColor)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: strokeWidth)
            )
        } else {
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: cornerRadius,
                topTrailingRadius: cornerRadius
            )
            .fill(depthColor)
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: cornerRadius
                )
                .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: strokeWidth)
            )
        }
    }

    @ViewBuilder
    private var surfaceLayer: some View {
        ZStack {
            if isLeftHalf {
                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(fillColor)

                UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: strokeWidth)

                // Center divider line on right edge
                HStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(hex: "#3a3a3a"))
                        .frame(width: strokeWidth)
                }
            } else {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: cornerRadius
                )
                .fill(fillColor)

                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: cornerRadius
                )
                .strokeBorder(Color(hex: "#3a3a3a"), lineWidth: strokeWidth)
            }

            Image(systemName: iconName)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

#Preview("End Button - Normal") {
    EndGameButton(
        theme: .daylight,
        layout: .preview
    ) {
        print("End game confirmed")
    }
    .padding()
    .background(Color(hex: "#F9F6EC"))
}
