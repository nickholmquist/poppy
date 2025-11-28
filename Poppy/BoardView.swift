//
//  BoardView.swift
//  Poppy
//
//  10-dot grid layout with 3-4-3 pattern
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

    private let rowPattern = [3, 4, 3]

    var body: some View {
        GeometryReader { geo in
            let maxCols = 4
            let rawW = geo.size.width
            let hSpacing = layout.dotSpacingHorizontal
            let vSpacing = layout.dotSpacingVertical
            let sideInset = layout.dotSideInset

            let usableW = max(0, rawW - sideInset * 2)
            let computed = (usableW - CGFloat(maxCols - 1) * hSpacing) / CGFloat(maxCols)
            let safeDot: CGFloat = {
                let d = floor(computed)
                if !d.isFinite || d < 8 { return 8 }
                return d
            }()

            let rowHeights = CGFloat(rowPattern.count) * safeDot
                           + CGFloat(rowPattern.count - 1) * vSpacing
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

                            DotSprite(
                                theme: theme,
                                layout: layout,
                                isActive: isActive,
                                isPressed: isPressed,
                                bounceID: bounceID,
                                idleFlashID: idleFlashID
                            )
                            .frame(width: safeDot, height: safeDot, alignment: .bottom)
                            .offset(x: totalDisplacement.x, y: totalDisplacement.y)
                            .contentShape(Circle().inset(by: 4))
                            .onTapGesture { onTap(idx) }
                        }
                    }
                    .padding(.horizontal, cols == maxCols ? 0 : max(0, (safeDot + hSpacing) / 2))
                    .frame(height: safeDot, alignment: .bottom)
                }
            }
            .frame(width: usableW, height: rowHeights, alignment: .top)
            .padding(.horizontal, sideInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
}
