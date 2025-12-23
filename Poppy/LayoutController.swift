//
//  LayoutController.swift
//  Poppy
//
//  ⚠️ SINGLE SOURCE OF TRUTH FOR ALL SIZING ⚠️
//
//  Architecture: Base Unit System
//  - One master scale factor derived from screen size
//  - A small set of "base units" that everything derives from
//  - Proportional relationships instead of absolute values
//
//  Philosophy: Comfortable sizing over "filling the screen"
//  - iPad gets breathing room, not stretched layouts
//  - Game board stays at a playable, consistent size
//

import SwiftUI

struct LayoutController {
    // MARK: - Screen Info
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let safeTop: CGFloat
    let safeBottom: CGFloat
    let isIPad: Bool
    
    // MARK: - Master Scale
    /// The single scale factor everything derives from.
    /// Reference: iPhone 16 Pro (393 × 852)
    private var scale: CGFloat {
        let referenceWidth: CGFloat = 393
        let referenceHeight: CGFloat = 852
        
        let widthRatio = screenWidth / referenceWidth
        let heightRatio = screenHeight / referenceHeight
        let rawScale = min(widthRatio, heightRatio)
        
        // iPad: gentle scaling - we want comfortable, not huge
        // This keeps the game feeling like a focused play area, not stretched
        if isIPad {
            return 1.0 + (rawScale - 1.0) * 0.3  // Only take 30% of the extra scale
        }
        
        return rawScale
    }
    
    // MARK: - Base Units
    /// These are the foundational building blocks. Everything else derives from these.
    
    /// Base spacing unit (8pt on reference device)
    var unit: CGFloat { 8 * scale }
    
    /// Base text size (16pt on reference device)
    var baseText: CGFloat { 16 * scale }
    
    /// Base corner radius (12pt on reference device)
    var baseRadius: CGFloat { 12 * scale }
    
    /// Standard stroke width (doesn't scale - stays crisp)
    // MARK: - Standardized Stroke Width
    /// All strokes use 2pt for consistency
    let strokeWidth: CGFloat = 2

    // MARK: - Standardized Corner Radii
    /// Derived from baseRadius for consistent proportions
    var cornerRadiusSmall: CGFloat { baseRadius }           // 12pt - pills, small buttons
    var cornerRadiusMedium: CGFloat { baseRadius * 1.4 }    // ~17pt - cards, containers
    var cornerRadiusLarge: CGFloat { baseRadius * 1.8 }     // ~22pt - scoreboards, modals

    // MARK: - Standardized 3D Button Dimensions
    /// All 3D elements use the same offset for consistency
    var button3DHeight: CGFloat { unit * 7 }                // 56pt - visual button height
    var button3DLayerOffset: CGFloat { unit * 0.8 }         // ~6pt - universal 3D depth offset
    var button3DTotalHeight: CGFloat { button3DHeight + button3DLayerOffset }  // ~62pt - frame height

    // MARK: - Standardized Card Heights
    /// Use these for consistent header/card sizing across modes
    var cardHeightSmall: CGFloat { unit * 11 }              // 88pt - simple score cards (Tappy, Zoomy, Seeky)
    var cardHeightMedium: CGFloat { unit * 14 }             // 112pt - cards with 2 stats
    var cardHeightLarge: CGFloat { unit * 18 }              // 144pt - Daily card, rich content

    // MARK: - Standardized Spacing
    /// Common spacing values for consistent layouts
    var spacingTight: CGFloat { unit * 1 }                  // 8pt - within components
    var spacingNormal: CGFloat { unit * 2 }                 // 16pt - between related items
    var spacingLoose: CGFloat { unit * 3 }                  // 24pt - between sections

    // MARK: - Lives Display
    var livesHeartSize: CGFloat { baseText * 1.8 }          // ~29pt - consistent heart size
    var livesSpacing: CGFloat { unit * 1.5 }                // 12pt - space between hearts

    // MARK: - Content Layout
    
    /// Detect larger iPads (12.9" Pro has width of 1024pt in portrait)
    private var isLargeiPad: Bool {
        isIPad && screenWidth >= 1000
    }
    
    /// Detect medium iPads (11" Pro has width ~834pt in portrait)
    private var isMediumiPad: Bool {
        isIPad && screenWidth >= 800 && screenWidth < 1000
    }
    
