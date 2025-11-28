//
//  MorphingTimerShape.swift
//  Poppy
//
//  Shape that smoothly morphs from horizontal bar to circle
//  Ends meet smoothly at top without flaring
//

import SwiftUI

struct MorphingTimerShape: Shape {
    var morphProgress: CGFloat  // 0.0 = bar, 1.0 = circle
    
    var animatableData: CGFloat {
        get { morphProgress }
        set { morphProgress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let centerX = rect.midX
        let centerY = rect.midY
        let radius = width / 2
        
        // Smooth curve needs lots of points
        let pointCount = 400
        
        var path = Path()
        
        for i in 0..<pointCount {
            let t = CGFloat(i) / CGFloat(pointCount - 1)
            
            // BAR POSITION (horizontal line from left to right)
            let barX = rect.minX + t * width
            let barY = centerY
            
            // CIRCLE POSITION (counter-clockwise from top)
            // Angle tuning: slightly less than 360° to prevent overlap/flare
            // but close enough to look visually complete
            let angleSpan: CGFloat = 359.85  // Very close to full circle
            let startAngle: CGFloat = 270.075  // Start just right of top
            let angleDegrees = startAngle - t * angleSpan
            let angleRadians = angleDegrees * .pi / 180
            
            let circleX = centerX + radius * cos(angleRadians)
            let circleY = centerY + radius * sin(angleRadians)
            
            // Simple linear interpolation - no tricks!
            let x = barX + (circleX - barX) * morphProgress
            let y = barY + (circleY - barY) * morphProgress
            
            let point = CGPoint(x: x, y: y)
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        return path
    }
}
