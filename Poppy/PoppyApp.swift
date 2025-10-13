//
//  PoppyApp.swift
//  Poppy
//

import SwiftUI

@main
struct PoppyApp: App {
    @StateObject private var highs = HighscoreStore()
    @StateObject private var store = ThemeStore()   

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(highs)
                .environmentObject(store)
        }
    }
}
