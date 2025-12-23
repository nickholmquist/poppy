//
//  HighScoreBoard.swift
//  Poppy
//
//  Collapsible high score display with smooth morph animation
//  Supports multiple game modes
//

import SwiftUI

struct HighScoreBoard: View {
    let theme: Theme
    let layout: LayoutController
    @ObservedObject var highs: HighscoreStore
    let isRunning: Bool
    @Binding var isExpanded: Bool  // Binding to parent
    let celebratingMode: Int?  // Which time mode is being celebrated (10, 20, 30, etc.)
    let gameMode: GameMode  // Current game mode
    var dailyDuration: Int = 0  // Today's daily challenge duration
    
    @State private var showScores = false
    @State private var showFirstPair = false   // 10s, 40s
    @State private var showSecondPair = false  // 20s, 50s
    @State private var showThirdPair = false   // 30s, 60s
    @State private var glowIntensity: CGFloat = 0.0
    @State private var isPressed = false  // Track press state for animation
    
    // Use LayoutController for all dimensions
    private var currentWidth: CGFloat {
        isExpanded ? layout.scoreboardExpandedWidth : layout.scoreboardCollapsedWidth
    }

    private var currentHeight: CGFloat {
        if !isExpanded {
            return layout.scoreboardCollapsedHeight
        }
        // Mode-specific expanded heights
        switch gameMode {
        case .classic:
            return layout.scoreboardExpandedHeight
        case .copy, .matchy, .seeky, .daily, .zoomy:
            // Smaller height for single-score modes
            return layout.scoreboardCollapsedHeight + 60
        case .boppy, .tappy:
            // Timed modes with 3 durations - medium height
            return layout.scoreboardCollapsedHeight + 100
        }
    }
    
    private var currentRadius: CGFloat {
        layout.scoreboardCornerRadius
    }
    
    // Layer spacing for 3D effect
    private var currentSpacing: CGFloat {
        layout.scoreboardLayerSpacing
    }
    
    // Top layer offset - slides down ONLY when pressed
    private var topLayerOffset: CGFloat {
        isPressed ? 0 : currentSpacing  // negative when idle, 0 when pressed
    }
    
    // Content offset follows top layer
    private var contentOffset: CGFloat {
        topLayerOffset
    }
    
    // Title padding that works for both collapsed and expanded states
    private var titleTopPadding: CGFloat {
        if isExpanded {
            return layout.isIPad ? 0 : 10
        } else {
            // Collapsed state - center vertically
            return 0
        }
    }
    
    private var titleBottomPadding: CGFloat {
        if isExpanded {
            return layout.isIPad ? 16 : 8
        } else {
            return 0
        }
    }
    
