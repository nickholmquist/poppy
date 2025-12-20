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
    @Binding var showThemeDrawer: Bool
    @EnvironmentObject var themeStore: ThemeStore
    @EnvironmentObject var store: StoreManager
    @EnvironmentObject var highs: HighscoreStore

    // Settings states
    @State private var dragOffset: CGFloat = 0
    @State private var showingCredits = false
    @State private var showingResetConfirmation = false
    @State private var isClosing = false  // NEW: tracks closing animation
    @State private var versionTapCount = 0
    @State private var showingSecretPrompt = false
    @State private var secretCode = ""
    
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
                        // Top bar with drag handle and X button
                        ZStack {
                            // Drag handle (centered)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(theme.textDark.opacity(0.3))
                                .frame(width: 40, height: 5)
                            
                            // X button (top-right)
                            HStack {
                                Spacer()
                                Button(action: {
                                    closeDrawer()
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(theme.textDark.opacity(0.6))
                                        .frame(width: 32, height: 32)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.trailing, 16)
                        }
                        .frame(height: 32)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        
                        ScrollView {
                            VStack(spacing: 22) {
                                // MARK: Settings Section
                                MenuSection(title: "Settings", theme: theme) {
                                    // Theme selector
                                    ThemePreviewButton(
                                        theme: theme,
                                        currentTheme: themeStore.current,
                                        currentThemeName: themeStore.name(at: themeStore.currentIndex ?? 0)
                                    ) {
                                        closeDrawer()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                                            showThemeDrawer = true
                                        }
                                    }

                                    // Sound & Haptics combined row
                                    DualToggleRow(
                                        theme: theme,
                                        leftIcon: "speaker.wave.2.fill",
                                        leftTitle: "Sound",
                                        leftIsOn: Binding(
                                            get: { SoundManager.shared.soundEnabled },
                                            set: { newValue in
                                                SoundManager.shared.soundEnabled = newValue
                                                AnalyticsManager.shared.trackSettingToggled(
                                                    setting: "sound",
                                                    enabled: newValue
                                                )
                                            }
                                        ),
                                        rightIcon: "hand.tap.fill",
                                        rightTitle: "Haptics",
                                        rightIsOn: Binding(
                                            get: { HapticsManager.shared.hapticsEnabled },
                                            set: { newValue in
                                                HapticsManager.shared.hapticsEnabled = newValue
                                                AnalyticsManager.shared.trackSettingToggled(
                                                    setting: "haptics",
                                                    enabled: newValue
                                                )
                                            }
                                        )
                                    )

                                    DailyReminderRow(theme: theme)
                                }

                                // MARK: Store Section (Unlock + Support combined)
                                StoreSection(theme: theme, store: store)

                                // MARK: About Section
                                MenuSection(title: "About", theme: theme) {
                                    InfoButton(
                                        icon: "gamecontroller.fill",
                                        title: "Game Center",
                                        theme: theme
                                    ) {
                                        GameCenterManager.shared.showLeaderboards()
                                    }

                                    InfoButton(
                                        icon: "info.circle.fill",
                                        title: "Privacy Policy",
                                        theme: theme
                                    ) {
                                        if let url = URL(string: "https://islandtwigstudios.com/#policies") {
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

                                    InfoButton(
                                        icon: "arrow.triangle.2.circlepath",
                                        title: "Reset High Scores",
                                        theme: theme
                                    ) {
                                        showingResetConfirmation = true
                                    }

                                    // Version (secret unlock trigger)
                                    HStack {
                                        Text("Version")
                                            .font(.system(size: 15, design: .rounded))
                                            .foregroundStyle(theme.textDark.opacity(0.6))
                                        Spacer()
                                        Text("1.2.0")
                                            .font(.system(size: 15, weight: .medium, design: .rounded))
                                            .foregroundStyle(theme.textDark.opacity(0.6))
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        versionTapCount += 1
                                        if versionTapCount >= 3 {
                                            versionTapCount = 0
                                            showingSecretPrompt = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            if versionTapCount > 0 && versionTapCount < 3 {
                                                versionTapCount = 0
                                            }
                                        }
                                    }
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
                    .offset(y: isClosing ? 1000 : max(0, dragOffset))  // Slide way down when closing
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

                // Purchase success overlay - CENTERED
                if store.showPurchaseSuccess {
                    PurchaseSuccessOverlay(theme: theme, message: store.purchaseSuccessMessage)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(999)
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isOpen)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: store.showTipSuccess)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: store.showPurchaseSuccess)
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
        .alert("Enter Code", isPresented: $showingSecretPrompt) {
            TextField("", text: $secretCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) {
                secretCode = ""
            }
            Button("OK") {
                if secretCode == "6524" {
                    // Unlock everything
                    UnlockManager.shared.unlockEverything()
                    HapticsManager.shared.heavy()
                }
                secretCode = ""
            }
        }
    }
    
    private func closeDrawer() {
        HapticsManager.shared.light()
        
        // First animate drawer down off screen
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isClosing = true
        }
        
        // Then remove it from view hierarchy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isOpen = false
            isClosing = false
            dragOffset = 0
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

// MARK: - Purchase Success Overlay

struct PurchaseSuccessOverlay: View {
    let theme: Theme
    let message: String

    @State private var scale: CGFloat = 0.8

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(theme.accent)

            Text(message)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textDark)
                .multilineTextAlignment(.center)

            Text("Thank you for your support!")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(theme.textDark.opacity(0.6))
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
                        
                        Text("Version 1.2.0")
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
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(theme.textDark.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Dual Toggle Row

struct DualToggleRow: View {
    let theme: Theme
    let leftIcon: String
    let leftTitle: String
    @Binding var leftIsOn: Bool
    let rightIcon: String
    let rightTitle: String
    @Binding var rightIsOn: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Left toggle
            HStack(spacing: 8) {
                Image(systemName: leftIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(theme.accent)
                    .frame(width: 22)

                Text(leftTitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark)

                Spacer()

                Toggle("", isOn: $leftIsOn)
                    .labelsHidden()
                    .tint(theme.accent)
                    .scaleEffect(0.9)
            }
            .frame(maxWidth: .infinity)

            // Divider
            Rectangle()
                .fill(theme.textDark.opacity(0.1))
                .frame(width: 1, height: 28)
                .padding(.horizontal, 8)

            // Right toggle
            HStack(spacing: 8) {
                Image(systemName: rightIcon)
                    .font(.system(size: 16))
                    .foregroundStyle(theme.accent)
                    .frame(width: 22)

                Text(rightTitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark)

                Spacer()

                Toggle("", isOn: $rightIsOn)
                    .labelsHidden()
                    .tint(theme.accent)
                    .scaleEffect(0.9)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.bgBottom.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(theme.textDark.opacity(0.1), lineWidth: 1)
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
                
                Text("Support the dev! 💙")
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
                    .stroke(theme.accent.opacity(0.3), lineWidth: 2)
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
                                    .stroke(Color.white, lineWidth: 2)
                                Circle()
                                    .stroke(drawerTheme.textDark.opacity(0.4), lineWidth: 2)
                            } else {
                                Circle()
                                    .stroke(drawerTheme.textDark.opacity(0.2), lineWidth: 2)
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

// MARK: - Theme Preview Button

struct ThemePreviewButton: View {
    let theme: Theme
    let currentTheme: Theme
    let currentThemeName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Theme preview dot
                Circle()
                    .fill(currentTheme.accent)
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle()
                            .stroke(theme.textDark.opacity(0.2), lineWidth: 2)
                    )

                Text(currentThemeName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textDark.opacity(0.3))
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.bgBottom.opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(theme.textDark.opacity(0.1), lineWidth: 1)
            )
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
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(theme.textDark.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Daily Reminder Row

struct DailyReminderRow: View {
    let theme: Theme
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingTimePicker = false
    @State private var showingPermissionAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Main toggle row
            HStack(spacing: 12) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(theme.accent)
                    .frame(width: 26)

                Text("Daily Reminder")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark)

                Spacer()

                Toggle("", isOn: Binding(
                    get: { notificationManager.dailyReminderEnabled },
                    set: { newValue in
                        if newValue {
                            // Request permission first
                            notificationManager.requestPermission { granted in
                                if granted {
                                    notificationManager.dailyReminderEnabled = true
                                    AnalyticsManager.shared.trackSettingToggled(
                                        setting: "dailyReminder",
                                        enabled: true
                                    )
                                } else {
                                    showingPermissionAlert = true
                                }
                            }
                        } else {
                            notificationManager.dailyReminderEnabled = false
                            AnalyticsManager.shared.trackSettingToggled(
                                setting: "dailyReminder",
                                enabled: false
                            )
                        }
                    }
                ))
                .labelsHidden()
                .tint(theme.accent)
            }
            .padding(.horizontal, 14)
            .frame(height: 48)

            // Time picker button (only show when enabled)
            if notificationManager.dailyReminderEnabled {
                Divider()
                    .padding(.horizontal, 14)

                Button(action: { showingTimePicker = true }) {
                    HStack {
                        Text("Reminder Time")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(theme.textDark.opacity(0.7))

                        Spacer()

                        Text(notificationManager.formattedReminderTime)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(theme.accent)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(theme.textDark.opacity(0.3))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.bgBottom.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(theme.textDark.opacity(0.1), lineWidth: 1)
        )
        .sheet(isPresented: $showingTimePicker) {
            ReminderTimePickerSheet(notificationManager: notificationManager)
        }
        .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive daily reminders.")
        }
    }
}

// MARK: - Reminder Time Picker Sheet

struct ReminderTimePickerSheet: View {
    @ObservedObject var notificationManager: NotificationManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedTime: Date

    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager

        // Initialize with current reminder time
        var components = DateComponents()
        components.hour = notificationManager.reminderHour
        components.minute = notificationManager.reminderMinute
        _selectedTime = State(initialValue: Calendar.current.date(from: components) ?? Date())
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("When would you like to be reminded?")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 24)

                DatePicker(
                    "Reminder Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let components = Calendar.current.dateComponents([.hour, .minute], from: selectedTime)
                        notificationManager.reminderHour = components.hour ?? 9
                        notificationManager.reminderMinute = components.minute ?? 0
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Store Section

struct StoreSection: View {
    let theme: Theme
    @ObservedObject var store: StoreManager

    var body: some View {
        MenuSection(title: "Store", theme: theme) {
            VStack(spacing: 10) {
                // Top row: 3 compact cards (Remove Ads, Themes, Modes)
                HStack(spacing: 8) {
                    if let removeAds = store.product(for: StoreManager.ProductID.removeAds) {
                        UnlockCard(
                            icon: "nosign",
                            title: "No Ads",
                            price: removeAds.displayPrice,
                            isPurchased: store.hasAdsRemoved,
                            theme: theme
                        ) {
                            purchaseProduct(removeAds)
                        }
                    }

                    if let themes = store.product(for: StoreManager.ProductID.themesBundle) {
                        UnlockCard(
                            icon: "paintpalette.fill",
                            title: "Themes",
                            price: themes.displayPrice,
                            isPurchased: store.hasThemesUnlocked,
                            theme: theme
                        ) {
                            purchaseProduct(themes)
                        }
                    }

                    if let modes = store.product(for: StoreManager.ProductID.modesBundle) {
                        UnlockCard(
                            icon: "gamecontroller.fill",
                            title: "Modes",
                            price: modes.displayPrice,
                            isPurchased: store.hasModesUnlocked,
                            theme: theme
                        ) {
                            purchaseProduct(modes)
                        }
                    }
                }

                // Bottom: Wide Poppy Plus button
                if !store.hasPoppyPlus {
                    if let poppyPlus = store.product(for: StoreManager.ProductID.poppyPlus) {
                        PoppyPlusButton(
                            price: poppyPlus.displayPrice,
                            theme: theme
                        ) {
                            purchaseProduct(poppyPlus)
                        }
                    }
                }

                // Restore Purchases
                InfoButton(
                    icon: "arrow.clockwise",
                    title: "Restore Purchases",
                    theme: theme
                ) {
                    Task {
                        await store.restorePurchases()
                    }
                }

                // Tip Jar
                TipJarCompact(theme: theme, store: store)

                if store.isPurchasing {
                    HStack {
                        Spacer()
                        ProgressView()
                            .tint(theme.accent)
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func purchaseProduct(_ product: Product) {
        Task {
            do {
                try await store.purchase(product)
            } catch {
                print("Purchase failed: \(error)")
            }
        }
    }
}

// MARK: - Unlock Card (Compact)

struct UnlockCard: View {
    let icon: String
    let title: String
    let price: String
    let isPurchased: Bool
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard !isPurchased else { return }
            SoundManager.shared.play(.pop)
            HapticsManager.shared.medium()
            action()
        }) {
            VStack(spacing: 6) {
                // Icon or checkmark
                ZStack {
                    if isPurchased {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Color.green.opacity(0.8))
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(theme.accent)
                    }
                }
                .frame(height: 22)

                // Title
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(isPurchased ? theme.textDark.opacity(0.5) : theme.textDark)

                // Price or Owned
                Text(isPurchased ? "Owned" : price)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isPurchased ? theme.textDark.opacity(0.4) : theme.accent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isPurchased ? theme.bgBottom.opacity(0.3) : theme.accent.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(theme.textDark.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchased)
    }
}

// MARK: - Poppy Plus Button (Wide)

struct PoppyPlusButton: View {
    let price: String
    let theme: Theme
    let action: () -> Void

    var body: some View {
        Button(action: {
            SoundManager.shared.play(.pop)
            HapticsManager.shared.medium()
            action()
        }) {
            HStack(spacing: 10) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.textOnAccent)

                Text("Poppy Plus")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textOnAccent)

                Text("•")
                    .foregroundStyle(theme.textOnAccent.opacity(0.6))

                Text("Unlock Everything")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textOnAccent.opacity(0.9))

                Spacer()

                Text(price)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(theme.textOnAccent)
                    )
            }
            .padding(.horizontal, 16)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.accent)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(theme.textDark.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tip Jar Compact

struct TipJarCompact: View {
    let theme: Theme
    @ObservedObject var store: StoreManager

    private var tipProducts: [Product] {
        store.tipProducts
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.accent)

                Text("Love Poppy? Leave a tip!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(theme.textDark)

                Spacer()
            }

            if tipProducts.isEmpty {
                Text("Loading...")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(theme.textDark.opacity(0.5))
            } else {
                HStack(spacing: 8) {
                    ForEach(tipProducts, id: \.id) { product in
                        TipButtonCompact(product: product, theme: theme, store: store)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.bgBottom.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(theme.textDark.opacity(0.1), lineWidth: 1)
        )
    }
}

struct TipButtonCompact: View {
    let product: Product
    let theme: Theme
    @ObservedObject var store: StoreManager

    var body: some View {
        Button(action: {
            Task {
                do {
                    try await store.purchase(product)
                } catch {}
            }
        }) {
            VStack(spacing: 2) {
                Text(tipEmoji)
                    .font(.system(size: 18))
                Text(product.displayPrice)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(theme.textDark)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(theme.accent.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(theme.accent.opacity(0.2), lineWidth: 1.5)
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

#Preview {
    @Previewable @State var isOpen = true
    @Previewable @State var showThemeDrawer = false

    ZStack {
        Color(hex: "#F9F6EC")
            .ignoresSafeArea()

        MenuDrawer(
            theme: .daylight,
            isOpen: $isOpen,
            showThemeDrawer: $showThemeDrawer
        )
        .environmentObject(ThemeStore())
        .environmentObject(StoreManager.preview)
        .environmentObject(HighscoreStore())
    }
}
