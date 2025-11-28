//
//  LayoutController.swift
//  Poppy
//
//  ⚠️ SINGLE SOURCE OF TRUTH FOR ALL SIZING ⚠️
//  DEVICE CATEGORY SYSTEM: iPhone mini → iPad Pro 13"
//

import SwiftUI

struct LayoutController {
    // MARK: - Device Detection
    let isIPad: Bool
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let safeTop: CGFloat
    let safeBottom: CGFloat
    
    // MARK: - Device Categories
    enum DeviceCategory {
        case iPhoneMini        // iPhone 12/13 mini
        case iPhoneStandard    // iPhone 12-16 standard
        case iPhoneMax         // iPhone 12-16 Pro Max/Plus
        case iPadMini          // iPad mini
        case iPadStandard      // iPad 10th gen, iPad Air, iPad 9th gen
        case iPadPro11         // iPad Pro 11"
        case iPadPro13         // iPad Pro 12.9"/13"
        
        var name: String {
            switch self {
            case .iPhoneMini: return "iPhone mini"
            case .iPhoneStandard: return "iPhone Standard"
            case .iPhoneMax: return "iPhone Max"
            case .iPadMini: return "iPad mini"
            case .iPadStandard: return "iPad Standard"
            case .iPadPro11: return "iPad Pro 11\""
            case .iPadPro13: return "iPad Pro 13\""
            }
        }
    }
    
    // Detect device category
    var deviceCategory: DeviceCategory {
        if isIPad {
            if screenWidth >= 1024 {
                return .iPadPro13
            } else if screenWidth >= 834 {
                return .iPadPro11
            } else if screenWidth >= 744 {
                // iPad mini is 744, iPad 9th gen is 810, iPad 10th gen is 820
                return .iPadStandard
            } else {
                return .iPadMini
            }
        } else {
            if screenWidth >= 415 {
                return .iPhoneMax
            } else if screenWidth <= 380 {
                return .iPhoneMini
            } else {
                return .iPhoneStandard
            }
        }
    }
    
    // MARK: - Reference Device (iPhone 16 Pro)
    private let referenceWidth: CGFloat = 393
    private let referenceHeight: CGFloat = 852
    
    // MARK: - Scale Factors
    private var widthScale: CGFloat {
        screenWidth / referenceWidth
    }
    
    private var heightScale: CGFloat {
        screenHeight / referenceHeight
    }
    
    private var minScale: CGFloat {
        min(widthScale, heightScale)
    }
    
    // MARK: - iPad Scale Factor
    // iPads use a gentler scale factor to prevent over-sizing
    private var iPadScale: CGFloat {
        let rawScale = min(widthScale, heightScale)
        
        // Larger iPads need more aggressive dampening
        switch deviceCategory {
        case .iPadPro13:
            // 13" iPads: very aggressive dampening
            return pow(rawScale, 0.35)  // e.g., 1.5 becomes ~1.15
        case .iPadPro11:
            // 11" iPads: moderate dampening
            return pow(rawScale, 0.4)  // e.g., 1.3 becomes ~1.11
        case .iPadStandard, .iPadMini:
            // Standard/mini iPads: gentle dampening
            return sqrt(rawScale)  // e.g., 1.27 becomes 1.13
        default:
            return sqrt(rawScale)
        }
    }
    
    // MARK: - Helper Functions
    private func scaled(_ value: CGFloat) -> CGFloat {
        if isIPad {
            return value * iPadScale
        }
        return value * minScale
    }
    
    private func scaledWidth(_ value: CGFloat) -> CGFloat {
        if isIPad {
            return value * iPadScale
        }
        return value * widthScale
    }
    
    private func scaledHeight(_ value: CGFloat) -> CGFloat {
        if isIPad {
            return value * iPadScale
        }
        return value * heightScale
    }
    
    // ========================================
    // MARK: - Content Width (Global)
    // ========================================
    
    var contentWidth: CGFloat {
        screenWidth * 0.90  // 90% of screen width
    }
    
    // ========================================
    // MARK: - Top Bar (Theme/Menu/Set Time)
    // ========================================
    
    var topBarPaddingTop: CGFloat {
        scaledHeight(5)
    }
    
    var topBarPaddingHorizontal: CGFloat {
        scaledWidth(40)
    }
    
    var topBarButtonSize: CGFloat {
        scaled(32)
    }
    
    var topBarButtonStrokeWidth: CGFloat {
        2.5
    }
    
    // Set Time button (pill-shaped)
    var setTimeButtonWidth: CGFloat {
        scaledWidth(180)
    }
    
    var setTimeButtonHeight: CGFloat {
        scaledHeight(37)
    }
    
    var setTimeButtonFontSize: CGFloat {
        scaled(16)
    }
    
    var setTimeButtonPaddingH: CGFloat {
        scaledWidth(16)
    }
    
    var setTimeButtonPaddingV: CGFloat {
        scaledHeight(10)
    }
    
    var setTimeButtonStrokeWidth: CGFloat {
        2
    }
    
    var setTimeButtonCornerRadius: CGFloat {
        setTimeButtonHeight / 2
    }
    
