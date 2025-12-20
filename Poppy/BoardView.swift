//
//  BoardView.swift
//  Poppy
//
//  Variable dot grid layout supporting 10, 16, or 20 dots for Matchy mode
//
//  ⚠️ SIZING: All dimensions come from LayoutController.swift
//  Do not hardcode any sizes, spacing, or dimensions in this file.
//

import SwiftUI

struct BoardView: View {
    let theme: Theme
    let layout: LayoutController
    let active: Set<Int>
    let pressed: Set<Int>
    let onTap: (Int) -> Void

    let bounceAll: Int
    let bounceIndividual: [Int: Int]
    let rippleDisplacements: [Int: CGPoint]
    let idleTapFlash: [Int: Int]
    let themeWaveDisplacements: [Int: CGPoint]

    // Matchy mode support
    let matchyColors: [Int: Int]  // Dot index -> color index
    let matchyRevealedArray: [Int]  // Currently revealed dots (as array for SwiftUI change detection)
    let matchyMatchedArray: [Int]   // Matched dots (as array for SwiftUI change detection)

    // Grid size for Matchy mode (10, 16, or 20) - defaults to 10 for other modes
    var matchyGridSize: Int = 10

    // Seeky mode support (find the odd one)
    var seekyOddDot: Int? = nil
    var seekyDifference: SeekyDifference = .color
    var seekyDifferenceAmount: CGFloat = 0.0
    var seekyBaseColor: Color? = nil  // Base color for all dots in Seeky mode
    var seekyRevealingAnswer: Bool = false  // Pulsate the odd dot when revealing answer

    // Computed sets for easier checking
    private var matchyRevealed: Set<Int> { Set(matchyRevealedArray) }
    private var matchyMatched: Set<Int> { Set(matchyMatchedArray) }

    // Dynamic row pattern based on grid size
    private var rowPattern: [Int] {
        switch matchyGridSize {
        case 16:
            return [2, 4, 4, 4, 2]  // Diamond pattern totaling 16
        case 20:
            return [3, 5, 4, 5, 3]  // Hourglass pattern totaling 20
        default:
            return [3, 4, 3]  // Original 10-dot pattern
        }
    }

    private var maxCols: Int {
        rowPattern.max() ?? 4
    }

