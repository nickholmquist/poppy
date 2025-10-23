//
//  ThemeStore.swift
//  Poppy
//

import SwiftUI
import Combine

@MainActor
final class ThemeStore: ObservableObject {
    @Published var current: Theme = .daylight
    @Published var previous: Theme? = nil
    
    let themes: [Theme] = [.daylight, .breeze, .meadow, .citrus, .sherbet, .beachglass, .twilight, .memphis, .minimalLight, .minimalDark]
    let names: [String] = ["Daylight", "Breeze", "Meadow", "Citrus", "Sherbet", "Beachglass", "Twilight", "Memphis", "Minimal Light", "Minimal Dark"]
    
    // Reference to StoreManager for checking locks
    private var storeManager: StoreManager?
    
    func setStoreManager(_ manager: StoreManager) {
        self.storeManager = manager
    }

    func select(_ theme: Theme) {
        previous = current
        current = theme
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func cycleNext() {
        guard let currentIndex = themes.firstIndex(where: {
            $0.accent == current.accent
        }) else { return }
        
        // Find next unlocked theme
        var nextIndex = (currentIndex + 1) % themes.count
        var attempts = 0
        let maxAttempts = themes.count
        
        while attempts < maxAttempts {
            let themeName = names[nextIndex]
            
            // Check if theme is unlocked
            if let manager = storeManager, !manager.isThemeUnlocked(themeName) {
                // Skip locked theme, try next
                nextIndex = (nextIndex + 1) % themes.count
                attempts += 1
            } else {
                // Found unlocked theme
                select(themes[nextIndex])
                return
            }
        }
        
        // Fallback - if all themes locked somehow, stay on current
    }
}