    // ========================================
    // MARK: - High Score Board
    // ========================================
    
    var scoreboardExpandedWidth: CGFloat {
        if isIPad {
            return contentWidth * 0.70  // iPad: 70% of content width
        } else {
            return contentWidth * 0.90  // iPhone: stays at 90%
        }
    }
    
    var scoreboardExpandedHeight: CGFloat {
        if isIPad {
            return scaledHeight(230)  // iPad: taller for bigger content
        } else {
            return scaledHeight(210)  // iPhone: stays at 210
        }
    }
    
    var scoreboardCollapsedWidth: CGFloat {
        scoreboardExpandedWidth * 0.75
    }
    
    var scoreboardCollapsedHeight: CGFloat {
        scaledHeight(64)  // Increased from 54 to 64 for more height
    }
    
    var scoreboardCornerRadius: CGFloat {
        scaled(22)
    }
    
    var scoreboardLayerSpacing: CGFloat {
        scaled(-14)
    }
    
    var scoreboardStrokeWidth: CGFloat {
        3
    }
    
    var scoreboardTopPadding: CGFloat {
        if isIPad {
            return 60  // Fixed padding to push scoreboard down on iPad
        } else {
            return scaledHeight(45)  // iPhone: stays at 45
        }
    }
    
    // Text sizing within scoreboard
    var scoreboardTitleSize: CGFloat {
        if isIPad {
            return scaled(32)  // iPad: bigger title
        } else {
            return scaled(24)  // iPhone: stays at 24
        }
    }
    
    var scoreboardLabelSize: CGFloat {
        if isIPad {
            return scaled(24)  // iPad: bigger labels
        } else {
            return scaled(18)  // iPhone: stays at 18
        }
    }
    
    var scoreboardValueSize: CGFloat {
        if isIPad {
            return scaled(26)  // iPad: bigger values
        } else {
            return scaled(20)  // iPhone: stays at 20
        }
    }
    
    var scoreboardRowSpacing: CGFloat {
        if isIPad {
            return scaledHeight(14)  // iPad: more space between rows
        } else {
            return scaledHeight(8)  // iPhone: stays at 8
        }
    }
    
    var scoreboardColumnSpacing: CGFloat {
        if isIPad {
            return scaledWidth(65)  // iPad: more space between columns
        } else {
            return scaledWidth(30)  // iPhone: stays at 50
        }
    }
    
    // ========================================
    // MARK: - Stats Display (Score/Time)
    // ========================================
    
    var statsTopPadding: CGFloat {
        if isIPad {
            return 60  // Fixed padding to push stats down on iPad
        } else {
            return scaledHeight(50)  // Original padding on iPhone
        }
    }
    
    var statsHorizontalPadding: CGFloat {
        scaledWidth(70)
    }
    
    var statsScoreSize: CGFloat {
        scaled(32)
    }
    
    var statsLabelSize: CGFloat {
        scaled(20)
    }
    
    var statsTimeSize: CGFloat {
        scaled(22)
    }
    
    // EXPANDED STATE (when scoreboard is open) - iPad gets bigger fonts
    var expandedScoreLabelSize: CGFloat {
        if isIPad {
            return scaled(22)  // Reduced from 24
        } else {
            return scaled(20)
        }
    }
    
    var expandedScoreValueSize: CGFloat {
        if isIPad {
            return scaled(48)  // Reduced from 55 to give more breathing room
        } else {
            return scaled(45)
        }
    }
    
    var expandedTimeLabelSize: CGFloat {
        if isIPad {
            return scaled(22)  // Reduced from 24
        } else {
            return scaled(20)
        }
    }
    
    var expandedTimeValueSize: CGFloat {
        if isIPad {
            return scaled(48)  // Reduced from 55 to match score
        } else {
            return scaled(45)
        }
    }
    
    // Vertical positioning for expanded state
    var expandedLabelOffsetY: CGFloat {
        if isIPad {
            return -78  // Slightly lower from -85
        } else {
            return -70
        }
    }
    
    var expandedValueOffsetY: CGFloat {
        if isIPad {
            return -32  // Closer to label (was -25)
        } else {
            return -35
        }
    }
    
    var expandedSideOffsetX: CGFloat {
        if isIPad {
            return 120  // Much more spread on iPad to prevent squishing
        } else {
            return 80
        }
    }
    
    // Collapsed state - score label position (above the big number)
    var collapsedScoreLabelOffsetY: CGFloat {
        if isIPad {
            return -75  // Much higher on iPad
        } else {
            return -70  // Higher on iPhone too
        }
    }
    
    // Collapsed state - score value position (the big number)
    var collapsedScoreValueOffsetY: CGFloat {
        if isIPad {
            return -10  // Better centered on iPad
        } else {
            return -5  // Better centered on iPhone
        }
    }
    
    // Collapsed state - time position (below the big number)
    var collapsedTimeOffsetY: CGFloat {
        if isIPad {
            return 58  // Closer to score on iPad
        } else {
            return 55  // Closer to score on iPhone
        }
    }
    
    // ========================================
    // MARK: - Timer Display (Bar & Ring)
    // ========================================
    