    var body: some View {
        ZStack {
            // Bottom rectangle (darker) - with stroke
            RoundedRectangle(cornerRadius: currentRadius, style: .continuous)
                .fill(Color(hex: "#7d7d7d"))
                .paperTint(theme.accent, opacity: 0.95, brightness: 0.06)
                .overlay(
                    RoundedRectangle(cornerRadius: currentRadius, style: .continuous)
                        .stroke(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(width: currentWidth, height: currentHeight)
                .animation(.easeInOut(duration: 0.5), value: isExpanded)

            // Top rectangle (lighter) - with stroke - SLIDES DOWN when pressed
            RoundedRectangle(cornerRadius: currentRadius, style: .continuous)
                .fill(Color(hex: "#d7d7d7"))
                .paperTint(theme.accent, opacity: 1.0, brightness: 0.06)
                .overlay(
                    RoundedRectangle(cornerRadius: currentRadius, style: .continuous)
                        .stroke(Color(hex: "#3a3a3a"), lineWidth: 2)
                )
                .frame(width: currentWidth, height: currentHeight)
                .animation(.easeInOut(duration: 0.5), value: isExpanded)
                .offset(y: topLayerOffset)
                .animation(.easeOut(duration: 0.15), value: isPressed)
            
            // Content overlay - VERTICALLY CENTERED when expanded (all devices)
            VStack(spacing: 0) {
                // Top spacer for vertical centering (when expanded)
                if isExpanded {
                    Spacer()
                }
                
                // Title (perfectly centered) with Game Center icon overlay
                ZStack(alignment: .trailing) {
                    // Title - centered across full width
                    Text(titleText)
                        .font(.system(
                            size: titleSize,
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundStyle(theme.textOnAccent)
                        .minimumScaleFactor(0.85)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, isExpanded ? 0 : titleTopPadding)
                        .padding(.bottom, isExpanded ? 12 : titleBottomPadding)
                    
                    // Game Center icon - overlaid in top-right (only when expanded)
                    if isExpanded {
                        Button(action: {
                            SoundManager.shared.play(.pop)
                            HapticsManager.shared.light()
                            GameCenterManager.shared.showLeaderboards()
                        }) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: layout.isIPad ? 20 : 16, weight: .semibold))
                                .foregroundStyle(theme.textOnAccent.opacity(0.7))
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .transition(.opacity.animation(.easeOut(duration: 0.15)))  // Fast fade
                        .padding(.trailing, layout.isIPad ? 45 : 30)  // More padding on iPad = further toward center
                        .padding(.bottom, 12)
                    }
                }
                
                // Scores - mode-specific content
                if isExpanded {
                    modeContent
                        .transition(.opacity)
                }
                
                // Bottom spacer for vertical centering (when expanded)
                if isExpanded {
                    Spacer()
                }
            }
            .frame(width: currentWidth, height: currentHeight, alignment: .center)  // Always center
            .animation(.easeInOut(duration: 0.5), value: isExpanded)
            .offset(y: contentOffset)
            .animation(.easeOut(duration: 0.15), value: isPressed)
            .clipShape(RoundedRectangle(cornerRadius: currentRadius, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .onAppear {
            if isExpanded {
                showScores = true
                showFirstPair = true
                showSecondPair = true
                showThirdPair = true
            }
        }
        .onChange(of: isExpanded) { _, expanded in
            if expanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showFirstPair = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSecondPair = true
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showThirdPair = true
                    }
                }
            } else {
                showFirstPair = false
                showSecondPair = false
                showThirdPair = false
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isRunning && !isPressed {
                        withAnimation(.easeOut(duration: 0.15)) {
                            isPressed = true
                        }
                        HapticsManager.shared.light()
                    }
                }
                .onEnded { _ in
                    if !isRunning && isPressed {
                        if isExpanded {
                            // COLLAPSING SEQUENCE
                            SoundManager.shared.play(.pop)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    showThirdPair = false
                                    showSecondPair = false
                                    showFirstPair = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        isExpanded = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        withAnimation(.easeOut(duration: 0.15)) {
                                            isPressed = false
                                        }
                                    }
                                }
                            }
                        } else {
                            // EXPANDING SEQUENCE
                            SoundManager.shared.play(.pop)
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isExpanded = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    withAnimation(.easeOut(duration: 0.15)) {
                                        isPressed = false
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            showFirstPair = true
                                        }
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            showSecondPair = true
                                        }
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            showThirdPair = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
        )
        .onChange(of: celebratingMode) { _, newMode in
            if newMode != nil {
                withAnimation(
                    .easeInOut(duration: 0.4)
                    .repeatCount(8, autoreverses: true)
                ) {
                    glowIntensity = 1.5
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
                    glowIntensity = 0.0
                }
            }
        }
    }
    
    // MARK: - Title Helper

    private var titleText: String {
        switch gameMode {
        case .classic:
            return "High Scores"
        case .daily:
            return "Daily Score"
        case .matchy:
            return "Matchy Best"
        case .copy:
            return "Copy Best"
        case .boppy:
            return "High Scores"
        case .zoomy:
            return "Zoomy Scores"
        case .tappy:
            return "High Scores"
        case .seeky:
            return "Seeky Best"
        }
    }

    // MARK: - Mode-Specific Content

    @ViewBuilder
    private var modeContent: some View {
        switch gameMode {
        case .classic:
            classicScoresContent
        case .daily:
            dailyScoreContent
        case .matchy:
            singleScoreContent(value: highs.matchyBest, label: "pairs")
        case .copy:
            // Copy mode uses CopyHeader instead, but show classic best as fallback
            singleScoreContent(value: highs.copyClassicBest, label: "rounds")
        case .boppy:
            timedScoresContent(scores: highs.boppyBest, durations: [20, 30, 40])
        case .zoomy:
            // Zoomy is survival mode - single best score
            singleScoreContent(value: highs.zoomyBest[0] ?? 0, label: "catches")
        case .tappy:
            // Tappy is lives-based mode - single best score
            singleScoreContent(value: highs.tappyBest[0] ?? 0, label: "rounds")
        case .seeky:
            singleScoreContent(value: highs.seekyBest, label: "rounds")
        }
    }

