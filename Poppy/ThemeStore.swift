//
//  ThemeStore.swift
//  Poppy
//
//  v1.2 - Updated with 27 themes and premium unlock logic
//  Supports automatic light/dark mode switching
//

import SwiftUI
import Combine

@MainActor
final class ThemeStore: ObservableObject {
    @Published var current: Theme = .daylight
    @Published var previous: Theme? = nil

    // Separate theme preferences for light/dark mode
    @Published private(set) var lightModeThemeIndex: Int = 0   // Default: Daylight
    @Published private(set) var darkModeThemeIndex: Int = 11   // Default: Slate

    // Track current system color scheme
    private var currentColorScheme: ColorScheme = .light

    private let lightThemeKey = "poppy.theme.lightMode"
    private let darkThemeKey = "poppy.theme.darkMode"
    
    // MARK: - All 27 Themes
    
    let themes: [Theme] = [
        // Original (0-11)
        .daylight,      // 0
        .sherbet,       // 1
        .sunset,        // 2
        .citrus,        // 3
        .ocean,         // 4
        .garden,        // 5
        .forest,        // 6
        .meadow,        // 7
        .twilight,      // 8
        .memphis,       // 9
        .minimalLight,  // 10
        .minimalDark,   // 11
        
        // Free Accessibility (12-15)
        .noir,          // 12
        .newsprint,     // 13
        .highContrast,  // 14
        .colorblindSafe,// 15
        
        // Premium (16-26)
        .tieDye,        // 16
        .terminal,      // 17
        .cottonCandy,   // 18
        .glacier,       // 19
        .stormy,        // 20
        .coralReef,     // 21
        .cosmic,        // 22
        .ember,         // 23
        .dusk,          // 24
        .vapor,         // 25
        .matcha         // 26
    ]
    
    let names: [String] = [
        // Original (0-11)
        "Daylight",
        "Sherbet",
        "Sunset",
        "Citrus",
        "Ocean",
        "Garden",
        "Forest",
        "Meadow",
        "Twilight",
        "Memphis",
        "Paper",
        "Slate",
        
        // Free Accessibility (12-15)
        "Noir",
        "Newsprint",
        "High Contrast",
        "Colorblind Safe",
        
        // Premium (16-26)
        "Tie-Dye",
        "Terminal",
        "Cotton Candy",
        "Glacier",
        "Stormy",
        "Coral Reef",
        "Cosmic",
        "Ember",
        "Dusk",
        "Vapor",
        "Matcha"
    ]
    
    // MARK: - Theme Categories
    
    /// Indices of premium themes (require purchase)
    static let premiumThemeIndices: Set<Int> = Set(16...26)
    
    /// Indices of free themes (always unlocked)
    static let freeThemeIndices: Set<Int> = Set(0...15)
    
    /// Product IDs for individual theme purchases
    static let themeProductIDs: [Int: String] = [
        16: "com.poppy.theme.tiedye",
        17: "com.poppy.theme.terminal",
        18: "com.poppy.theme.cottoncandy",
        19: "com.poppy.theme.glacier",
        20: "com.poppy.theme.stormy",
        21: "com.poppy.theme.coralreef",
        22: "com.poppy.theme.cosmic",
        23: "com.poppy.theme.ember",
        24: "com.poppy.theme.dusk",
        25: "com.poppy.theme.vapor",
        26: "com.poppy.theme.matcha"
    ]
    
    // MARK: - Unlock Status
    
    /// Check if a theme at given index is unlocked
    func isUnlocked(index: Int) -> Bool {
        // Free themes are always unlocked
        if !isPremium(index: index) {
            return true
        }
        // Premium themes require unlock (via Poppy Plus, theme bundle, or individual purchase)
        return UnlockManager.shared.isUnlocked
    }
    
    /// Get all unlocked theme indices
    var unlockedIndices: [Int] {
        themes.indices.filter { isUnlocked(index: $0) }
    }
    
    /// Get current theme index
    var currentIndex: Int? {
        themes.firstIndex(where: { $0.accent == current.accent })
    }
    
    // MARK: - Initialization

    init() {
        // Load saved preferences
        if let savedLight = UserDefaults.standard.object(forKey: lightThemeKey) as? Int {
            lightModeThemeIndex = savedLight
        }
        if let savedDark = UserDefaults.standard.object(forKey: darkThemeKey) as? Int {
            darkModeThemeIndex = savedDark
        }

        // Set initial theme based on current system appearance
        // This will be updated properly when updateColorScheme is called
        current = themes[lightModeThemeIndex]
    }

    // MARK: - Color Scheme Handling

    /// Called when system color scheme changes
    func updateColorScheme(_ colorScheme: ColorScheme) {
        guard colorScheme != currentColorScheme else { return }
        currentColorScheme = colorScheme

        let targetIndex = colorScheme == .dark ? darkModeThemeIndex : lightModeThemeIndex
        if targetIndex >= 0 && targetIndex < themes.count {
            previous = current
            current = themes[targetIndex]
        }
    }

    /// Force apply the correct theme for current color scheme (call on app launch)
    func applyCurrentColorScheme(_ colorScheme: ColorScheme) {
        currentColorScheme = colorScheme
        let targetIndex = colorScheme == .dark ? darkModeThemeIndex : lightModeThemeIndex
        if targetIndex >= 0 && targetIndex < themes.count {
            current = themes[targetIndex]
        }
    }

    // MARK: - Selection

    func select(_ theme: Theme) {
        previous = current
        current = theme
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Save to appropriate mode preference
        if let index = themes.firstIndex(where: { $0.accent == theme.accent }) {
            if currentColorScheme == .dark {
                darkModeThemeIndex = index
                UserDefaults.standard.set(index, forKey: darkThemeKey)
            } else {
                lightModeThemeIndex = index
                UserDefaults.standard.set(index, forKey: lightThemeKey)
            }
        }
    }

    func select(at index: Int) {
        guard index >= 0 && index < themes.count else { return }
        select(themes[index])
    }

    /// Cycle to next UNLOCKED theme (for tap on theme dot)
    func cycleNext() {
        guard let currentIdx = currentIndex else { return }

        // Find next unlocked theme
        let unlocked = unlockedIndices.sorted()

        if let currentPos = unlocked.firstIndex(of: currentIdx) {
            let nextPos = (currentPos + 1) % unlocked.count
            select(at: unlocked[nextPos])
        } else {
            // Current theme somehow not in unlocked list, go to first unlocked
            if let first = unlocked.first {
                select(at: first)
            }
        }
    }
    
    // MARK: - Premium Helpers
    
    /// Check if theme at index is premium
    func isPremium(index: Int) -> Bool {
        Self.premiumThemeIndices.contains(index)
    }
    
    /// Get product ID for a premium theme
    func productID(for index: Int) -> String? {
        Self.themeProductIDs[index]
    }
    
    /// Get theme name at index
    func name(at index: Int) -> String {
        guard index >= 0 && index < names.count else { return "Unknown" }
        return names[index]
    }
}
