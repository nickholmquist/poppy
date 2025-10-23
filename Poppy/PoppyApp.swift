//
//  PoppyApp.swift
//  Poppy
//

import SwiftUI

@main
struct PoppyApp: App {
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
                }
                .overlay {
                    if showSplash {
                        SplashScreen(isActive: $showSplash)
                    }
                }
        }
    }
    
}