    /// Maximum width for game content - keeps iPad feeling focused
    private var maxContentWidth: CGFloat {
        isLargeiPad ? 580 : 500
    }
    
    var contentWidth: CGFloat {
        if isIPad {
            return min(screenWidth * 0.75, maxContentWidth)
        }
        return screenWidth * 0.90
    }
    
    // ============================================
    // MARK: - Component Sizes (Derived from Base)
    // ============================================
    
    // MARK: Top Bar
    var topBarPaddingTop: CGFloat { unit * 0.6 }
    var topBarPaddingHorizontal: CGFloat { unit * 5 }
    var topBarButtonSize: CGFloat { unit * 4 }
    var topBarButtonStrokeWidth: CGFloat { strokeWidth }
    
    // MARK: Set Time Button
    var setTimeButtonHeight: CGFloat { unit * 4.5 }
    var setTimeButtonFontSize: CGFloat { baseText }
    var setTimeButtonPaddingH: CGFloat { unit * 2 }
    var setTimeButtonPaddingV: CGFloat { unit * 1.25 }
    var setTimeButtonStrokeWidth: CGFloat { 2 }
    var setTimeButtonCornerRadius: CGFloat { setTimeButtonHeight / 2 }
    
    // MARK: Scoreboard
    var scoreboardExpandedWidth: CGFloat {
        if isIPad {
            let maxWidth: CGFloat = isLargeiPad ? 500 : 420
            return min(contentWidth * 0.85, maxWidth)
        }
        return contentWidth * 0.90
    }
    
    var scoreboardCollapsedWidth: CGFloat { scoreboardExpandedWidth * 0.75 }
    
    var scoreboardExpandedHeight: CGFloat {
        if isLargeiPad {
            return unit * 32  // Taller on large iPad
        }
        return unit * 26
    }
    var scoreboardCollapsedHeight: CGFloat { unit * 8 }
    var scoreboardCornerRadius: CGFloat { baseRadius * 1.8 }
    var scoreboardLayerSpacing: CGFloat { -(unit * 1.75) }  // Negative for 3D offset
    var scoreboardStrokeWidth: CGFloat { 2 }
    
    var scoreboardTopPadding: CGFloat {
        if isIPad {
            return unit * 6  // More space from top bar on iPad
        }
        return unit * 5
    }
    
    var scoreboardTitleSize: CGFloat { baseText * 1.5 }
    var scoreboardLabelSize: CGFloat { baseText * 1.125 }
    var scoreboardValueSize: CGFloat { baseText * 1.25 }
    var scoreboardRowSpacing: CGFloat { unit * 1.25 }
    var scoreboardColumnSpacing: CGFloat { unit * 4 }

    /// Standardized height for all header cards (80pt)
    var headerCardHeight: CGFloat { unit * 10 }

    // MARK: Stats Display (Score/Time in center)
    var statsTopPadding: CGFloat {
        if isLargeiPad {
            return unit * 15  // More space on large iPad (12.9")
        }
        if isMediumiPad {
            return unit * 10  // Medium space on 11" iPad Pro
        }
        if isIPad {
            return unit * 5  // Standard iPad
        }
        return unit * 5
    }
    var statsHorizontalPadding: CGFloat { unit * 9 }
    var statsScoreSize: CGFloat { baseText * 2 }
    var statsLabelSize: CGFloat { baseText * 1.25 }
    var statsTimeSize: CGFloat { baseText * 1.4 }
    
    // Expanded state (scoreboard open)
    var expandedScoreLabelSize: CGFloat { baseText * 1.25 }
    var expandedScoreValueSize: CGFloat { baseText * 2.8 }
    var expandedTimeLabelSize: CGFloat { baseText * 1.25 }
    var expandedTimeValueSize: CGFloat { baseText * 2.8 }
    var expandedLabelOffsetY: CGFloat { unit * -9 }
    var expandedValueOffsetY: CGFloat { unit * -4 }
    var expandedSideOffsetX: CGFloat { isIPad ? unit * 12 : unit * 10 }
    
    // Collapsed state (scoreboard closed)
    var collapsedScoreLabelOffsetY: CGFloat { unit * -9 }
    var collapsedScoreValueOffsetY: CGFloat { unit * -0.6 }
    var collapsedTimeOffsetY: CGFloat { unit * 7 }
    
