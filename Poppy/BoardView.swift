//
//  BoardView.swift
//  Poppy
//

import SwiftUI

struct BoardView: View {
    let theme: Theme
    let active: Set<Int>          // indices 0..<10
    let pressed: Set<Int>
    let onTap: (Int) -> Void
    var compact: Bool = false
    
    // Bounce animation triggers
    let bounceAll: Int
    let bounceIndividual: [Int: Int]

    // 3-4-3 layout
    private let rowPattern = [3, 4, 3]

    // Spacing and sizing
    private let hSpacing: CGFloat = 18   // horizontal gap between dots
    private let vSpacing: CGFloat = 10   // vertical gap between rows
    private let sideInset: CGFloat = 6   // outer horizontal gutter
    private let maxBoardWidth: CGFloat = 350

    // Visual normalization so active/pressed art appears same size
    private let activeScale: CGFloat = 0.94
    private let pressedScale: CGFloat = 0.85

    var body: some View {
        GeometryReader { geo in
            let maxCols = 4
            let rawW = geo.size.width
            let sideInset: CGFloat = 4           // keep your value
            let hSpacing: CGFloat = 20           // keep your value
            let vSpacing: CGFloat = 10           // keep your value

            // usable width can be 0 during transitions on device
            let usableW = max(0, rawW - sideInset * 2)

            // compute, then clamp dot to a sane minimum
            let computed = (usableW - CGFloat(maxCols - 1) * hSpacing) / CGFloat(maxCols)
            let safeDot: CGFloat = {
                let d = floor(computed)
                if !d.isFinite || d < 8 { return 8 }   // min ~8pt so it never goes negative or NaN
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
                            
                            // Combine bounceAll and individual bounce triggers
                            // Combine bounceAll and individual bounce triggers
                            let bounceID = bounceAll + (bounceIndividual[idx] ?? 0)

                            DotSprite(
                                theme: theme,
                                isActive: isActive,
                                isPressed: isPressed,
                                bounceID: bounceID
                            )
                            .frame(width: safeDot, height: safeDot, alignment: .bottom)
                            .contentShape(Circle().inset(by: 4))   // your tighter hit target
                            .onTapGesture { onTap(idx) }
                        }
                    }
                    // guard the centering pad so it never goes negative
                    .padding(.horizontal, cols == maxCols ? 0 : max(0, (safeDot + hSpacing) / 2))
                    .frame(height: safeDot, alignment: .bottom)
                }
            }
            .frame(width: usableW, height: rowHeights, alignment: .top)
            .padding(.horizontal, sideInset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        // Overall board height. Adjust if you want the grid taller or shorter.
        .frame(height: 275)
    }

    // Helper
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
