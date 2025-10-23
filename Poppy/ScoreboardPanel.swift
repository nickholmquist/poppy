//
//  ScoreboardPanel.swift
//  Poppy
//

import SwiftUI

struct ScoreboardPanel: View {
    let layout: LayoutController
    let theme: Theme
    @ObservedObject var highs: HighscoreStore

    // These now just pull from LayoutController
    private var titleSize: CGFloat { layout.scoreboardTitleSize }
    private var rowLabel: CGFloat { layout.scoreboardLabelSize }
    private var rowValue: CGFloat { layout.scoreboardValueSize }
    
    // Keep padding calculations proportional to height
    private func padH(_ h: CGFloat) -> CGFloat { max(10, h * 0.04) }
    private func padV(_ h: CGFloat) -> CGFloat { max(10, h * 0.06) }

    var body: some View {
        let ui = UIImage(named: "Scoreboard")
        let aspect = ui.map { $0.size.width / $0.size.height } ?? (1201.0 / 768.0)
        let width = layout.scoreboardWidth
        let height = layout.scoreboardHeight

        ZStack {
            if let ui {
                Image(uiImage: ui)
                    .renderingMode(.original)
                    .resizable()
                    .aspectRatio(aspect, contentMode: .fit)
                    .frame(width: width, height: height, alignment: .center)
                    .paperTint(theme.accent, opacity: 0.95, brightness: 0.06)
            } else {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(theme.bgBottom.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(.black.opacity(0.25), lineWidth: 1.25)
                    )
                    .frame(width: width, height: height)
            }

            VStack(spacing: 14) {
                Text("High Scores")
                    .font(.system(size: titleSize, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent)
                    .minimumScaleFactor(0.85)
                    .lineLimit(1)

                HStack(spacing: height * 0.20) {
                    col([
                        ("10s", highs.best[10] ?? 0),
                        ("20s", highs.best[20] ?? 0),
                        ("30s", highs.best[30] ?? 0)
                    ])
                    col([
                        ("40s", highs.best[40] ?? 0),
                        ("50s", highs.best[50] ?? 0),
                        ("60s", highs.best[60] ?? 0)
                    ])
                }
            }
            .padding(.horizontal, padH(height))
            .padding(.vertical, padV(height))
            .offset(y: -12)
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func col(_ items: [(String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: layout.scoreboardHeight * 0.06) {
            ForEach(items, id: \.0) { label, value in
                HStack(spacing: 8) {
                    Text(label)
                        .font(.system(size: rowLabel, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textOnAccent.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("------")
                        .font(.system(size: rowLabel))
                        .foregroundStyle(theme.textOnAccent.opacity(0.5))

                    Text("\(value)")
                        .font(.system(size: rowValue, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
}
