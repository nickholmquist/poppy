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

    func select(_ theme: Theme) {
        previous = current
        current = theme
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func cycleNext() {
        guard let currentIndex = themes.firstIndex(where: {
            $0.accent == current.accent
        }) else { return }
        
        // All themes are unlocked - just cycle to next
        let nextIndex = (currentIndex + 1) % themes.count
        select(themes[nextIndex])
    }
}
