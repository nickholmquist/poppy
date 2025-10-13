//
//  LayoutMetrics.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/9/25.
//


import SwiftUI

struct LayoutMetrics {
    enum Bucket { case compact, medium, large }

    // raw
    let width: CGFloat
    let height: CGFloat
    let safeTop: CGFloat
    let safeBottom: CGFloat

    // derived
    let bucket: Bucket
    var compact: Bool { bucket == .compact }

    // main content width
    let maxW: CGFloat

    // scoreboard
    let scoreboardW: CGFloat
    let scoreboardH: CGFloat   // derived from width

    // board
    let boardH: CGFloat
    let boardCapW: CGFloat     // new - max grid width for BoardView

    // start button
    let startH: CGFloat

    // spacing
    let stackSpacing: CGFloat
    let titleToBoard: CGFloat
    let statsTop: CGFloat
    let statsSide: CGFloat
    let boardToButtonGap: CGFloat

    init(_ geo: GeometryProxy) {
        width = geo.size.width
        height = geo.size.height
        safeTop = geo.safeAreaInsets.top
        safeBottom = geo.safeAreaInsets.bottom

        // Height buckets - roughly 16e / 15 Pro / Pro Max
        if height < 770 { bucket = .compact }
        else if height < 860 { bucket = .medium }
        else { bucket = .large }

        // Max content width
        maxW = min(width * 0.9, 520)

        // Scoreboard width as a percent of maxW
        let sbPercent: CGFloat
        switch bucket {
        case .compact: sbPercent = 0.94
        case .medium:  sbPercent = 0.98
        case .large:   sbPercent = 0.98
        }
        scoreboardW = maxW * sbPercent

        // Native art aspect ~ 1564x740 -> 2.114
        let aspect: CGFloat = 1564.0 / 740.0
        let proportionalH = scoreboardW / aspect

        // Clamp by bucket so it never gets tiny
        let minH: CGFloat
        let maxH: CGFloat
        switch bucket {
        case .compact: minH = 230; maxH = 240
        case .medium:  minH = 230; maxH = 270
        case .large:   minH = 250; maxH = 280
        }
        scoreboardH = min(max(proportionalH, minH), maxH)

        // Board height - leave near your previous feel
        switch bucket {
        case .compact: boardH = 190
        case .medium:  boardH = 200
        case .large:   boardH = 260
        }

        // Board cap width - track with scoreboard so their visual sizes feel tied
        let boardPercent: CGFloat
        switch bucket {
        case .compact: boardPercent = 0.92
        case .medium:  boardPercent = 0.93
        case .large:   boardPercent = 0.94
        }
        boardCapW = maxW * boardPercent

        // Start button height
        switch bucket {
        case .compact: startH = 100
        case .medium:  startH = 112
        case .large:   startH = 122
        }

        // Spacing
        switch bucket {
        case .compact:
            stackSpacing = 0
            titleToBoard = 10
            statsTop = 20
            statsSide = 44
            boardToButtonGap = -6
        case .medium:
            stackSpacing = 0
            titleToBoard = 14
            statsTop = 26
            statsSide = 58
            boardToButtonGap = -8
        case .large:
            stackSpacing = 0
            titleToBoard = 18
            statsTop = 30
            statsSide = 70
            boardToButtonGap = -10
        }
    }
}
