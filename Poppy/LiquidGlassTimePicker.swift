//
//  LiquidGlassTimePicker.swift
//  Poppy
//
//  Liquid glass magnifying time selector with drag handle
//

import SwiftUI

struct LiquidGlassTimePicker: View {
    let theme: Theme
    @Binding var show: Bool
    @Binding var selected: Int?
    let onConfirm: (Int) -> Void
    
    let times = [10, 20, 30, 40, 50, 60]
    @State private var selectedIndex: Int = 2 // Start at 30s
    @State private var startX: CGFloat = 0
    @State private var isDragging = false
    @State private var previousIndex: Int = 2
    @State private var isAppearing = false // Track sheet animation
    @State private var exitOffset: CGFloat = 0 // Track pop-up on exit
    @State private var dragOffset: CGFloat = 0
    
    private let dismissThreshold: CGFloat = 150
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissSheet()
                }
            
            // Card slides up from bottom like iOS sheet
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    // Drag handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.textDark.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    
                    // Buttons at top - in corners
                    HStack {
                        Button(action: { dismissSheet() }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.textDark)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(theme.bgTop.opacity(0.3))
                                )
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            selected = times[selectedIndex]
                            onConfirm(times[selectedIndex])
                            dismissSheet()
                        }) {
                            Text("Confirm")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(theme.textDark)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(theme.bgTop.opacity(0.6))
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    
                    // Magnifying glass and arc area
                    ZStack {
                        // Arc of times - curves UP like a rainbow
                        GeometryReader { geo in
                            let width = geo.size.width
                            let centerX = width / 2
                            
                            ForEach(times.indices, id: \.self) { i in
                                let offset = i - selectedIndex
                                let normalizedPosition = CGFloat(offset) / 2.0
                                
                                // Position in arc - WIDER SPREAD
                                let xOffset = normalizedPosition * (width * 0.65) // Increased from 0.5
                                let yOffset = pow(normalizedPosition, 2) * 80.0 - 20.0
                                let x = centerX + xOffset
                                let y = geo.size.height * 0.5 + yOffset
                                
                                // Rotation
                                let rotationAngle = normalizedPosition * 0.4
                                
                                // Distance effects
                                let distance = abs(CGFloat(offset))
                                let isSelected = offset == 0
                                
                                // Scale: selected is MUCH larger
                                let scale: CGFloat = isSelected ? 3.5 : max(0.7, 1.0 - distance * 0.15)
                                
                                // Opacity: all visible, selected is prominent
                                let alpha = isSelected ? 1.0 : max(0.4, 1.0 - distance * 0.2)
                                let visible = abs(offset) <= 2
                                
                                Text("\(times[i])s")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(isSelected ? theme.bgTop : theme.textDark.opacity(0.6))
                                    .scaleEffect(scale)
                                    .opacity(visible ? alpha : 0)
                                    .rotationEffect(.radians(isSelected ? 0 : rotationAngle))
                                    .position(x: x, y: y)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: selectedIndex)
                            }
                        }
                        .frame(height: 200)
                    }
                    .frame(height: 240)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                if !isDragging {
                                    isDragging = true
                                    startX = value.location.x
                                }
                                
                                let delta = value.location.x - startX
                                
                                if abs(delta) > 40 {
                                    if delta > 0 && selectedIndex > 0 {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedIndex -= 1
                                        startX = value.location.x
                                    } else if delta < 0 && selectedIndex < times.count - 1 {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        selectedIndex += 1
                                        startX = value.location.x
                                    }
                                }
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                    .padding(.top, 20)
                    .padding(.bottom, 80) // More height at bottom
                }
                .background(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(theme.accent) // Solid accent pink!
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(theme.textDark.opacity(0.6), lineWidth: 3)
                )
                .shadow(color: theme.shadow.opacity(0.3), radius: 15, y: -3)
                .offset(y: max(0, dragOffset))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > dismissThreshold {
                                dismissSheet()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
            .ignoresSafeArea(edges: .bottom)
            .offset(y: isAppearing ? exitOffset : 800)
            .scaleEffect(isAppearing ? 1.0 : 0.95)
            .padding(.bottom, -80) // Extend bottom offscreen so it doesn't show during bounce
        }
        .onAppear {
            // Set initial selected index based on current selection
            if let currentTime = selected,
               let index = times.firstIndex(of: currentTime) {
                selectedIndex = index
                previousIndex = index
            }
            
            // Bouncy entrance animation
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isAppearing = true
            }
        }
    }
    
    // Helper function for dismissal with animation
    private func dismissSheet() {
        // First: Pop up slightly
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            exitOffset = -30 // Move up 30 points
        }
        
        // Then: Slide down
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isAppearing = false
            }
        }
        
        // Dismiss after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            show = false
        }
    }
}

#Preview {
    @Previewable @State var show = true
    @Previewable @State var selected: Int? = 30
    
    return LiquidGlassTimePicker(
        theme: .daylight,
        show: $show,
        selected: $selected,
        onConfirm: { time in
            print("Selected: \(time)")
        }
    )
}
