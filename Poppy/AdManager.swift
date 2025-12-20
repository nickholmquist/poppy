//
//  AdManager.swift
//  Poppy
//

import SwiftUI
import Combine
import GoogleMobileAds

class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()
    static let preview = AdManager(preview: true)

    private let isPreview: Bool

    // MARK: - Ad Unit IDs
    #if DEBUG
    private let interstitialAdUnitID = "ca-app-pub-3940256099942544/4411468910" // Test ID for development
    #else
    private let interstitialAdUnitID = "ca-app-pub-3758940728665504/9014438630" // Production ID
    #endif

    // MARK: - Properties
    private var interstitialAd: InterstitialAd?
    @Published var isAdLoaded = false

    // Play counter for showing ads every 6-7 games
    private var playCount = 0
    private var playsUntilAd = Int.random(in: 6...7)

    override init() {
        self.isPreview = false
        super.init()
        // Ad loading is triggered by AppDelegate after SDK initialization
    }

    private init(preview: Bool) {
        self.isPreview = preview
        super.init()
        // Don't initialize anything for preview
    }

    // MARK: - Load Interstitial Ad
    func loadInterstitialAd() {
        // Don't load ads in preview mode
        guard !isPreview, !ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS") else {
            return
        }
        let request = Request()
        InterstitialAd.load(with: interstitialAdUnitID, request: request) { [weak self] ad, error in
            guard let self = self else { return }

            if let error = error {
                print("Failed to load interstitial ad: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isAdLoaded = false
                }
                return
            }

            self.interstitialAd = ad
            self.interstitialAd?.fullScreenContentDelegate = self
            DispatchQueue.main.async {
                self.isAdLoaded = true
            }
            print("Interstitial ad loaded successfully")
        }
    }

    // MARK: - Show Interstitial Ad
    @MainActor
    func showInterstitialAd() {
        guard !isPreview else { return }

        guard let ad = interstitialAd else {
            print("Interstitial ad not ready, loading...")
            loadInterstitialAd()
            return
        }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Could not find root view controller")
            return
        }

        // Find the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }

        ad.present(from: topController)
    }

    // MARK: - Check if user has removed ads (for premium users)
    func shouldShowAds(storeManager: StoreManager) -> Bool {
        return !storeManager.hasAdsRemoved
    }

    // MARK: - Game completion with ad-removal check
    @MainActor
    func gameCompleted(storeManager: StoreManager) {
        // Don't show ads in preview mode or if user has purchased ad removal
        guard !isPreview, shouldShowAds(storeManager: storeManager) else {
            return
        }

        playCount += 1
        print("Play count: \(playCount)/\(playsUntilAd)")

        if playCount >= playsUntilAd {
            showInterstitialAd()
            playCount = 0
            playsUntilAd = Int.random(in: 6...7) // Reset for next cycle
        }
    }
}

// MARK: - FullScreenContentDelegate
extension AdManager: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Interstitial ad dismissed")
        interstitialAd = nil
        DispatchQueue.main.async {
            self.isAdLoaded = false
        }
        loadInterstitialAd() // Preload next ad
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Failed to present interstitial ad: \(error.localizedDescription)")
        interstitialAd = nil
        DispatchQueue.main.async {
            self.isAdLoaded = false
        }
        loadInterstitialAd()
    }

    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("Interstitial ad will present")
    }
}
