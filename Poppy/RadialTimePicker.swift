//
//  RadialTimePicker.swift
//  Poppy v1.1
//
//  Radial dial time selector with swipe-to-select mechanics
//

import SwiftUI
import Darwin

struct RadialTimePicker: View {
    let theme: Theme
    @Binding var show: Bool
    @Binding var selected: Int?
    let onConfirm: (Int) -> Void
    
    let times = [10, 20, 30, 40, 50, 60]
    @State private var selectedIndex: Int = 2 // Start at 30s
    @State private var startX: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var scale: CGFloat = 0.01 // Start very small for bloom
    @State private var backgroundOpacity: Double = 0
    @State private var bloomOffset: CGSize = .zero // For bloom-from-time animation
    @State private var timePositionOffset: CGSize = .zero // Store time position for bloom/dismiss
    @State private var selectedTimeSlideOffset: CGFloat = 0 // Slide animation for selected time
    @State private var shouldAnimateRotation: Bool = false // Only animate rotation on swipe, not initial bloom
    @State private var blurRadius: CGFloat = 0 // Blur during morph transition
    
    private let dialRadius: CGFloat = 224.5 // From Figma: 449px diameter
    
    private var selectedTime: Int {
        times[selectedIndex]
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background dim - SOLID black
                Color.black
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissPicker()
                    }
                
                // Radial dial - all elements grouped together to scale as one unit
                ZStack {
                    // Container frame that defines the dial's size
                    Color.clear
                        .frame(width: dialRadius * 2, height: dialRadius * 2)
                    
                    // Dial background - radial gradient for depth
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.bgTop.opacity(0.85),
                                    theme.bgTop
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: dialRadius
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(theme.textDark.opacity(0.25), lineWidth: 3)
                        )
                        .shadow(color: theme.shadow.opacity(0.4), radius: 30, y: 15)
                    
                    // Curved arrow indicator - engraved look, rotates with selection
                    CurvedArrow(radius: dialRadius * 0.75)
                        .stroke(theme.textDark.opacity(0.2), lineWidth: 5)
                        .overlay(
                            CurvedArrow(radius: dialRadius * 0.75)
                                .stroke(theme.textDark.opacity(0.08), lineWidth: 3)
                                .blur(radius: 1)
                                .offset(x: 1, y: 1)
                        )
                        .overlay(
                            CurvedArrow(radius: dialRadius * 0.75)
                                .stroke(.white.opacity(0.4), lineWidth: 1)
                                .blur(radius: 0.5)
                                .offset(x: -1, y: -1)
                        )
                        .rotationEffect(.degrees(Double(selectedIndex) * 30))
                        .animation(shouldAnimateRotation ? .spring(response: 0.4, dampingFraction: 0.75) : nil, value: selectedIndex)
                
                    // Time labels - positioned relative to center
                    ForEach(times.indices, id: \.self) { index in
                        timeLabel(for: index)
                    }
                    
