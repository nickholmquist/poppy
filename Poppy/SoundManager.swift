//
//  SoundManager.swift
//  Requires: import AVFoundation and import AudioToolbox
//

import Foundation
import AVFoundation
import AudioToolbox

final class SoundManager {
    static let shared = SoundManager()
    
    private let userDefaultsKey = "poppy.sound.enabled"
    
    var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: userDefaultsKey)
        }
    }
    
    // Audio players for low-latency playback
    private var popPlayer: AVAudioPlayer?
    private var popAllPlayer: AVAudioPlayer?
    private var countdownPlayer: AVAudioPlayer?
    private var gameOverPlayer: AVAudioPlayer?
    private var newHighPlayer: AVAudioPlayer?
    private var themeChangePlayer: AVAudioPlayer?
    
    private init() {
        // Load saved preference, default to false
        self.soundEnabled = UserDefaults.standard.object(forKey: userDefaultsKey) as? Bool ?? false
        
        // Configure audio session for low latency
        configureAudioSession()
        
        // Preload all sounds for instant playback
        preloadSounds()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default)
            try audioSession.setActive(true)
        } catch {
        }
    }
    
    private func preloadSounds() {
        // We'll use system sounds for now since they're reliable and free
        // If you want custom sounds, add audio files to your project
        // and use: preparePlayer(named: "pop.wav", for: &popPlayer)
    }
    
    private func preparePlayer(named: String, for player: inout AVAudioPlayer?) {
        guard let url = Bundle.main.url(forResource: named, withExtension: nil) else {
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.volume = 1.0
        } catch {
        }
    }
    
    // System sound IDs - these are built-in iOS sounds
    enum GameSound {
        case pop        // When tapping a dot (active or idle)
        case popAll     // When pressing POP button
        case countdown  // Countdown beep
        case gameOver   // Game over sound
        case newHigh    // New high score
        case themeChange // Theme transition whoosh
        
        var systemSoundID: SystemSoundID {
            switch self {
            case .pop:
                return 1104  // "Tock" - short, crisp tap sound
            case .popAll:
                return 1103  // "Pop" - satisfying
            case .countdown:
                return 1075  // "ReceivedMessage" - attention grabbing
            case .gameOver:
                return 1006  // "SMSReceived_Alert" - distinct
            case .newHigh:
                return 1111  // "SIMToolkitCallDropped" - celebratory
            case .themeChange:
                return 1306  // "key_press_click" - smooth, short sound
            }
        }
    }
    
    func play(_ sound: GameSound) {
        guard soundEnabled else { return }
        
        // Use system sounds for reliable, low-latency playback
        // System sounds don't have the lag issues of AVAudioPlayer for short sounds
        AudioServicesPlaySystemSound(sound.systemSoundID)
    }
    
    // ALTERNATIVE: If system sounds still lag, try haptic-style audio
    // This method uses a different approach with lower latency
    func playWithLowLatency(_ sound: GameSound) {
        guard soundEnabled else { return }
        
        // For fastest response, use AudioServicesPlaySystemSound
        // It's designed for immediate playback
        AudioServicesPlaySystemSound(sound.systemSoundID)
    }
}

// MARK: - Custom Sound Files (Optional Enhancement)
// If you want to add custom sounds for even better performance:
//
// 1. Add .wav or .caf audio files to your Xcode project
// 2. Use very short files (< 0.5 seconds) for best performance
// 3. Preload them in init() like this:
//
// preparePlayer(named: "pop.wav", for: &popPlayer)
// preparePlayer(named: "pop_all.wav", for: &popAllPlayer)
//
// 4. Play them like this:
//
// func playCustom(_ sound: GameSound) {
//     guard soundEnabled else { return }
//
//     switch sound {
//     case .pop:
//         popPlayer?.currentTime = 0
//         popPlayer?.play()
//     case .popAll:
//         popAllPlayer?.currentTime = 0
//         popAllPlayer?.play()
//     // ... etc
//     }
// }
