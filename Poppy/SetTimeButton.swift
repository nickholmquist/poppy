//
//  SetTimeButton.swift
//  Poppy
//
//  Pill-shaped button for time selection display
//

import SwiftUI

struct SetTimeButton: View {
    let theme: Theme
    let currentTime: Int?   // nil = show "Set Time", value = show "Set Time: 30s"
    let isEnabled: Bool     // false = grayed out (during gameplay)
    let onTap: () -> Void   // Callback when tapped
    
    var body: some View {
        Button(action: {
            if isEnabled {
                HapticsManager.shared.light()
                onTap()
            }
        }) {
            HStack(spacing: 4) {
                Text("Set Time")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                
                if let time = currentTime {
                    Text(":")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .opacity(isEnabled ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.2), value: isEnabled)
                    
                    Text("\(time)s")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .opacity(isEnabled ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.2), value: isEnabled)
                }
            }
            .foregroundStyle(theme.textDark)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .strokeBorder(theme.textDark.opacity(0.3), lineWidth: 2)
            )
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.3), value: isEnabled)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

// MARK: - Previews

#Preview("Button - Idle State") {
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()
        
        VStack(spacing: 30) {
            Text("Idle State (Enabled)")
                .font(.caption)
            
            SetTimeButton(
                theme: .daylight,
                currentTime: 30,
                isEnabled: true,
                onTap: { print("Tapped") }
            )
        }
    }
}

#Preview("Button - Playing State") {
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()
        
        VStack(spacing: 30) {
            Text("Playing State (Disabled)")
                .font(.caption)
            
            SetTimeButton(
                theme: .daylight,
                currentTime: 30,
                isEnabled: false,
                onTap: { }
            )
        }
    }
}

#Preview("Button - Different Times") {
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            SetTimeButton(
                theme: .daylight,
                currentTime: 10,
                isEnabled: true,
                onTap: { }
            )
            
            SetTimeButton(
                theme: .daylight,
                currentTime: 30,
                isEnabled: true,
                onTap: { }
            )
            
            SetTimeButton(
                theme: .daylight,
                currentTime: 60,
                isEnabled: true,
                onTap: { }
            )
        }
    }
}

#Preview("Button - Multiple Themes") {
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            SetTimeButton(
                theme: .daylight,
                currentTime: 30,
                isEnabled: true,
                onTap: { }
            )
            
            SetTimeButton(
                theme: .breeze,
                currentTime: 30,
                isEnabled: true,
                onTap: { }
            )
            
            SetTimeButton(
                theme: .meadow,
                currentTime: 30,
                isEnabled: true,
                onTap: { }
            )
        }
    }
}

#Preview("Button - Animation Test") {
    struct AnimationTest: View {
        @State private var isPlaying = false
        
        var body: some View {
            ZStack {
                Color(hex: "#F9F6EC")
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    SetTimeButton(
                        theme: .daylight,
                        currentTime: 30,
                        isEnabled: !isPlaying,
                        onTap: { }
                    )
                    
                    Button("Toggle Playing") {
                        withAnimation {
                            isPlaying.toggle()
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    return AnimationTest()
}