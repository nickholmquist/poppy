//
//  VerticalTimePicker.swift
//  Poppy v1.1
//
//  Origami-style vertical time picker that unfolds on top of time display
//

import SwiftUI

struct VerticalTimePicker: View {
    let theme: Theme
    @Binding var show: Bool
    @Binding var selected: Int?
    let onConfirm: (Int) -> Void
    
    let times = [10, 20, 30, 40, 50, 60]
    @State private var selectedTime: Int = 30
    @State private var isUnfolding = false
    @Namespace private var scrollNamespace
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Dimmed background
                Color.black
                    .opacity(isUnfolding ? 0.5 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissPicker()
                    }
                    .animation(.easeOut(duration: 0.4), value: isUnfolding)
                
                // Origami strip - positioned where time display is
                VStack(spacing: 0) {
                    // Scrollable time sections
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 8) {
                                ForEach(Array(times.enumerated()), id: \.offset) { index, time in
                                    TimeSection(
                                        time: time,
                                        isSelected: time == selectedTime,
                                        isUnfolding: isUnfolding,
                                        unfoldDelay: Double(index) * 0.05,
                                        theme: theme
                                    ) {
                                        selectedTime = time
                                        HapticsManager.shared.light()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            proxy.scrollTo(time, anchor: .center)
                                        }
                                    }
                                    .id(time)
                                }
                            }
                            .padding(10)
                        }
                        .frame(maxHeight: 300)
                        .onAppear {
                            // Scroll to selected time after unfold
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                withAnimation {
                                    proxy.scrollTo(selectedTime, anchor: .center)
                                }
                            }
                        }
                    }
                    
                    // Checkmark confirm button
                    Button(action: {
                        selected = selectedTime
                        onConfirm(selectedTime)
                        dismissPicker()
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(theme.accent)
                                    .shadow(color: theme.accent.opacity(0.3), radius: 8, y: 4)
                            )
                    }
                    .padding(10)
                    .opacity(isUnfolding ? 1 : 0)
                    .offset(y: isUnfolding ? 0 : 10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7).delay(0.35), value: isUnfolding)
                }
                .frame(width: 140)
                .background(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(theme.bgTop)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(theme.textDark, lineWidth: 3)
                        )
                        .shadow(color: theme.shadow.opacity(0.4), radius: 20, y: 10)
                )
                .position(
                    x: geo.size.width * 0.704,  // Time display X position
                    y: geo.size.height * 0.46   // Time display Y position
                )
            }
        }
        .onAppear {
            // Set initial selected time
            if let currentTime = selected {
                selectedTime = currentTime
            }
            
            // Trigger unfold animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation {
                    isUnfolding = true
                }
            }
        }
    }
    
    private func dismissPicker() {
        HapticsManager.shared.light()
        
        withAnimation(.easeOut(duration: 0.3)) {
            isUnfolding = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            show = false
        }
    }
}

// MARK: - Time Section

struct TimeSection: View {
    let time: Int
    let isSelected: Bool
    let isUnfolding: Bool
    let unfoldDelay: Double
    let theme: Theme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Paper crease line at top
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                theme.textDark.opacity(0.15),
                                theme.textDark.opacity(0.15),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .offset(y: -22)
                
                // Time number
                Text("\(time)s")
                    .font(.system(size: isSelected ? 32 : 28, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? .white : theme.textDark.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isSelected ? theme.accent : theme.bgBottom.opacity(0.5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(
                                        isSelected ? theme.textDark : Color.clear,
                                        lineWidth: isSelected ? 2 : 0
                                    )
                            )
                            .shadow(
                                color: isSelected ? theme.accent.opacity(0.5) : .clear,
                                radius: 8,
                                y: 4
                            )
                    )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(y: isUnfolding ? 1.0 : 0.0, anchor: .top)
        .opacity(isUnfolding ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.3, dampingFraction: 0.7).delay(unfoldDelay),
            value: isUnfolding
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var show = true
    @Previewable @State var selected: Int? = 30
    
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()
        
        if show {
            VerticalTimePicker(
                theme: .daylight,
                show: $show,
                selected: $selected,
                onConfirm: { time in
                    print("Selected: \(time)")
                }
            )
        }
    }
}