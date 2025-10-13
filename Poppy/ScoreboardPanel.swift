//
//  ScoreboardPanel.swift
//  Poppy
//

import SwiftUI

struct ScoreboardPanel: View {
    let maxWidth: CGFloat
    /// A soft cap for height. The image will never exceed this, but will keep its aspect.
    let height: CGFloat
    let theme: Theme
    @ObservedObject var highs: HighscoreStore

    /// Optional tint over the PNG (0 = none)
    var tintOpacity: Double = 0.95
    var brightnessLift: Double = 0.06


    // Typography that scales with the final panel height
    private func titleSize(_ h: CGFloat) -> CGFloat    { min(28, h * 0.16) }
    private func rowLabel(_ h: CGFloat) -> CGFloat     { min(18, h * 0.11) }
    private func rowValue(_ h: CGFloat) -> CGFloat     { min(20, h * 0.12) }
    private func padH(_ h: CGFloat) -> CGFloat         { max(10, h * 0.06) }
    private func padV(_ h: CGFloat) -> CGFloat         { max(10, h * 0.08) }

    var body: some View {
        // Load the PNG to get the true aspect ratio
        let ui = UIImage(named: "Scoreboard")
        // Fallback aspect if image fails to load (your file is 1201x768)
        let aspect = ui.map { $0.size.width / $0.size.height } ?? (1201.0 / 768.0)

        // Compute the rendered height: fit to width, but do not exceed the given height cap
        let fittedHeight = min(maxWidth / aspect, height)

        ZStack {
            if let ui {
                Image(uiImage: ui)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(aspect, contentMode: .fit)
                    .frame(width: maxWidth, height: fittedHeight, alignment: .center)
                    .paperTint(theme.accent, opacity: tintOpacity, brightness: brightnessLift) // <- same as Start button
            }
            else {
                // Simple fallback if the asset is missing
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.bgBottom.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.black.opacity(0.25), lineWidth: 1.25)
                    )
                    .frame(width: maxWidth, height: fittedHeight)
            }

            // Content overlay
            VStack(spacing: 10) {
                Text("High Scores")
                    .font(.system(size: titleSize(fittedHeight), weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)

                HStack(spacing: fittedHeight * 0.20) {
                    col([
                        ("10s", highs.best[10] ?? 0),
                        ("20s", highs.best[20] ?? 0),
                        ("30s", highs.best[30] ?? 0)
                    ], h: fittedHeight)
                    col([
                        ("40s", highs.best[40] ?? 0),
                        ("50s", highs.best[50] ?? 0),
                        ("60s", highs.best[60] ?? 0)
                    ], h: fittedHeight)
                }
            }
            .padding(.horizontal, padH(fittedHeight))
            .padding(.vertical, padV(fittedHeight))
        }
        .frame(width: maxWidth, height: fittedHeight)
        .allowsHitTesting(false)   // never swallow taps
    }

    // MARK: helpers

    @ViewBuilder
    private func col(_ items: [(String, Int)], h: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: h * 0.06) {
            ForEach(items, id: \.0) { label, value in
                HStack(spacing: 8) {
                    Text(label)
                        .font(.system(size: rowLabel(h), weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textOnAccent.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("------") // short divider so we avoid em dashes
                        .font(.system(size: rowLabel(h)))
                        .foregroundStyle(theme.textOnAccent.opacity(0.5))

                    Text("\(value)")
                        .font(.system(size: rowValue(h), weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
}
