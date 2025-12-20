//
//  GameCenterManager.swift
//  Poppy
//
//  Game Center integration for leaderboards
//

import Foundation
import GameKit
import SwiftUI
import Combine

@MainActor
final class GameCenterManager: NSObject, ObservableObject {
    static let shared = GameCenterManager()
    
    @Published var isAuthenticated = false
    @Published var localPlayer: GKLocalPlayer?
    
    // Leaderboard IDs - these MUST match what you create in App Store Connect
    enum LeaderboardID: String, CaseIterable {
        // Classic mode (by duration)
        case classic10s = "com.poppy.leaderboard.classic.10s"
        case classic20s = "com.poppy.leaderboard.classic.20s"
        case classic30s = "com.poppy.leaderboard.classic.30s"
        case classic40s = "com.poppy.leaderboard.classic.40s"
        case classic50s = "com.poppy.leaderboard.classic.50s"
        case classic60s = "com.poppy.leaderboard.classic.60s"

        // Daily mode
        case daily = "com.poppy.leaderboard.daily"

        // Boppy mode (by duration)
        case boppy20s = "com.poppy.leaderboard.boppy.20s"
        case boppy30s = "com.poppy.leaderboard.boppy.30s"
        case boppy40s = "com.poppy.leaderboard.boppy.40s"

        // Lives-based modes (single leaderboard each)
        case zoomy = "com.poppy.leaderboard.zoomy"
        case tappy = "com.poppy.leaderboard.tappy"
        case seeky = "com.poppy.leaderboard.seeky"

        static func classicID(for duration: Int) -> String? {
            switch duration {
            case 10: return LeaderboardID.classic10s.rawValue
            case 20: return LeaderboardID.classic20s.rawValue
            case 30: return LeaderboardID.classic30s.rawValue
            case 40: return LeaderboardID.classic40s.rawValue
            case 50: return LeaderboardID.classic50s.rawValue
            case 60: return LeaderboardID.classic60s.rawValue
            default: return nil
            }
        }

        static func boppyID(for duration: Int) -> String? {
            switch duration {
            case 20: return LeaderboardID.boppy20s.rawValue
            case 30: return LeaderboardID.boppy30s.rawValue
            case 40: return LeaderboardID.boppy40s.rawValue
            default: return nil
            }
        }
    }
    
    private override init() {
        super.init()
        authenticatePlayer()
    }
    
    // MARK: - Authentication
    
    func authenticatePlayer() {
        localPlayer = GKLocalPlayer.local
        
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self = self else { return }
            
            if let viewController = viewController {
                // Game Center needs to show login UI
                // Present it from the root view controller
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(viewController, animated: true)
                }
                return
            }
            
            if let error = error {
                print("❌ Game Center authentication error: \(error.localizedDescription)")
                self.isAuthenticated = false
                return
            }
            
