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
    // Format: com.yourcompany.poppy.leaderboard.XXs
    enum LeaderboardID: String, CaseIterable {
        case tenSeconds = "com.poppy.leaderboard.10s"
        case twentySeconds = "com.poppy.leaderboard.20s"
        case thirtySeconds = "com.poppy.leaderboard.30s"
        case fortySeconds = "com.poppy.leaderboard.40s"
        case fiftySeconds = "com.poppy.leaderboard.50s"
        case sixtySeconds = "com.poppy.leaderboard.60s"
        
        static func id(for duration: Int) -> String? {
            switch duration {
            case 10: return LeaderboardID.tenSeconds.rawValue
            case 20: return LeaderboardID.twentySeconds.rawValue
            case 30: return LeaderboardID.thirtySeconds.rawValue
            case 40: return LeaderboardID.fortySeconds.rawValue
            case 50: return LeaderboardID.fiftySeconds.rawValue
            case 60: return LeaderboardID.sixtySeconds.rawValue
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
    
    func submitScore(_ score: Int, for duration: Int) {
        guard isAuthenticated else {
            print("⚠️ Cannot submit score - not authenticated")
            return
        }
        
        guard let leaderboardID = LeaderboardID.id(for: duration) else {
            print("⚠️ Invalid duration: \(duration)")
            return
        }
        
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboardID]
                )
                
                print("✅ Score submitted: \(score) to \(duration)s leaderboard")
                
                // Track leaderboard submission
                AnalyticsManager.shared.trackLeaderboardSubmission(
                    score: score,
                    duration: duration
                )
                
            } catch {
                print("❌ Failed to submit score: \(error.localizedDescription)")
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
        
        guard let leaderboardID = LeaderboardID.id(for: duration) else {
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
}

// MARK: - GKGameCenterControllerDelegate

extension GameCenterManager: GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        Task { @MainActor in
            gameCenterViewController.dismiss(animated: true)
        }
    }
}
