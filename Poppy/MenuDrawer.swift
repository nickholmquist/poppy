//
//  MenuDrawer.swift
//  Poppy
//
//  Bottom sheet menu with drag handle
//

import SwiftUI
import StoreKit

struct MenuDrawer: View {
    let theme: Theme
    @Binding var isOpen: Bool
    @EnvironmentObject var themeStore: ThemeStore
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var highs: HighscoreStore
    
    // Settings states
    @State private var dragOffset: CGFloat = 0
    @State private var showingCredits = false
    @State private var showingResetConfirmation = false
    
    private let dismissThreshold: CGFloat = 200
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Dimmed background
                if isOpen {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closeDrawer()
                        }
                        .transition(.opacity)
                }
                
                // Bottom sheet
                if isOpen {
                    VStack(spacing: 0) {
                        // Drag handle
                        RoundedRectangle(cornerRadius: 3)
                            .fill(theme.textDark.opacity(0.3))
                            .frame(width: 40, height: 5)
                            .padding(.top, 12)
                            .padding(.bottom, 8)
                        
                        ScrollView {
                            VStack(spacing: 22) {
                                // Settings Section
                                MenuSection(title: "Settings", theme: theme) {
                                    ToggleRow(
                                        icon: "hand.tap.fill",
                                        title: "Haptics",
                                        isOn: Binding(
                                            get: { HapticsManager.shared.hapticsEnabled },
                                            set: { HapticsManager.shared.hapticsEnabled = $0 }
                                        ),
                                        theme: theme
                                    )
                                    
                                    ToggleRow(
                                        icon: "speaker.wave.2.fill",
                                        title: "Sound",
                                        isOn: Binding(
                                            get: { SoundManager.shared.soundEnabled },
                                            set: { SoundManager.shared.soundEnabled = $0 }
                                        ),
                                        theme: theme
                                    )
                                }
                                
                                // Tip Jar
                                TipJarView(theme: theme, store: store)
                                
                                // Themes Section
                                MenuSection(title: "Themes", theme: theme) {
                                    ThemeGrid(
                                        theme: theme,
                                        themeStore: themeStore
                                    )
                                }
                                
                                // Info Section
                                MenuSection(title: "Info", theme: theme) {
                                    InfoButton(
                                        icon: "arrow.triangle.2.circlepath",
                                        title: "Reset High Scores",
                                        theme: theme
                                    ) {
                                        showingResetConfirmation = true
                                    }
                                    
                                    InfoButton(
                                        icon: "info.circle.fill",
                                        title: "Privacy Policy",
                                        theme: theme
                                    ) {
                                        if let url = URL(string: "https://poppygame.crd.co/") {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    
                                    InfoButton(
                                        icon: "heart.fill",
                                        title: "Credits",
                                        theme: theme
                                    ) {
                                        showingCredits = true
                                    }
                                    
                                    // Version
                                    HStack {
                                        Text("Version")
                                            .font(.system(size: 15, design: .rounded))
                                            .foregroundStyle(theme.textDark.opacity(0.6))
                                        Spacer()
                                        Text("1.0.0")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(theme.textDark.opacity(0.6))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 6)
                            .padding(.bottom, 40)
                        }
                        .safeAreaInset(edge: .bottom) {
                            Color.clear.frame(height: 0)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.85)
                    .background(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(theme.bgTop)
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .stroke(theme.textDark.opacity(0.2), lineWidth: 2)
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .shadow(color: theme.shadow.opacity(0.3), radius: 15, y: -3)
                    .offset(y: max(0, dragOffset))
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
                
                // Tip success overlay - CENTERED
                if store.showTipSuccess {
                    TipSuccessOverlay(theme: theme, message: store.tipSuccessMessage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(999)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isOpen)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: store.showTipSuccess)
        }
        .sheet(isPresented: $showingCredits) {
            CreditsSheet(theme: theme)
        }
        .alert("Reset High Scores?", isPresented: $showingResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                highs.reset()
                HapticsManager.shared.medium()
            }
        } message: {
            Text("This will permanently erase all your high scores. This action cannot be undone.")
        }
    }
    
    private func closeDrawer() {
        HapticsManager.shared.light()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isOpen = false
        }
    }
}

// MARK: - Tip Success Overlay

struct TipSuccessOverlay: View {
    let theme: Theme
    let message: String
    
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.green)
            
            Text(message)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textDark)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(theme.bgTop)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
    }
}

