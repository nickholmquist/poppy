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
    
    let themes: [Theme] = [.daylight, .breeze, .meadow, .citrus, .sherbet, .beachglass, .ember]
    let names: [String] = ["Daylight", "Breeze", "Meadow", "Citrus", "Sherbet", "Beachglass", "Ember"]

    func select(_ theme: Theme) {
        previous = current
        current = theme
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func cycleNext() {
        guard let currentIndex = themes.firstIndex(where: {
            $0.accent == current.accent
        }) else { return }
        
        let nextIndex = (currentIndex + 1) % themes.count
        select(themes[nextIndex])
    }
}
