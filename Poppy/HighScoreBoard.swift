//
//  HighScoreBoard.swift
//  Poppy
//
//  Collapsible high score display with smooth morph animation
//

import SwiftUI

struct HighScoreBoard: View {
    let theme: Theme
    let layout: LayoutController
    @ObservedObject var highs: HighscoreStore
    let isRunning: Bool
    
    @State private var isExpanded = false
    
    // Expanded dimensions (iPhone 16 Pro reference)
    private let expandedWidth: CGFloat = 359
    private let expandedHeight: CGFloat = 202
    private let expandedRadius: CGFloat = 22
    private let expandedSpacing: CGFloat = -88
    
    // Collapsed dimensions
    private let collapsedWidth: CGFloat = 118
    private let collapsedHeight: CGFloat = 54
    private let collapsedRadius: CGFloat = 12
    private let collapsedSpacing: CGFloat = -30
    
    // Computed properties for current state
    private var currentWidth: CGFloat {
        isExpanded ? expandedWidth : collapsedWidth
    }
    
    private var currentHeight: CGFloat {
        isExpanded ? expandedHeight : collapsedHeight
    }
    
    private var currentRadius: CGFloat {
        isExpanded ? expandedRadius : collapsedRadius
    }
    
    private var currentSpacing: CGFloat {
        isExpanded ? expandedSpacing : collapsedSpacing
    }
    
    var body: some View {
        ZStack {
            // Bottom rectangle (darker)
            RoundedRectangle(cornerRadius: currentRadius, style: .continuous)
                .fill(Color(hex: "#7d7d7d"))
                .frame(width: currentWidth, height: currentHeight)
            
            // Top rectangle (lighter) with stroke
            RoundedRectangle(cornerRadius: currentRadius, style: .continuous)
                .fill(Color(hex: "#d7d7d7"))
                .overlay(
                    RoundedRectangle(cornerRadius: currentRadius, style: .continuous)
                        .stroke(Color(hex: "#3a3a3a"), lineWidth: 3)
                )
                .frame(width: currentWidth, height: currentHeight)
                .offset(y: currentSpacing)
            
            // Content overlay
            if isExpanded {
                expandedContent
                    .frame(width: currentWidth, height: currentHeight)
                    .offset(y: currentSpacing / 2) // Center in the visible area
            } else {
                collapsedContent
                    .frame(width: currentWidth, height: currentHeight)
                    .offset(y: currentSpacing / 2)
            }
        }
        .onTapGesture {
            if !isRunning {
                HapticsManager.shared.light()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    isExpanded.toggle()
                }
            }
        }
    }
    
    // MARK: - Expanded Content
    
    @ViewBuilder
    private var expandedContent: some View {
        VStack(spacing: 14) {
            Text("High Scores")
                .font(.system(size: titleSize, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textOnAccent)
                .minimumScaleFactor(0.85)
                .lineLimit(1)
            
            HStack(spacing: 40) {
                scoreColumn([
                    ("10s", highs.best[10] ?? 0),
                    ("20s", highs.best[20] ?? 0),
                    ("30s", highs.best[30] ?? 0)
                ])
                scoreColumn([
                    ("40s", highs.best[40] ?? 0),
                    ("50s", highs.best[50] ?? 0),
                    ("60s", highs.best[60] ?? 0)
                ])
            }
        }
        .opacity(isExpanded ? 1 : 0)
    }
    
    @ViewBuilder
    private func scoreColumn(_ items: [(String, Int)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items, id: \.0) { label, value in
                HStack(spacing: 8) {
                    Text(label)
                        .font(.system(size: rowLabelSize, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textOnAccent.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    Text("------")
                        .font(.system(size: rowLabelSize))
                        .foregroundStyle(theme.textOnAccent.opacity(0.5))
                    
                    Text("\(value)")
                        .font(.system(size: rowValueSize, weight: .bold, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
        }
    }
    
    // MARK: - Collapsed Content
    
    @ViewBuilder
    private var collapsedContent: some View {
        Text("High Scores")
            .font(.system(size: collapsedTitleSize, weight: .bold, design: .rounded))
            .foregroundStyle(theme.textOnAccent)
            .minimumScaleFactor(0.85)
            .lineLimit(1)
            .opacity(isExpanded ? 0 : 1)
    }
    
    // MARK: - Dynamic Sizing
    
    private var titleSize: CGFloat {
        layout.scoreboardTitleSize
    }
    
    private var rowLabelSize: CGFloat {
        layout.scoreboardLabelSize
    }
    
    private var rowValueSize: CGFloat {
        layout.scoreboardValueSize
    }
    
    private var collapsedTitleSize: CGFloat {
        // Smaller title for collapsed state
        titleSize * 0.6
    }
}

#Preview {
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()
        
        GeometryReader { geo in
            let layout = LayoutController(geo)
            
            HighScoreBoard(
                theme: .daylight,
                layout: layout,
                highs: HighscoreStore(),
                isRunning: false
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 100)
        }
    }
}