// MARK: - Credits Sheet

struct CreditsSheet: View {
    let theme: Theme
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Poppy")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textDark)
                        
                        Text("Version 1.0.0")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(theme.textDark.opacity(0.6))
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Created by")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textDark.opacity(0.6))
                        
                        Text("Nick Holmquist")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.textDark)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Special Thanks")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(theme.textDark.opacity(0.6))
                        
                        Text("Thank you for playing Poppy! A special thank you goes out to my wife and my kids. Without you all, I wouldn't have been able to make this possible. Your support means everything.\n\nAnd thank YOU for playing my game. It means the world to me!")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(theme.textDark)
                            .lineSpacing(2)
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .background(theme.bgTop)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(theme.accent)
                }
            }
        }
    }
}

// MARK: - Menu Section

struct MenuSection<Content: View>: View {
    let title: String
    let theme: Theme
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
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
                .font(.system(size: 18))
                .foregroundStyle(theme.accent)
                .frame(width: 26)
            
            Text(title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textDark)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(theme.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.bgBottom.opacity(0.5))
        )
    }
}

// MARK: - Tip Jar View

struct TipJarView: View {
    let theme: Theme
    @ObservedObject var store: StoreManager
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("Love Poppy?")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textDark)
                
                Text("Support the dev! 🎉")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.7))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.top, 8)
            
            if tipProducts.isEmpty {
                Text("Loading tip options...")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.5))
                    .padding(.vertical, 8)
            } else {
                HStack(spacing: 10) {
                    ForEach(tipProducts, id: \.id) { product in
                        TipButton(product: product, theme: theme, store: store)
                    }
                }
                .padding(.horizontal, 14)
            }
            
            if store.isPurchasing {
                ProgressView()
                    .tint(theme.accent)
                    .padding(.top, 8)
            }
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.bgBottom.opacity(0.5))
        )
    }
    
    private var tipProducts: [Product] {
        store.products.filter { $0.id.contains("tip") }
    }
}

struct TipButton: View {
    let product: Product
    let theme: Theme
    @ObservedObject var store: StoreManager
    
    var body: some View {
        Button(action: {
            Task {
                do {
                    try await store.purchase(product)
                } catch {
                }
            }
        }) {
            VStack(spacing: 4) {
                Text(tipEmoji)
                    .font(.system(size: 24))
                
                Text(product.displayPrice)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textDark)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.accent.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(theme.accent.opacity(0.3), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(store.isPurchasing)
    }
    
    private var tipEmoji: String {
        if product.id.contains("small") { return "☕️" }
        if product.id.contains("medium") { return "🍰" }
        return "🎉"
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
                let themeName = themeStore.names[index]
                
                ThemeDot(
                    theme: themeStore.themes[index],
                    isSelected: themeStore.themes[index].accent == themeStore.current.accent,
                    isLocked: false,  // All themes unlocked
                    themeName: themeName,
                    onTap: {
                        themeStore.select(themeStore.themes[index])
                    },
                    drawerTheme: theme
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
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
    let isLocked: Bool
    let themeName: String
    let onTap: () -> Void
    let drawerTheme: Theme
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 40, height: 40)
                        .overlay {
                            if isSelected {
                                Circle()
                                    .stroke(Color.white, lineWidth: 2.5)
                                Circle()
                                    .stroke(drawerTheme.textDark.opacity(0.4), lineWidth: 3.5)
                            } else {
                                Circle()
                                    .stroke(drawerTheme.textDark.opacity(0.2), lineWidth: 1.5)
                            }
                        }
                    
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                }
                
                Text(themeName)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(drawerTheme.textDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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
                    .font(.system(size: 18))
                    .foregroundStyle(theme.accent)
                    .frame(width: 26)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textDark.opacity(0.3))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
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
            .environmentObject(StoreManager.preview)
            .environmentObject(HighscoreStore())
    }
}