                    // Confirm button in center
                    Button(action: {
                        selected = selectedTime
                        onConfirm(selectedTime)
                        dismissPicker()
                    }) {
                        ZStack {
                            Circle()
                                .fill(theme.bgBottom)
                                .frame(width: 65, height: 65)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(theme.textDark)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: dialRadius * 2, height: dialRadius * 2)
                .scaleEffect(scale)
                .blur(radius: blurRadius)
                .offset(bloomOffset)
                .position(
                    x: geo.size.width * 0.6107,
                    y: geo.size.height * 0.4137
                )
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            handleSwipe(value)
                        }
                        .onEnded { _ in
                            isDragging = false
                        }
                )
            }
            .onAppear {
                // Set initial selected index based on current selection
                if let currentTime = selected,
                   let index = times.firstIndex(of: currentTime) {
                    selectedIndex = index
                }
                
                // Calculate where the time number is on the main screen
                let dialCenterX = geo.size.width * 0.6107
                let dialCenterY = geo.size.height * 0.4137
                
                // Time position on main screen (right side)
                let timeX = geo.size.width * 0.704
                let timeY = geo.size.height * 0.46
                
                // Calculate starting offset (from time position to dial center)
                let timeOffset = CGSize(
                    width: timeX - dialCenterX,
                    height: timeY - dialCenterY
                )
                
                timePositionOffset = timeOffset
                bloomOffset = timeOffset
                
                // Start selected time far to the right (extra slide distance)
                selectedTimeSlideOffset = 150
                
                // Start with blur for morph effect
                blurRadius = 20
                
                // Multi-stage morph animation:
                // 1. Quick blur dissolve (morph feeling)
                withAnimation(.easeOut(duration: 0.2)) {
                    blurRadius = 8
                }
                
                // 2. Dial blooms and clears
                withAnimation(.spring(response: 0.6, dampingFraction: 0.72).delay(0.1)) {
                    scale = 1.0
                    bloomOffset = .zero
                    backgroundOpacity = 0.75
                    blurRadius = 0
                }
                
                // 3. Selected time slides in
                withAnimation(.spring(response: 0.65, dampingFraction: 0.78).delay(0.2)) {
                    selectedTimeSlideOffset = 0
                }
                
                // 4. Enable rotation animations AFTER bloom completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    shouldAnimateRotation = true
                }
            }
        }
    }
    
    // MARK: - Time Label View
    
    @ViewBuilder
    private func timeLabel(for index: Int) -> some View {
        let angleDegrees = angleForTime(at: index)
        let angle = Angle(degrees: angleDegrees)
        // Position at 75% of radius so times fit comfortably inside the circle
        let position = positionForAngle(angle, radius: dialRadius * 0.75)
        let isSelected = index == selectedIndex
        
        Text("\(times[index])s")
            .font(.system(size: isSelected ? 44 : 24, weight: .black, design: .rounded))
            .foregroundStyle(isSelected ? theme.accent : theme.textDark.opacity(0.6))
            .scaleEffect(isSelected ? 1.0 : 0.85)
            .shadow(color: isSelected ? theme.accent.opacity(0.5) : .clear, radius: 12, x: 0, y: 0)
            .offset(
                x: position.x + (isSelected ? selectedTimeSlideOffset : 0),
                y: position.y
            )
            // Only animate position changes when user swipes, not on initial appearance
            .animation(shouldAnimateRotation ? .spring(response: 0.4, dampingFraction: 0.75) : nil, value: selectedIndex)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedTimeSlideOffset)
    }
    
    /// Calculate angle for a time at given index
    /// Selected time is ALWAYS at 180° (left/9 o'clock in screen coordinates)
    /// Others are offset by 30° increments clockwise
    private func angleForTime(at index: Int) -> Double {
        let offset = index - selectedIndex
        let rawAngle = 180.0 + Double(offset) * 30.0
        
        // Normalize to 0-360 range using modulo
        let normalized = rawAngle.truncatingRemainder(dividingBy: 360)
        return normalized < 0 ? normalized + 360 : normalized
    }
    
    // MARK: - Geometry Calculations
    
    /// Convert angle to x,y position on circle
    private func positionForAngle(_ angle: Angle, radius: CGFloat? = nil) -> CGPoint {
        let r = radius ?? dialRadius
        let radians = angle.radians
        let x = r * cos(radians)
        let y = r * sin(radians)
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Swipe Handling
    
    private func handleSwipe(_ value: DragGesture.Value) {
        if !isDragging {
            isDragging = true
            startX = value.location.x
        }
        
        let delta = value.location.x - startX
        
        // Swipe threshold - 35 points for comfortable swiping
        if abs(delta) > 35 {
            if delta > 0 && selectedIndex > 0 {
                // Swipe right - go to previous time (counterclockwise)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                
                // Animate new selection sliding in from right
                selectedTimeSlideOffset = 150
                selectedIndex -= 1
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    selectedTimeSlideOffset = 0
                }
                
                startX = value.location.x
            } else if delta < 0 && selectedIndex < times.count - 1 {
                // Swipe left - go to next time (clockwise)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                
                // Animate new selection sliding in from right
                selectedTimeSlideOffset = 150
                selectedIndex += 1
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    selectedTimeSlideOffset = 0
                }
                
                startX = value.location.x
            }
        }
    }
    
    // MARK: - Dismiss Animation
    
    private func dismissPicker() {
        // Reverse morph: blur, slide, and shrink back
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            selectedTimeSlideOffset = 150
            scale = 0.01
            bloomOffset = timePositionOffset
            backgroundOpacity = 0
            blurRadius = 15  // Blur as it shrinks for morph effect
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            show = false
        }
    }
}

// MARK: - Curved Arrow Shape

/// Curved arrow that points to the left (180°) when rotation is 0°
/// Rotates with the selected time to always point at the current selection
struct CurvedArrow: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        // Arc from bottom-left, curving up to the left side (pointing position)
        // Start angle: 210° (bottom-left)
        // End angle: 180° (left - where arrow points)
        let startAngle = Angle(degrees: 210)
        let endAngle = Angle(degrees: 180)
        
        // Draw the curved line
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )
        
        // Add arrowhead at the end (180° position)
        let endRadians = CGFloat(endAngle.radians)
        let arrowEndPoint = CGPoint(
            x: center.x + radius * CoreGraphics.cos(endRadians),
            y: center.y + radius * CoreGraphics.sin(endRadians)
        )
        
        // Arrowhead size
        let arrowLength: CGFloat = 15
        
        // Calculate arrowhead points (pointing clockwise along the curve)
        let arrowAngle1 = endRadians - CGFloat.pi / 6
        let arrowAngle2 = endRadians + CGFloat.pi / 6
        
        let arrowPoint1 = CGPoint(
            x: arrowEndPoint.x + arrowLength * CoreGraphics.cos(arrowAngle1),
            y: arrowEndPoint.y + arrowLength * CoreGraphics.sin(arrowAngle1)
        )
        
        let arrowPoint2 = CGPoint(
            x: arrowEndPoint.x + arrowLength * CoreGraphics.cos(arrowAngle2),
            y: arrowEndPoint.y + arrowLength * CoreGraphics.sin(arrowAngle2)
        )
        
        // Draw arrowhead
        path.move(to: arrowPoint1)
        path.addLine(to: arrowEndPoint)
        path.addLine(to: arrowPoint2)
        
        return path
    }
}

#Preview {
    @Previewable @State var show = true
    @Previewable @State var selected: Int? = 30
    
    RadialTimePicker(
        theme: .daylight,
        show: $show,
        selected: $selected,
        onConfirm: { time in
            print("Selected: \(time)")
        }
    )
}
