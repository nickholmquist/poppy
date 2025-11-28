//
//  MorphingTimerShape.swift
//  Poppy
//
//  Shape that morphs from horizontal bar to circular ring
//

import SwiftUI

struct MorphingTimerShape: Shape {
    // 0.0 = horizontal bar, 1.0 = circular ring
    var morphProgress: CGFloat
    
    var animatableData: CGFloat {
        get { morphProgress }
        set { morphProgress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        // Interpolate the vertical scale: 0.0 = flat bar, 1.0 = full circle
        // Use a minimum scale so the path never completely disappears
        let verticalScale = 0.05 + (morphProgress * 0.95)
        
        // Calculate the ellipse dimensions
        let ellipseWidth = width
        let ellipseHeight = height * verticalScale
        
        // Center the ellipse
        let ellipseRect = CGRect(
            x: rect.midX - ellipseWidth / 2,
            y: rect.midY - ellipseHeight / 2,
            width: ellipseWidth,
            height: ellipseHeight
        )
        
        // Create an elliptical path
        var path = Path()
        path.addEllipse(in: ellipseRect)
        
        return path
    }
}