    var ringDiameter: CGFloat {
        if isIPad {
            return scaled(200)  // Smaller on iPad
        } else {
            return scaled(240)  // Original size on iPhone
        }
    }
    
    var ringStrokeWidth: CGFloat {
        // Thinner on iPad
        if isIPad {
            return scaled(10)
        } else {
            return scaled(14)
        }
    }
    
    var progressBarWidth: CGFloat {
        scoreboardExpandedWidth
    }
    
    var progressBarHeight: CGFloat {
        // Thinner on iPad
        if isIPad {
            return scaled(10)
        } else {
            return scaled(13)
        }
    }
    
    // ========================================
    // MARK: - Board (Dot Grid)
    // ========================================
    
    var boardWidth: CGFloat {
        if isIPad {
            switch deviceCategory {
            case .iPadPro13:
                return contentWidth * 0.50  // Smaller on 13" iPads
            case .iPadPro11:
                return contentWidth * 0.55  // Smaller on 11" iPads
            default:
                return contentWidth * 0.65  // Standard iPads
            }
        } else {
            return contentWidth * 0.90  // iPhone: stays at 90%
        }
    }
    
    var boardHeight: CGFloat {
        scaledHeight(250)
    }
    
    var boardBottomPadding: CGFloat {
        if isIPad {
            switch deviceCategory {
            case .iPadPro13:
                return 120  // More padding on 13" iPads
            case .iPadPro11:
                return 100  // More padding on 11" iPads
            default:
                return 90   // Standard iPads
            }
        } else {
            return scaledHeight(15)
        }
    }
    
    var dotSpacingHorizontal: CGFloat {
        scaledWidth(18)
    }
    
    var dotSpacingVertical: CGFloat {
        scaledHeight(10)
    }
    
    var dotSideInset: CGFloat {
        scaledWidth(6)
    }
    
    // ========================================
    // MARK: - Dot Sprite Styling
    // ========================================
    
    var dotLayerOffset: CGFloat {
        scaled(8)
    }
    
    var dotStrokeWidth: CGFloat {
        2
    }
    
    var dotPadding: CGFloat {
        scaled(4)
    }
    
    var dotActiveTintOpacity: Double {
        0.85  // Vibrant accent color
    }
    
    var dotInactiveTintOpacity: Double {
        0.03  // Very light, almost white/neutral
    }
    
    var dotGlowRadius: CGFloat {
        scaled(26)
    }
    
    var dotGlowOpacity: Double {
        0.12
    }
    
    // ========================================
    // MARK: - Start Button
    // ========================================
    
    var startButtonWidth: CGFloat {
        if isIPad {
            return screenWidth * 0.55  // 55% of screen width on iPad
        } else {
            return screenWidth * 0.75  // iPhone: stays at 75%
        }
    }
    
    var startButtonHeight: CGFloat {
        if isIPad {
            return scaledHeight(85)
        } else {
            return scaledHeight(95)  // iPhone: stays at 95
        }
    }
    
    // The actual visible button width (used internally by StartButton)
    var startButtonVisibleWidth: CGFloat {
        startButtonWidth * 0.75
    }
    
    var startButtonCornerRadius: CGFloat {
        scaled(20)
    }
    
    var startButtonLayerOffset: CGFloat {
        scaled(12)
    }
    
    var startButtonStrokeWidth: CGFloat {
        3
    }
    
    var startButtonHorizontalPadding: CGFloat {
        scaledWidth(16)
    }
    
    var startButtonBottomPadding: CGFloat {
        scaledHeight(5)
    }
    
    var startButtonTitleSize: CGFloat {
        scaled(36)
    }
    
    var startButtonGlowRadius: CGFloat {
        scaled(15)
    }
    
    var startButtonGlowOpacity: Double {
        0.4
    }
    
    // ========================================
    // MARK: - INITIALIZATION
    // ========================================
    
    init(_ geo: GeometryProxy) {
        self.screenWidth = geo.size.width
        self.screenHeight = geo.size.height
        self.safeTop = geo.safeAreaInsets.top
        self.safeBottom = geo.safeAreaInsets.bottom
        self.isIPad = UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // ========================================
    // MARK: - Helper Properties
    // ========================================
    
    var isCompact: Bool {
        screenHeight < 800
    }
    
    var debugInfo: String {
        """
        Device: \(deviceCategory.name)
        Screen: \(Int(screenWidth))×\(Int(screenHeight))
        Width Scale: \(String(format: "%.2f", widthScale))x
        Height Scale: \(String(format: "%.2f", heightScale))x
        iPad Scale: \(String(format: "%.2f", isIPad ? iPadScale : minScale))x
        Scoreboard: \(Int(scoreboardExpandedWidth))×\(Int(scoreboardExpandedHeight))
        Board: \(Int(boardWidth))×\(Int(boardHeight))
        Start Button: \(Int(startButtonWidth))×\(Int(startButtonHeight))
        Ring Stroke: \(Int(ringStrokeWidth))pt
        Progress Bar: \(Int(progressBarHeight))pt
        """
    }
}