    private func timedScoresContent(scores: [Int: Int], durations: [Int]) -> some View {
        // For 3 or fewer durations, stack vertically and center
        if durations.count <= 3 {
            return AnyView(
                VStack(spacing: 8) {
                    ForEach(Array(durations.enumerated()), id: \.offset) { index, duration in
                        scoreRow("\(duration)s", scores[duration] ?? 0, show: showForIndex(index))
                    }
                }
            )
        } else {
            // For more durations, use two columns
            let leftDurations = Array(durations.prefix(durations.count / 2 + durations.count % 2))
            let rightDurations = Array(durations.suffix(durations.count / 2))

            return AnyView(
                HStack(spacing: layout.scoreboardColumnSpacing) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(leftDurations.enumerated()), id: \.offset) { index, duration in
                            scoreRow("\(duration)s", scores[duration] ?? 0, show: showForIndex(index))
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(rightDurations.enumerated()), id: \.offset) { index, duration in
                            scoreRow("\(duration)s", scores[duration] ?? 0, show: showForIndex(index))
                        }
                    }
                }
            )
        }
    }

    private func showForIndex(_ index: Int) -> Bool {
        switch index {
        case 0: return showFirstPair
        case 1: return showSecondPair
        default: return showThirdPair
        }
    }

    private var classicScoresContent: some View {
        HStack(spacing: layout.scoreboardColumnSpacing) {
            VStack(alignment: .leading, spacing: 10) {
                scoreRow("10s", highs.best[10] ?? 0, show: showFirstPair)
                scoreRow("20s", highs.best[20] ?? 0, show: showSecondPair)
                scoreRow("30s", highs.best[30] ?? 0, show: showThirdPair)
            }
            VStack(alignment: .leading, spacing: 10) {
                scoreRow("40s", highs.best[40] ?? 0, show: showFirstPair)
                scoreRow("50s", highs.best[50] ?? 0, show: showSecondPair)
                scoreRow("60s", highs.best[60] ?? 0, show: showThirdPair)
            }
        }
    }

    private func singleScoreContent(value: Int, label: String) -> some View {
        HStack(spacing: 8) {
            Text("\(value)")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(theme.textOnAccent)
            Text(label)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textOnAccent.opacity(0.7))
        }
        .opacity(showFirstPair ? 1 : 0)
        .scaleEffect(showFirstPair ? 1 : 0.8)
    }

    private var dailyScoreContent: some View {
        VStack(spacing: 8) {
            // Score display
            if let todayScore = highs.dailyTodayScore {
                HStack(spacing: 8) {
                    Text("\(todayScore)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(theme.textOnAccent)
                    Text("points")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textOnAccent.opacity(0.7))
                }
            } else {
                Text("Not played yet")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textOnAccent.opacity(0.5))
            }
        }
        .opacity(showFirstPair ? 1 : 0)
        .scaleEffect(showFirstPair ? 1 : 0.8)
    }

    // MARK: - Score Row Helper

    @ViewBuilder
    private func scoreRow(_ label: String, _ value: Int, show: Bool) -> some View {
        let timeMode = Int(label.replacingOccurrences(of: "s", with: "")) ?? 0
        let isCelebrating = celebratingMode == timeMode
        
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: rowLabelSize, weight: .medium, design: .rounded))
                .foregroundStyle(isCelebrating ? Color(hex: "#FFD700") : theme.textOnAccent.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text("------")
                .font(.system(size: rowLabelSize))
                .foregroundStyle(isCelebrating ? Color(hex: "#FFD700").opacity(0.7) : theme.textOnAccent.opacity(0.5))
            
            Text("\(value)")
                .font(.system(size: rowValueSize, weight: .bold, design: .rounded))
                .foregroundStyle(isCelebrating ? Color(hex: "#FFD700") : theme.textOnAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCelebrating ? Color(hex: "#FFD700").opacity(0.15 * glowIntensity) : .clear)
                    .blur(radius: 4)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCelebrating ? Color(hex: "#FFA500").opacity(0.08 * glowIntensity) : .clear)
                    .blur(radius: 8)
            }
        )
        .scaleEffect(isCelebrating ? (1.0 + 0.10 * glowIntensity) : 1.0)
        .shadow(
            color: isCelebrating ? Color(hex: "#FFD700").opacity(0.3 * glowIntensity) : .clear,
            radius: 10 * glowIntensity
        )
        .shadow(
            color: isCelebrating ? Color(hex: "#FFA500").opacity(0.2 * glowIntensity) : .clear,
            radius: 15 * glowIntensity
        )
        .opacity(show ? 1 : 0)
        .transition(.scale.combined(with: .opacity))
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
}

#Preview {
    @Previewable @State var expanded = false

    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()

        GeometryReader { geo in
            let layout = LayoutController(geo)

            HighScoreBoard(
                theme: .daylight,
                layout: layout,
                highs: HighscoreStore(),
                isRunning: false,
                isExpanded: $expanded,
                celebratingMode: 30,
                gameMode: .classic
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 100)
        }
    }
}