            // Successfully authenticated
            if GKLocalPlayer.local.isAuthenticated {
                print("✅ Game Center authenticated: \(GKLocalPlayer.local.displayName)")
                self.isAuthenticated = true
                
                // Track Game Center authentication
                AnalyticsManager.shared.trackGameCenterAuthenticated(
                    playerID: GKLocalPlayer.local.gamePlayerID
                )
            } else {
                print("⚠️ Game Center not authenticated")
                self.isAuthenticated = false
            }
        }
    }
    
    // MARK: - Leaderboard Submission

    /// Submit score for Classic mode (Poppy)
    func submitClassicScore(_ score: Int, duration: Int) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit Classic score - not authenticated")
            return
        }

        guard let leaderboardID = LeaderboardID.classicID(for: duration) else {
            print("⚠️ Invalid Classic duration: \(duration)")
            return
        }

        submitToLeaderboard(score: score, leaderboardID: leaderboardID, mode: "Classic", duration: duration)
    }

    /// Submit score for Boppy mode
    func submitBoppyScore(_ score: Int, duration: Int) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit Boppy score - not authenticated")
            return
        }

        guard let leaderboardID = LeaderboardID.boppyID(for: duration) else {
            print("⚠️ Invalid Boppy duration: \(duration)")
            return
        }

        submitToLeaderboard(score: score, leaderboardID: leaderboardID, mode: "Boppy", duration: duration)
    }

    /// Submit score for Zoomy mode
    func submitZoomyScore(_ score: Int) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit Zoomy score - not authenticated")
            return
        }

        submitToLeaderboard(score: score, leaderboardID: LeaderboardID.zoomy.rawValue, mode: "Zoomy")
    }

    /// Submit score for Tappy mode
    func submitTappyScore(_ score: Int) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit Tappy score - not authenticated")
            return
        }

        submitToLeaderboard(score: score, leaderboardID: LeaderboardID.tappy.rawValue, mode: "Tappy")
    }

    /// Submit score for Seeky mode
    func submitSeekyScore(_ score: Int) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit Seeky score - not authenticated")
            return
        }

        submitToLeaderboard(score: score, leaderboardID: LeaderboardID.seeky.rawValue, mode: "Seeky")
    }

    /// Internal helper to submit score to a specific leaderboard
    private func submitToLeaderboard(score: Int, leaderboardID: String, mode: String, duration: Int? = nil) {
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )

                if let duration = duration {
                    print("✅ \(mode) score submitted: \(score) to \(duration)s leaderboard")
                } else {
                    print("✅ \(mode) score submitted: \(score)")
                }

                // Track leaderboard submission
                AnalyticsManager.shared.trackLeaderboardSubmission(
                    score: score,
                    duration: duration ?? 0
                )

            } catch {
                print("❌ Failed to submit \(mode) score: \(error.localizedDescription)")
            }
        }
    }

    /// Legacy method for backward compatibility - submits to Classic leaderboard
    func submitScore(_ score: Int, for duration: Int) {
        submitClassicScore(score, duration: duration)
    }
    
    // MARK: - Daily Leaderboard Submission

    func submitDailyScore(_ score: Int) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit daily score - not authenticated")
            return
        }

        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [LeaderboardID.daily.rawValue]
                )

                print("✅ Daily score submitted: \(score)")

                // Track daily leaderboard submission
                AnalyticsManager.shared.trackLeaderboardSubmission(
                    score: score,
                    duration: -1  // Use -1 to indicate daily mode
                )

            } catch {
                print("❌ Failed to submit daily score: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Show Leaderboards

    func showLeaderboards() {
        guard isAuthenticated else {
            print("⚠️ Cannot show leaderboards - not authenticated")
            return
        }
        
        let viewController = GKGameCenterViewController(state: .leaderboards)
        viewController.gameCenterDelegate = self
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true)
            
            // Track leaderboard view
            AnalyticsManager.shared.trackLeaderboardViewed()
        }
    }
    
    // MARK: - Show Specific Leaderboard

    func showLeaderboard(for duration: Int) {
        guard isAuthenticated else {
            print("⚠️ Cannot show leaderboard - not authenticated")
            return
        }

        guard let leaderboardID = LeaderboardID.classicID(for: duration) else {
            print("⚠️ Invalid duration: \(duration)")
            return
        }

        let viewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        viewController.gameCenterDelegate = self

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true)

            // Track specific leaderboard view
            AnalyticsManager.shared.trackLeaderboardViewed(duration: duration)
        }
    }

    // MARK: - Show Daily Leaderboard

    func showDailyLeaderboard() {
        guard isAuthenticated else {
            print("⚠️ Cannot show daily leaderboard - not authenticated")
            return
        }

        let viewController = GKGameCenterViewController(leaderboardID: LeaderboardID.daily.rawValue, playerScope: .global, timeScope: .today)
        viewController.gameCenterDelegate = self

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(viewController, animated: true)

            // Track daily leaderboard view
            AnalyticsManager.shared.trackLeaderboardViewed(duration: -1)
        }
    }
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
