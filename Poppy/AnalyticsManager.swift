//
//  AnalyticsManager.swift
//  Poppy
//
//  PostHog analytics integration for behavior tracking and crash monitoring
//

import Foundation
import PostHog

@MainActor
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {
        setupPostHog()
    }
    
    private func setupPostHog() {
        // Initialize PostHog with your project API key and host
        let config = PostHogConfig(apiKey: "YOUR_POSTHOG_API_KEY")
        config.host = "https://us.i.posthog.com" // or your self-hosted instance
        
        // Enable crash reporting
        config.captureApplicationLifecycleEvents = true
        config.captureScreenViews = false // We'll track screens manually
        
        PostHogSDK.shared.setup(config)
    }
    
    // MARK: - Game Events
    
    func trackGameStart(duration: Int) {
        PostHogSDK.shared.capture(
            "game_started",
            properties: [
                "duration_seconds": duration
            ]
        )
    }
    
    func trackGameComplete(score: Int, duration: Int, isNewHigh: Bool, timeLimitSeconds: Int) {
        PostHogSDK.shared.capture(
            "game_completed",
            properties: [
                "score": score,
                "duration_seconds": duration,
                "is_new_high": isNewHigh,
                "time_limit": timeLimitSeconds
            ]
        )
    }
    
    func trackHighScore(score: Int, duration: Int) {
        PostHogSDK.shared.capture(
            "high_score_achieved",
            properties: [
                "score": score,
                "duration_seconds": duration
            ]
        )
    }
    
    // MARK: - User Interactions
    
    func trackThemeChange(themeName: String) {
        PostHogSDK.shared.capture(
            "theme_changed",
            properties: [
                "theme": themeName
            ]
        )
    }
    
    func trackTimeDurationChange(from: Int, to: Int) {
        PostHogSDK.shared.capture(
            "time_duration_changed",
            properties: [
                "from_seconds": from,
                "to_seconds": to
            ]
        )
    }
    
    func trackMenuOpened() {
        PostHogSDK.shared.capture("menu_opened")
    }
    
    func trackSettingToggled(setting: String, enabled: Bool) {
        PostHogSDK.shared.capture(
            "setting_toggled",
            properties: [
                "setting": setting,
                "enabled": enabled
            ]
        )
    }
    
    func trackTipJarPurchase(tier: String, amount: String) {
        PostHogSDK.shared.capture(
            "tip_jar_purchase",
            properties: [
                "tier": tier,
                "amount": amount
            ]
        )
    }
    
    // MARK: - Tutorial Events
    
    func trackTutorialStep(step: String, completed: Bool) {
        PostHogSDK.shared.capture(
            "tutorial_step",
            properties: [
                "step": step,
                "completed": completed
            ]
        )
    }
    
    func trackTutorialCompleted() {
        PostHogSDK.shared.capture("tutorial_completed")
    }
    
    // MARK: - App Lifecycle
    
    func trackAppLaunch() {
        PostHogSDK.shared.capture("app_launched")
    }
    
    func trackSessionStart() {
        PostHogSDK.shared.capture("session_started")
    }
    
    // MARK: - User Properties
    
    func updateUserProperties(
        totalGamesPlayed: Int? = nil,
        highestScore: Int? = nil,
        favoriteTheme: String? = nil
    ) {
        var properties: [String: Any] = [:]
        
        if let games = totalGamesPlayed {
            properties["total_games_played"] = games
        }
        if let score = highestScore {
            properties["highest_score"] = score
        }
        if let theme = favoriteTheme {
            properties["favorite_theme"] = theme
        }
        
        PostHogSDK.shared.identify(
            distinctId: PostHogSDK.shared.getDistinctId(),
            userProperties: properties
        )
    }
}