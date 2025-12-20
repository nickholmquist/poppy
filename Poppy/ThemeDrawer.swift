//
//  ThemeDrawer.swift
//  Poppy
//
//  v1.2 - Dedicated theme selection drawer
//  Opens via long press on theme dot OR "Themes" button in menu
//

import SwiftUI

struct ThemeDrawer: View {
    let theme: Theme
    @Binding var isOpen: Bool
    var onLockedThemeTap: (() -> Void)?
    @EnvironmentObject var themeStore: ThemeStore

    @State private var dragOffset: CGFloat = 0
    @State private var isClosing = false

    private let dismissThreshold: CGFloat = 150

    // 4 columns for the grid
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Dimmed background
                if isOpen {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closeDrawer()
                        }
                        .transition(.opacity)
                }

                // Bottom sheet
                if isOpen {
                    VStack(spacing: 0) {
                        // Top bar with drag handle and title
                        VStack(spacing: 8) {
                            // Drag handle
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.textDark.opacity(0.3))
                                .frame(width: 40, height: 5)

                            // Title and close button
                            ZStack {
                                Text("Themes")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(theme.textDark)

                                HStack {
                                    Spacer()
                                    Button(action: closeDrawer) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(theme.textDark.opacity(0.6))
                                            .frame(width: 32, height: 32)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                        // Theme grid
                        ScrollView {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(themeStore.themes.indices, id: \.self) { index in
                                    ThemeDrawerItem(
                                        itemTheme: themeStore.themes[index],
                                        name: themeStore.names[index],
                                        isSelected: themeStore.currentIndex == index,
                                        isLocked: !themeStore.isUnlocked(index: index),
                                        isPremium: themeStore.isPremium(index: index),
                                        drawerTheme: theme
                                    ) {
                                        selectTheme(at: index)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 40)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.75)
                    .background(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(theme.bgTop)
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(theme.textDark.opacity(0.15), lineWidth: 2)
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .shadow(color: theme.shadow.opacity(0.35), radius: 20, y: -5)
                    .offset(y: isClosing ? 1000 : max(0, dragOffset))
                    .transition(.move(edge: .bottom))
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.height > 0 {
                                    dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                if value.translation.height > dismissThreshold {
                                    closeDrawer()
                                } else {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isOpen)
        }
    }

    private func selectTheme(at index: Int) {
        guard themeStore.isUnlocked(index: index) else {
            // Show purchase modal for locked themes
            SoundManager.shared.play(.pop)
            HapticsManager.shared.medium()
            closeDrawer()
            // Delay to let drawer close first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                onLockedThemeTap?()
            }
            return
        }

        SoundManager.shared.play(.pop)
        HapticsManager.shared.light()
        themeStore.select(at: index)

        // Close drawer after selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            closeDrawer()
        }
    }

    private func closeDrawer() {
        HapticsManager.shared.light()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isClosing = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isOpen = false
            isClosing = false
            dragOffset = 0
        }
    }
}

// MARK: - Theme Drawer Item

private struct ThemeDrawerItem: View {
    let itemTheme: Theme
    let name: String
    let isSelected: Bool
    let isLocked: Bool
    let isPremium: Bool
    let drawerTheme: Theme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Theme preview dot
                ZStack {
                    // Background gradient preview
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [itemTheme.bgTop, itemTheme.bgBottom],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    // Accent color inner circle
                    Circle()
                        .fill(itemTheme.accent)
                        .frame(width: 32, height: 32)

                    // Selection ring
                    if isSelected {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .frame(width: 52, height: 52)
                        Circle()
                            .stroke(drawerTheme.textDark.opacity(0.3), lineWidth: 2)
                            .frame(width: 56, height: 56)
                    } else {
                        Circle()
                            .stroke(drawerTheme.textDark.opacity(0.15), lineWidth: 2)
                            .frame(width: 52, height: 52)
                    }

                    // Lock icon for locked themes
                    if isLocked {
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .frame(width: 52, height: 52)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                // Theme name
                Text(name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(drawerTheme.textDark.opacity(isLocked ? 0.5 : 0.9))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.7 : 1.0)
    }
}

// MARK: - Preview

#Preview("Theme Drawer") {
    @Previewable @State var isOpen = true

    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()

        ThemeDrawer(
            theme: .daylight,
            isOpen: $isOpen
        )
        .environmentObject(ThemeStore())
    }
}
