//
//  UnlockManager.swift
//  Poppy
//
//  Manages unlock state for premium content (modes, themes, ads)
//  Supports both individual unlocks and full Poppy Plus unlock
//

import Foundation
import Combine

@MainActor
final class UnlockManager: ObservableObject {
    static let shared = UnlockManager()

    // UserDefaults keys
    private let fullUnlockKey = "poppy.unlock.full"
    private let modesUnlockKey = "poppy.unlock.modes"
    private let themesUnlockKey = "poppy.unlock.themes"
    private let adsRemovedKey = "poppy.unlock.ads"

    // Published unlock states
    @Published private(set) var isFullyUnlocked: Bool
    @Published private(set) var areModesUnlocked: Bool
    @Published private(set) var areThemesUnlocked: Bool
    @Published private(set) var areAdsRemoved: Bool

    /// Convenience: true if everything is unlocked (Poppy Plus or all bundles)
    var isUnlocked: Bool {
        isFullyUnlocked || (areModesUnlocked && areThemesUnlocked && areAdsRemoved)
    }

    /// Check if a specific game mode is unlocked
    func isModeUnlocked(_ mode: GameMode) -> Bool {
        // Free modes are always unlocked
        if mode.isFree { return true }
        // Premium modes require modes unlock or full unlock
        return areModesUnlocked || isFullyUnlocked
    }

    /// Check if premium themes are unlocked
    var canAccessPremiumThemes: Bool {
        areThemesUnlocked || isFullyUnlocked
    }

    /// Check if ads should be shown
    var shouldShowAds: Bool {
        !areAdsRemoved && !isFullyUnlocked
    }

    private init() {
        self.isFullyUnlocked = UserDefaults.standard.bool(forKey: fullUnlockKey)
        self.areModesUnlocked = UserDefaults.standard.bool(forKey: modesUnlockKey)
        self.areThemesUnlocked = UserDefaults.standard.bool(forKey: themesUnlockKey)
        self.areAdsRemoved = UserDefaults.standard.bool(forKey: adsRemovedKey)
    }

    // MARK: - Unlock Methods

    /// Unlock everything (Poppy Plus)
    func unlockEverything() {
        isFullyUnlocked = true
        areModesUnlocked = true
        areThemesUnlocked = true
        areAdsRemoved = true

        UserDefaults.standard.set(true, forKey: fullUnlockKey)
        UserDefaults.standard.set(true, forKey: modesUnlockKey)
        UserDefaults.standard.set(true, forKey: themesUnlockKey)
        UserDefaults.standard.set(true, forKey: adsRemovedKey)

        print("Poppy Plus unlocked!")
    }

    /// Set modes unlock state
    func setModesUnlocked(_ unlocked: Bool) {
        areModesUnlocked = unlocked
        UserDefaults.standard.set(unlocked, forKey: modesUnlockKey)
    }

    /// Set themes unlock state
    func setThemesUnlocked(_ unlocked: Bool) {
        areThemesUnlocked = unlocked
        UserDefaults.standard.set(unlocked, forKey: themesUnlockKey)
    }

    /// Set ads removed state
    func setAdsRemoved(_ removed: Bool) {
        areAdsRemoved = removed
        UserDefaults.standard.set(removed, forKey: adsRemovedKey)
    }

    /// Lock everything (for testing)
    func lock() {
        isFullyUnlocked = false
        areModesUnlocked = false
        areThemesUnlocked = false
        areAdsRemoved = false

        UserDefaults.standard.set(false, forKey: fullUnlockKey)
        UserDefaults.standard.set(false, forKey: modesUnlockKey)
        UserDefaults.standard.set(false, forKey: themesUnlockKey)
        UserDefaults.standard.set(false, forKey: adsRemovedKey)

        print("Everything locked")
    }
}
