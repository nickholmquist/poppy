//
//  HapticsManager.swift
//  Poppy
//
//  Manages haptic feedback settings with persistence
//

import Foundation
import UIKit

final class HapticsManager {
    static let shared = HapticsManager()
    
    private let userDefaultsKey = "poppy.haptics.enabled"
    
    var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: userDefaultsKey)
        }
    }
    
    private init() {
        // Load saved preference, default to true
        self.hapticsEnabled = UserDefaults.standard.object(forKey: userDefaultsKey) as? Bool ?? true
    }
    
    // Convenience methods for different haptic types
    func light() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    func medium() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    func heavy() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    func rigid() {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    }
    
    func success() {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    func error() {
        guard hapticsEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}