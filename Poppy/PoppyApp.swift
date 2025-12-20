//
//  PoppyApp.swift
//  Poppy
//

import SwiftUI
import GoogleMobileAds

@main
struct PoppyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var highs = HighscoreStore()
    @StateObject private var themeStore = ThemeStore()
    @StateObject private var storeManager = StoreManager()
    @StateObject private var gameCenterManager = GameCenterManager.shared  // NEW
    @State private var showBusinessSplash = true

    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(highs)
                .environmentObject(themeStore)
                .environmentObject(storeManager)
                .environmentObject(isPreview ? AdManager.preview : AdManager.shared)
                .onAppear {
                    // Track app launch and session
                    AnalyticsManager.shared.trackAppLaunch()
                    AnalyticsManager.shared.trackSessionStart()

                    // Lock orientation to portrait
                    AppDelegate.orientationLock = .portrait
                }
                .onOpenURL { url in
                    // Handle Universal Links from shared scores
                    print("Opened via Universal Link: \(url)")
                    AnalyticsManager.shared.trackDeepLink(url: url)
                }
                .overlay {
                    if showBusinessSplash {
                        BusinessSplashView(onComplete: {
                            showBusinessSplash = false
                        })
                    }
                }
        }
    }
}

// MARK: - AppDelegate for Orientation Locking

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize Google Mobile Ads SDK (skip in preview mode)
        if !ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS") {
            MobileAds.shared.start { _ in
                print("Google Mobile Ads SDK initialized")
                AdManager.shared.loadInterstitialAd()
            }
        }
        return true
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
