//
//  LayoutController.swift
//  Poppy
//
//  Unified layout system - ALL sizing decisions in one place
//

import SwiftUI

struct LayoutController {
    // Device detection
    let isIPad: Bool
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let safeTop: CGFloat
    let safeBottom: CGFloat
    
    // MARK: - Content Width
    var contentWidth: CGFloat {
        if isIPad {
            return min(screenWidth * 0.7, 500)
        } else {
            return min(screenWidth * 0.9, 520)
        }
    }
    
    // MARK: - Top Bar
    var topBarPaddingTop: CGFloat {
        isIPad ? 8 : (screenHeight < 770 ? 4 : 5)
    }
    
    var topBarPaddingHorizontal: CGFloat { 40 }
    
    var topBarTitleSize: CGFloat {
        if isIPad {
            return 36
        } else {
            return screenHeight < 770 ? 34 : 30
        }
    }
    
    // MARK: - Scoreboard
    var scoreboardWidth: CGFloat {
        if isIPad {
            return contentWidth * 0.90
        } else {
            let percent: CGFloat = screenHeight < 770 ? 0.88 : 0.90
            return contentWidth * percent
        }
    }
    
    var scoreboardHeight: CGFloat {
        let aspect: CGFloat = 1564.0 / 740.0
        let proportionalH = scoreboardWidth / aspect
        
        if isIPad {
            return min(max(proportionalH, 360), 420)
        } else if screenHeight < 770 {
            return min(max(proportionalH, 230), 240)
        } else if screenHeight < 860 {
            return min(max(proportionalH, 230), 270)
        } else {
            return min(max(proportionalH, 250), 280)
        }
    }
    
    var scoreboardTopPadding: CGFloat {
        if isIPad {
            return 25
        } else if screenHeight < 770 {
            return 10
        } else {
            return 30
        }
    }
    
    // MARK: - Scoreboard Text Sizing
    var scoreboardTitleSize: CGFloat {
        if isIPad {
            return 36
        } else {
            return min(24, scoreboardHeight * 0.12)
        }
    }
    
    var scoreboardLabelSize: CGFloat {
        if isIPad {
            return 26
        } else {
            return min(18, scoreboardHeight * 0.09)
        }
    }
    
    var scoreboardValueSize: CGFloat {
        if isIPad {
            return 30
        } else {
            return min(20, scoreboardHeight * 0.10)
        }
    }
    
    // MARK: - Stats Row (Score/Time)
    var statsTopPadding: CGFloat {
        if isIPad {
            return 25
        } else if screenHeight < 770 {
            return 20
        } else if screenHeight < 860 {
            return 15
        } else {
            return 25
        }
    }
    
    var statsHorizontalPadding: CGFloat {
        if isIPad {
            return 50
        } else if screenHeight < 770 {
            return 44
        } else if screenHeight < 860 {
            return 58
        } else {
            return 70
        }
    }
    
    var statsScoreSize: CGFloat {
        if isIPad {
            return 40
        } else {
            return screenHeight < 770 ? 36 : 35
        }
    }
    
    // MARK: - Board (Dot Grid)
    var boardWidth: CGFloat {
        if isIPad {
            return contentWidth * 0.95
        } else {
            return contentWidth * 0.90
        }
    }
    
    var boardHeight: CGFloat {
        if isIPad {
            return 420
        } else if screenHeight < 770 {
            return 190
        } else if screenHeight < 860 {
            return 200
        } else {
            return 260
        }
    }
    
    var boardBottomPadding: CGFloat {
        if isIPad {
            return -40
        } else if screenHeight < 770 {
            return 35
        } else if screenHeight < 860 {
            return 35
        } else {
            return 0
        }
    }
    
    // Dot sizing within the board
    var dotSpacingHorizontal: CGFloat {
        isIPad ? 24 : 18
    }
    
    var dotSpacingVertical: CGFloat {
        isIPad ? 14 : 10
    }
    
    var dotSideInset: CGFloat {
        isIPad ? 8 : 6
    }
    
    // MARK: - Start Button
    var startButtonWidth: CGFloat {
        let safeW = max(1, screenWidth)
        return max(44, min(safeW - 32, isIPad ? 400 : 500))
    }
    
    var startButtonHeight: CGFloat {
        if isIPad {
            return 100
        } else if screenHeight < 770 {
            return 90
        } else if screenHeight < 860 {
            return 100
        } else {
            return 110
        }
    }
    
    var startButtonHorizontalPadding: CGFloat { 16 }
    var startButtonBottomPadding: CGFloat { 10 }
    
    var startButtonTitleSize: CGFloat {
        isIPad ? 44 : 40
    }
    
    // MARK: - Initialization
    init(_ geo: GeometryProxy) {
        self.screenWidth = geo.size.width
        self.screenHeight = geo.size.height
        self.safeTop = geo.safeAreaInsets.top
        self.safeBottom = geo.safeAreaInsets.bottom
        self.isIPad = UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // Helper for views that need to know device type
    var isCompact: Bool {
        !isIPad && screenHeight < 770
    }
}
