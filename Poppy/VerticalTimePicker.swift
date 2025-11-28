//
//  VerticalTimePicker.swift
//  Poppy v1.1
//
//  Positioned to match Set Time button frame exactly with matching stroke
//

import SwiftUI

struct VerticalTimePicker: View {
    let theme: Theme
    @Binding var show: Bool
    @Binding var selected: Int?
    let buttonFrame: CGRect  // NEW: Frame of the Set Time button
    let onConfirm: (Int) -> Void
    
    let times = [10, 20, 30, 40, 50, 60]
    @State private var selectedTime: Int = 30
    @State private var selectedIndex: Int = 2
    @State private var isExpanded = false
    
    private let itemHeight: CGFloat = 70
    private let buttonHeight: CGFloat = 70
    private let titleHeight: CGFloat = 44
    
    // Match button width exactly
    private var stripWidth: CGFloat {
        buttonFrame.width
    }
    
    private var currentHeight: CGFloat {
        isExpanded ? expandedHeight : titleHeight
    }
    
    private var expandedHeight: CGFloat {
        titleHeight + (CGFloat(times.count) * itemHeight) + buttonHeight
    }
    
    private var highlighterY: CGFloat {
        titleHeight + CGFloat(selectedIndex) * itemHeight
    }
    
    var body: some View {
        ZStack {
            // Dimmed background with drag gesture
            Color.black
                .opacity(isExpanded ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissPicker()
                }
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            guard isExpanded else { return }
                            
                            // Convert global drag position to picker-relative position
                            let globalY = value.location.y
                            let pickerTopY = buttonFrame.minY
                            let dragY = globalY - pickerTopY - titleHeight
                            let index = Int(round(dragY / itemHeight))
                            let clampedIndex = max(0, min(times.count - 1, index))
                            
                            if clampedIndex != selectedIndex {
                                selectedIndex = clampedIndex
                                selectedTime = times[clampedIndex]
                                SoundManager.shared.play(.timeSelect)
                                HapticsManager.shared.light()
                            }
                        }
                )
                .animation(.easeOut(duration: 0.4), value: isExpanded)
            
            // The morphing accordion
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    // Title - ALWAYS VISIBLE, never clipped
                    Text("Set Time")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(theme.textDark)
                        .frame(width: stripWidth, height: titleHeight)
                    
                    // Content area that gets clipped during expansion
                    VStack(spacing: 0) {
                        // Time options
                        ForEach(Array(times.enumerated()), id: \.offset) { index, time in
                            Button(action: {
                                SoundManager.shared.play(.timeSelect)
                                tapTime(index)
                            }) {
                                ZStack {
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    .clear,
                                                    theme.textDark.opacity(0.12),
                                                    theme.textDark.opacity(0.12),
                                                    .clear
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(height: 1)
                                        .offset(y: -35)
                                    
                                    Text("\(time)s")
                                        .font(.system(
                                            size: 36,
                                            weight: selectedTime == time ? .black : .semibold,
                                            design: .rounded
                                        ))
                                        .foregroundStyle(theme.textDark.opacity(selectedTime == time ? 1.0 : 0.5))
                                }
                                .frame(width: stripWidth, height: itemHeight)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Confirm button
                        Button(action: {
                            SoundManager.shared.play(.popUp)
                            selected = selectedTime
                            onConfirm(selectedTime)
                            dismissPicker()
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: stripWidth, height: buttonHeight)
                                .background(
                                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                                        .fill(theme.accent)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .opacity(isExpanded ? 1.0 : 0.0)  // Hide instantly when collapsing
                    .animation(.none, value: isExpanded)  // NO fade animation
                    .frame(height: max(0, currentHeight - titleHeight))
                    .clipped()  // Clip only the content area, not the title
                }
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(theme.bgTop)
                        // Shadow only when expanded
                        .shadow(
                            color: isExpanded ? theme.shadow.opacity(0.3) : .clear,
                            radius: 15,
                            y: 8
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(theme.textDark.opacity(0.3), lineWidth: 2)
                )
                .frame(height: currentHeight)
                
                // Highlighter
                if isExpanded {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(theme.accent.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(theme.accent, lineWidth: 3)
                        )
                        .frame(width: stripWidth - 8, height: itemHeight - 4)
                        .offset(y: highlighterY + 2)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: selectedIndex)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        guard isExpanded else { return }
                        
                        let dragY = value.location.y - titleHeight
                        let index = Int(round(dragY / itemHeight))
                        let clampedIndex = max(0, min(times.count - 1, index))
                        
                        if clampedIndex != selectedIndex {
                            selectedIndex = clampedIndex
                            selectedTime = times[clampedIndex]
                            SoundManager.shared.play(.timeSelect)
                            HapticsManager.shared.light()
                        }
                    }
            )
            .frame(width: stripWidth, height: currentHeight, alignment: .top)
            .position(
                x: buttonFrame.midX,
                y: buttonFrame.midY + (currentHeight - titleHeight) / 2
            )
            .animation(.spring(response: 0.5, dampingFraction: 0.9), value: currentHeight)
        }
        .ignoresSafeArea()  // Match global coordinate space
        .onAppear {
            if let currentTime = selected {
                selectedTime = currentTime
            }
            
            if let index = times.firstIndex(of: selectedTime) {
                selectedIndex = index
            }
            
            startMorphAnimation()
        }
    }
    
    private func startMorphAnimation() {
        // Simpler: just expand immediately with smooth animation
        // No lifting shadow - cleaner and avoids the "shadow appearing on empty pill" issue
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            isExpanded = true
        }
    }
    
    private func tapTime(_ index: Int) {
        guard isExpanded else { return }
        HapticsManager.shared.light()
        selectedIndex = index
        selectedTime = times[index]
    }
    
    private func dismissPicker() {
        HapticsManager.shared.light()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            isExpanded = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            show = false
        }
    }
}

#Preview {
    @Previewable @State var show = true
    @Previewable @State var selected: Int? = 30
    
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()
        
        // Mock button frame for preview
        let buttonFrame = CGRect(x: 150, y: 100, width: 120, height: 44)
        
        if show {
            VerticalTimePicker(
                theme: .daylight,
                show: $show,
                selected: $selected,
                buttonFrame: buttonFrame,
                onConfirm: { time in
                    print("Selected: \(time)")
                }
            )
        }
    }
}
