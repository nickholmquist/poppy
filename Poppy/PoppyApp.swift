//
//  PoppyApp.swift
//  Poppy
//

import SwiftUI

@main
struct PoppyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var highs = HighscoreStore()
    @StateObject private var themeStore = ThemeStore()
    @StateObject private var storeManager = StoreManager()
    @StateObject private var gameCenterManager = GameCenterManager.shared  // NEW
    @State private var showBusinessSplash = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(highs)
                .environmentObject(themeStore)
                .environmentObject(storeManager)
                .onAppear {
                    // Track app launch and session
                    AnalyticsManager.shared.trackAppLaunch()
                    AnalyticsManager.shared.trackSessionStart()
                    
                    // Lock orientation to portrait
                    AppDelegate.orientationLock = .portrait
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
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
