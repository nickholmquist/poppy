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
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(highs)
                .environmentObject(themeStore)
                .environmentObject(storeManager)
                .onAppear {
                    // Connect StoreManager to ThemeStore so it can check locks
                    themeStore.setStoreManager(storeManager)
                    
                    // Lock orientation to portrait
                    AppDelegate.orientationLock = .portrait
                }
                .overlay {
                    if showSplash {
                        SplashScreen(isActive: $showSplash)
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