    var body: some View {
        GeometryReader { geo in
            let rawW = geo.size.width
            let rawH = geo.size.height
            let baseHSpacing = layout.dotSpacingHorizontal
            let baseVSpacing = layout.dotSpacingVertical
            let sideInset = layout.dotSideInset

            let usableW = max(0, rawW - sideInset * 2)

            // Scale factor for dot size - keep dots large
            // Base: 3 rows, Medium: 5 rows (2-4-4-4-2), Large: 5 rows (3-5-4-5-3)
            let rowCount = rowPattern.count
            let dotScaleFactor: CGFloat = {
                switch matchyGridSize {
                case 16: return 0.88  // Medium - bigger dots
                case 20: return 1.15  // Large - extra large dots
                default: return 1.0   // Small (3 rows) - full size
                }
            }()

            // Spacing multiplier - more spacing for medium/large grids
            let spacingMultiplier: CGFloat = {
                switch matchyGridSize {
                case 16: return 1.15  // Medium - good spacing
                case 20: return 1.2   // Large - a bit more spacing
                default: return 1.0   // Small - default spacing
                }
            }()

            // Apply scale to spacing
            let hSpacing = baseHSpacing * dotScaleFactor * spacingMultiplier
            let vSpacing = baseVSpacing * dotScaleFactor * spacingMultiplier

            // Calculate dot size - scale by width available divided by max columns
            let computed = (usableW - CGFloat(maxCols - 1) * hSpacing) / CGFloat(maxCols) * dotScaleFactor
            let safeDot: CGFloat = {
                let d = floor(computed)
                if !d.isFinite || d < 8 { return 8 }
                return d
            }()

            let totalHeight = CGFloat(rowCount) * safeDot + CGFloat(rowCount - 1) * vSpacing
            let indexOffsets = prefixSums(rowPattern)

            VStack(spacing: vSpacing) {
                ForEach(rowPattern.indices, id: \.self) { r in
                    let cols = rowPattern[r]
                    let startIndex = indexOffsets[r]

                    HStack(alignment: .bottom, spacing: hSpacing) {
                        ForEach(0..<cols, id: \.self) { c in
                            let idx = startIndex + c
                            let isActive  = active.contains(idx)
                            let isPressed = pressed.contains(idx)

                            let bounceID = bounceAll + (bounceIndividual[idx] ?? 0)

                            let rippleOffset = rippleDisplacements[idx] ?? .zero
                            let waveOffset = themeWaveDisplacements[idx] ?? .zero
                            let totalDisplacement = CGPoint(
                                x: rippleOffset.x + waveOffset.x,
                                y: rippleOffset.y + waveOffset.y
                            )

                            let idleFlashID = idleTapFlash[idx] ?? 0

                            TappableDotSprite(
                                theme: theme,
                                layout: layout,
                                isActive: isActive,
                                isGamePressed: isPressed,
                                bounceID: bounceID,
                                idleFlashID: idleFlashID,
                                matchyColorHex: getMatchyColorHex(for: idx),
                                matchySymbol: getMatchySymbol(for: idx),
                                onTap: { onTap(idx) },
                                seekyDifference: seekyDifference,
                                seekyAmount: idx == seekyOddDot ? seekyDifferenceAmount : 0.0,
                                seekyBaseColor: seekyBaseColor,
                                seekyIsOddDot: idx == seekyOddDot,
                                seekyRevealingAnswer: seekyRevealingAnswer
                            )
                            .frame(width: safeDot, height: safeDot, alignment: .bottom)
                            .offset(x: totalDisplacement.x, y: totalDisplacement.y)
                        }
                    }
                    // Center rows with fewer columns
                    .frame(height: safeDot, alignment: .bottom)
                }
            }
            .frame(width: usableW, height: totalHeight, alignment: .center)
            .padding(.horizontal, sideInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func prefixSums(_ arr: [Int]) -> [Int] {
        var sums: [Int] = []
        var running = 0
        for v in arr {
            sums.append(running)
            running += v
        }
        return sums
    }

    // Extended Matchy color palette for larger grids (up to 10 pairs = 20 dots)
    private static let matchyColorPalette: [String] = [
        "#F59AA1", // Rose
        "#7DD3FC", // Sky
        "#A3E635", // Lime
        "#FACC15", // Gold
        "#C084FC", // Violet
        "#FB923C", // Orange
        "#4ADE80", // Emerald
        "#F472B6", // Pink
        "#60A5FA", // Blue
        "#A78BFA"  // Purple
    ]

    // Symbols for each color (accessibility - helps colorblind players)
    private static let matchySymbolPalette: [String] = [
        "heart.fill",      // Rose - heart
        "drop.fill",       // Sky - water drop
        "leaf.fill",       // Lime - leaf
        "star.fill",       // Gold - star
        "diamond.fill",    // Violet - diamond
        "flame.fill",      // Orange - flame
        "square.fill",     // Emerald - square
        "circle.fill",     // Pink - circle
        "triangle.fill",   // Blue - triangle
        "moon.fill"        // Purple - moon
    ]

    private func getMatchyColorHex(for index: Int) -> String? {
        // Only show color if revealed or matched
        guard matchyRevealed.contains(index) || matchyMatched.contains(index) else {
            return nil
        }
        guard let colorIndex = matchyColors[index],
              colorIndex < Self.matchyColorPalette.count else {
            return nil
        }
        return Self.matchyColorPalette[colorIndex]
    }

    private func getMatchySymbol(for index: Int) -> String? {
        // Only show symbol if revealed or matched
        guard matchyRevealed.contains(index) || matchyMatched.contains(index) else {
            return nil
        }
        guard let colorIndex = matchyColors[index],
              colorIndex < Self.matchySymbolPalette.count else {
            return nil
        }
        return Self.matchySymbolPalette[colorIndex]
    }
}

// MARK: - Tappable Dot Sprite Wrapper

/// Wraps DotSprite with local press state for touch feedback
private struct TappableDotSprite: View {
    let theme: Theme
    let layout: LayoutController
    let isActive: Bool
    let isGamePressed: Bool  // From game logic (showing sequence)
    let bounceID: Int
    let idleFlashID: Int
    var matchyColorHex: String? = nil
    var matchySymbol: String? = nil
    let onTap: () -> Void

    // Seeky mode - difference from normal dots
    var seekyDifference: SeekyDifference = .color
    var seekyAmount: CGFloat = 0.0  // 0 = normal, >0 = this is the odd dot (saturation shift)
    var seekyBaseColor: Color? = nil  // Override color for Seeky mode
    var seekyIsOddDot: Bool = false   // Whether this is the odd dot
    var seekyRevealingAnswer: Bool = false  // Pulsate when revealing answer

    @State private var isLocalPressed = false
    @State private var revealPulse: Bool = false

    // Either game logic or local touch causes pressed state
    private var isPressed: Bool {
        isGamePressed || isLocalPressed
    }

    var body: some View {
        DotSprite(
            theme: theme,
            layout: layout,
            isActive: isActive,
            isPressed: isPressed,
            bounceID: bounceID,
            idleFlashID: idleFlashID,
            matchyColorHex: matchyColorHex,
            matchySymbol: matchySymbol,
            seekyBaseColor: seekyBaseColor
        )
        // Apply Seeky shade difference - saturation shift for the odd dot
        // When revealing, show full saturation so the answer is obvious
        .saturation(seekyRevealingAnswer && seekyIsOddDot ? 1.0 : (seekyAmount > 0 ? 1.0 - seekyAmount : 1.0))
        // Pulsate scale when revealing the answer
        .scaleEffect(revealPulse ? 1.25 : 1.0)
        .animation(revealPulse ? .easeInOut(duration: 0.25).repeatForever(autoreverses: true) : .spring(response: 0.2, dampingFraction: 0.7), value: revealPulse)
        .onChange(of: seekyRevealingAnswer) { _, revealing in
            if revealing && seekyIsOddDot {
                revealPulse = true
            } else {
                // Use withAnimation to ensure the scale animates back smoothly
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    revealPulse = false
                }
            }
        }
        .contentShape(Circle().inset(by: 4))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isLocalPressed {
                        isLocalPressed = true
                        HapticsManager.shared.light()
                    }
                }
                .onEnded { _ in
                    if isLocalPressed {
                        isLocalPressed = false
                        onTap()
                    }
                }
        )
    }
}
