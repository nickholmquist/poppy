//
//  MenuDrawer.swift
//  Poppy
//
//  Slide-out menu from right edge
//

import SwiftUI

struct MenuDrawer: View {
    let theme: Theme
    @Binding var isOpen: Bool
    @EnvironmentObject var themeStore: ThemeStore
    
    // Settings states (these will be wired up to UserDefaults later)
    @State private var hapticsEnabled: Bool = true
    @State private var soundEnabled: Bool = false
    
    private let drawerWidth: CGFloat = UIScreen.main.bounds.width * 0.65
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Dimmed background
            if isOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeDrawer()
                    }
                    .transition(.opacity)
            }
            
            // Drawer panel
            if isOpen {
                VStack(spacing: 0) {
                    // Header with close button
                    HStack {
                        Text("Menu")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(theme.textDark)
                        
                        Spacer()
                        
                        Button(action: { closeDrawer() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(theme.textDark.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    
                    ScrollView {
                        VStack(spacing: 28) {
                            // Settings Section
                            MenuSection(title: "Settings", theme: theme) {
                                ToggleRow(
                                    icon: "hand.tap.fill",
                                    title: "Haptics",
                                    isOn: $hapticsEnabled,
                                    theme: theme
                                )
                                
                                ToggleRow(
                                    icon: "speaker.wave.2.fill",
                                    title: "Sound",
                                    isOn: $soundEnabled,
                                    theme: theme
                                )
                            }
                            
                            // Themes Section
                            MenuSection(title: "Themes", theme: theme) {
                                ThemeGrid(theme: theme, themeStore: themeStore)
                            }
                            
                            // Info Section
                            MenuSection(title: "Info", theme: theme) {
                                InfoButton(
                                    icon: "info.circle.fill",
                                    title: "Privacy Policy",
                                    theme: theme
                                ) {
                                    // Open privacy policy URL
                                    print("Privacy policy tapped")
                                }
                                
                                InfoButton(
                                    icon: "heart.fill",
                                    title: "Credits",
                                    theme: theme
                                ) {
                                    // Show credits
                                    print("Credits tapped")
                                }
                                
                                // Version
                                HStack {
                                    Text("Version")
                                        .font(.system(size: 16, design: .rounded))
                                        .foregroundStyle(theme.textDark.opacity(0.6))
                                    Spacer()
                                    Text("1.0.0")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(theme.textDark.opacity(0.6))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                    }
                }
                .frame(width: drawerWidth)
                .background(theme.bgTop)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isOpen)
    }
    
    private func closeDrawer() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        isOpen = false
    }
}

// MARK: - Menu Section

struct MenuSection<Content: View>: View {
    let title: String
    let theme: Theme
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textDark.opacity(0.7))
                .padding(.horizontal, 4)
            
            VStack(spacing: 8) {
                content
            }
        }
    }
}

// MARK: - Toggle Row

struct ToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(theme.accent)
                .frame(width: 28)
            
            Text(title)
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textDark)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.bgBottom.opacity(0.5))
        )
    }
}

// MARK: - Theme Grid

struct ThemeGrid: View {
    let theme: Theme
    @ObservedObject var themeStore: ThemeStore
    
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(themeStore.themes.indices, id: \.self) { index in
                ThemeDot(
                    theme: themeStore.themes[index],
                    isSelected: themeStore.themes[index].accent == themeStore.current.accent,
                    themeName: themeStore.names[index]
                ) {
                    themeStore.select(themeStore.themes[index])
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.bgBottom.opacity(0.5))
        )
    }
}

// MARK: - Theme Dot

struct ThemeDot: View {
    let theme: Theme
    let isSelected: Bool
    let themeName: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Circle()
                    .fill(theme.accent)
                    .frame(width: 44, height: 44)
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                            Circle()
                                .stroke(theme.textDark.opacity(0.4), lineWidth: 4)
                        } else {
                            Circle()
                                .stroke(theme.textDark.opacity(0.2), lineWidth: 2)
                        }
                    }
                
                Text(themeName)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Info Button

struct InfoButton: View {
    let icon: String
    let title: String
    let theme: Theme
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(theme.accent)
                    .frame(width: 28)
                
                Text(title)
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.textDark.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.bgBottom.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var isOpen = true
    
    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()
        
        MenuDrawer(theme: .daylight, isOpen: $isOpen)
            .environmentObject(ThemeStore())
    }
}