    // MARK: Timer Ring/Bar
    var ringDiameter: CGFloat { unit * 30 }
    var ringStrokeWidth: CGFloat { unit * 1.75 }
    var progressBarWidth: CGFloat { scoreboardExpandedWidth }
    var progressBarHeight: CGFloat { unit * 1.6 }
    
    // MARK: Board (Dot Grid)
    var boardWidth: CGFloat {
        if isIPad {
            let maxWidth: CGFloat = isLargeiPad ? 500 : 480
            return min(contentWidth, maxWidth)
        }
        return contentWidth * 0.90  // 90% of content width on iPhone
    }
    
    var boardHeight: CGFloat {
        if isIPad {
            return unit * 30  // Reduced to make room
        }
        return unit * 31
    }
    
    var boardBottomPadding: CGFloat {
        if isIPad {
            return unit * 14  // More space to push dots up
        }
        return unit * 4  // Push dots up from START button
    }
    
    var dotSpacingHorizontal: CGFloat { unit * 2.25 }
    var dotSpacingVertical: CGFloat { unit * 1.25 }
    var dotSideInset: CGFloat { unit * 0.75 }
    
    // MARK: Dot Sprite
    var dotLayerOffset: CGFloat { button3DLayerOffset }  // Use universal 3D offset
    var dotStrokeWidth: CGFloat { 2 }
    var dotPadding: CGFloat { unit * 0.5 }
    var dotGlowRadius: CGFloat { unit * 3.25 }
    let dotGlowOpacity: Double = 0.12
    let dotActiveTintOpacity: Double = 0.85
    let dotInactiveTintOpacity: Double = 0.03
    
    // MARK: Start Button
    var startButtonWidth: CGFloat {
        if isIPad {
            let maxWidth: CGFloat = isLargeiPad ? 520 : 450
            return min(screenWidth * 0.55, maxWidth)
        }
        return screenWidth * 0.75
    }
    
    var startButtonVisibleWidth: CGFloat { startButtonWidth * 0.75 }
    var startButtonHeight: CGFloat { unit * 12 }
    var startButtonCornerRadius: CGFloat { baseRadius * 1.7 }
    var startButtonLayerOffset: CGFloat { button3DLayerOffset }  // Use universal 3D offset
    var startButtonStrokeWidth: CGFloat { 2 }
    var startButtonHorizontalPadding: CGFloat { unit * 2 }
    var startButtonBottomPadding: CGFloat {
        if isIPad {
            return unit * 3  // More padding from bottom edge on iPad
        }
        return unit * 0.6
    }
    var startButtonTitleSize: CGFloat { baseText * 2.25 }
    var startButtonGlowRadius: CGFloat { unit * 1 }
    let startButtonGlowOpacity: Double = 0.25
    
    // ============================================
    // MARK: - Initialization
    // ============================================
    
    init(_ geo: GeometryProxy) {
        self.screenWidth = geo.size.width
        self.screenHeight = geo.size.height
        self.safeTop = geo.safeAreaInsets.top
        self.safeBottom = geo.safeAreaInsets.bottom
        self.isIPad = UIDevice.current.userInterfaceIdiom == .pad
    }

    /// Preview-friendly initializer with explicit values
    init(screenWidth: CGFloat, screenHeight: CGFloat, safeTop: CGFloat, safeBottom: CGFloat, isIPad: Bool) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.safeTop = safeTop
        self.safeBottom = safeBottom
        self.isIPad = isIPad
    }

    /// Convenience for SwiftUI previews
    static var preview: LayoutController {
        LayoutController(screenWidth: 393, screenHeight: 852, safeTop: 59, safeBottom: 34, isIPad: false)
    }
    
    // ============================================
    // MARK: - Debug
    // ============================================
    
    var debugInfo: String {
        """
        Screen: \(Int(screenWidth))×\(Int(screenHeight))
        Scale: \(String(format: "%.2f", scale))x
        Unit: \(String(format: "%.1f", unit))pt
        iPad: \(isIPad)
        Content: \(Int(contentWidth))pt
        Board: \(Int(boardWidth))pt
        Scoreboard: \(Int(scoreboardExpandedWidth))pt
        """
    }
}
