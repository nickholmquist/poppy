//
//  SoundManager.swift
//  Poppy
//
//  Safe sound manager with volume and speed controls
//

import Foundation
import AVFoundation
import AudioToolbox

@MainActor
final class SoundManager {
    static let shared = SoundManager()
    
    private let userDefaultsKey = "poppy.sound.enabled"
    
    var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: userDefaultsKey)
        }
    }
    
    // Track whether custom sounds are available
    private var customSoundsAvailable = false
    
    // Audio players for each sound effect (optional - may not load)
    private var popPlayer: AVAudioPlayer?
    private var popUpPlayer: AVAudioPlayer?
    private var countdownPlayer: AVAudioPlayer?
    private var gameOverPlayer: AVAudioPlayer?
    private var newHighPlayer: AVAudioPlayer?
    private var newHighEndPlayer: AVAudioPlayer?
    private var themeChangePlayer: AVAudioPlayer?
    private var menuPlayer: AVAudioPlayer?
    private var timeSelectPlayer: AVAudioPlayer?
    private var scoreboardExpandPlayer: AVAudioPlayer?
    private var scoreboardCollapsePlayer: AVAudioPlayer?
    
    // ========================================
    // 🎛️ SOUND CUSTOMIZATION CONTROLS
    // ========================================
    // Adjust these values to customize each sound!
    // Volume: 0.0 (silent) to 1.0 (full)
    // Rate: 0.5 (half speed) to 2.0 (double speed)
    
    struct SoundConfig {
        var volume: Float
        var rate: Float  // 1.0 = normal speed
        
        init(volume: Float = 1.0, rate: Float = 1.0) {
            self.volume = volume
            self.rate = rate
        }
    }
    
    private var soundConfigs: [GameSound: SoundConfig] = [
        .pop: SoundConfig(volume: 1.0, rate: 1.0),
        .popUp: SoundConfig(volume: 1.0, rate: 1.5),        // ⚡ Slightly faster
        .countdownStart: SoundConfig(volume: 1.0, rate: 1.0),
        .gameOver: SoundConfig(volume: 1.0, rate: 1.0),
        .newHigh: SoundConfig(volume: 0.6, rate: 1.0),       // 🔉 Quieter
        .newHighEnd: SoundConfig(volume: 1.0, rate: 1.0),
        .themeChange: SoundConfig(volume: 0.4, rate: 1.0),
        .menu: SoundConfig(volume: 1.0, rate: 1.0),
        .timeSelect: SoundConfig(volume: 1.0, rate: 1.0),
        .scoreboardExpand: SoundConfig(volume: 1.0, rate: 1.0),
        .scoreboardCollapse: SoundConfig(volume: 1.0, rate: 1.0)
    ]
    
    private init() {
        // Load saved preference, default to false
        self.soundEnabled = UserDefaults.standard.object(forKey: userDefaultsKey) as? Bool ?? false
        
        // Try to configure audio session (fail gracefully if it doesn't work)
        configureAudioSession()
        
        // Try to preload sounds (fall back to system sounds if unavailable)
        preloadSounds()
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Failed to configure audio session: \(error)")
            // Continue anyway - system sounds will still work
        }
    }
    
    private func preloadSounds() {
        // Try to load custom sounds
        let loadedCount = [
            preparePlayer(named: "pop.wav", for: &popPlayer),
            preparePlayer(named: "pop_up.wav", for: &popUpPlayer, enableRate: true),  // Enable rate control
            preparePlayer(named: "countdown.wav", for: &countdownPlayer),
            preparePlayer(named: "game_over.wav", for: &gameOverPlayer),
            preparePlayer(named: "new_high.wav", for: &newHighPlayer),
            preparePlayer(named: "new_high_end.wav", for: &newHighEndPlayer),
            preparePlayer(named: "theme_change.wav", for: &themeChangePlayer),
            preparePlayer(named: "time_select.wav", for: &timeSelectPlayer),
            preparePlayer(named: "scoreboard_expand.wav", for: &scoreboardExpandPlayer),
            preparePlayer(named: "scoreboard_collapse.wav", for: &scoreboardCollapsePlayer)
        ].filter { $0 }.count
        
        // Reuse pop sound for menu if main pop loaded
        if popPlayer != nil {
            menuPlayer = popPlayer
        }
        
        // Consider custom sounds available if at least half loaded
        customSoundsAvailable = loadedCount >= 5
        
        if customSoundsAvailable {
            print("✅ Custom sounds loaded successfully (\(loadedCount)/10)")
        } else {
            print("⚠️ Custom sounds not available, using system sounds fallback")
        }
    }
    
    @discardableResult
    private func preparePlayer(named: String, for player: inout AVAudioPlayer?, enableRate: Bool = false) -> Bool {
        guard let url = Bundle.main.url(forResource: named, withExtension: nil) else {
            print("⚠️ Sound file not found: \(named)")
            return false
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.volume = 1.0
            
            // Enable rate control if requested (allows speed adjustment)
            if enableRate {
                player?.enableRate = true
            }
            
            return true
        } catch {
            print("⚠️ Failed to load sound \(named): \(error)")
            return false
        }
    }
    
    enum GameSound {
        case pop              // Single dot tap
        case popUp            // POP button press
        case popAll           // Legacy (redirects to popUp)
        case countdownStart   // Countdown begins
        case gameOver         // Game over
        case newHigh          // Crossing high score
        case newHighEnd       // End celebration
        case themeChange      // Theme transition
        case menu             // Menu tap
        case timeSelect       // Time picker selection
        case scoreboardExpand    // Scoreboard opens
        case scoreboardCollapse  // Scoreboard closes
        
        // Fallback system sound IDs
        var systemSoundID: SystemSoundID {
            switch self {
            case .pop: return 1104         // "Tock"
            case .popUp: return 1103       // "Pop"
            case .popAll: return 1103      // "Pop"
            case .countdownStart: return 1075  // "ReceivedMessage"
            case .gameOver: return 1006    // "SMSReceived_Alert"
            case .newHigh: return 1111     // Celebratory
            case .newHighEnd: return 1111  // Celebratory
            case .themeChange: return 1306 // Smooth click
            case .menu: return 1104        // "Tock"
            case .timeSelect: return 1104  // "Tock" - light tap
            case .scoreboardExpand: return 1306   // Smooth whoosh
            case .scoreboardCollapse: return 1306 // Smooth whoosh
            }
        }
    }
    
    func play(_ sound: GameSound) {
        guard soundEnabled else { return }
        
        // If custom sounds available, try to use them
        if customSoundsAvailable {
            let played = playCustomSound(sound)
            if played { return }
        }
        
        // Fallback to system sound
        AudioServicesPlaySystemSound(sound.systemSoundID)
    }
    
    private func playCustomSound(_ sound: GameSound) -> Bool {
        // Get config for this sound
        let config = soundConfigs[sound] ?? SoundConfig()
        
        switch sound {
        case .pop:
            guard let player = popPlayer else { return false }
            player.volume = config.volume
            player.currentTime = 0
            player.play()
            return true
            
        case .popUp:
            guard let player = popUpPlayer else { return false }
            player.volume = config.volume
            player.rate = config.rate  // Apply speed adjustment
            player.currentTime = 0
            player.play()
            return true
            
        case .popAll:
            // Redirect to popUp
            guard let player = popUpPlayer else { return false }
            player.volume = config.volume
            player.rate = config.rate  // Apply speed adjustment
            player.currentTime = 0
            player.play()
            return true
            
        case .countdownStart:
            guard let player = countdownPlayer else { return false }
            player.volume = config.volume
            player.currentTime = 0
            player.play()
            return true
            
        case .gameOver:
            guard let player = gameOverPlayer else { return false }
            player.volume = config.volume
            player.currentTime = 0
            player.play()
            return true
            
        case .newHigh:
            guard let player = newHighPlayer else { return false }
            player.volume = config.volume  // Apply volume reduction
            player.currentTime = 0
            player.play()
            return true
            
        case .newHighEnd:
            guard let player = newHighEndPlayer else { return false }
            player.volume = config.volume
            player.currentTime = 0
            player.play()
            return true
            
        case .themeChange:
            guard let player = themeChangePlayer else { return false }
            player.volume = config.volume
            player.currentTime = 0
            player.play()
            return true
            
        case .menu:
            guard let player = menuPlayer else { return false }
            player.volume = config.volume
            player.currentTime = 0
            player.play()
            return true
            
        case .timeSelect:
            // Use dedicated time_select.wav sound
            guard let player = timeSelectPlayer else { return false }
            player.volume = config.volume
            player.currentTime = 0
            player.play()
            return true
            
        case .scoreboardExpand:
            guard let player = scoreboardExpandPlayer else { return false }
            player.volume = config.volume
            player.currentTime = 0
            player.play()
            return true
            
        case .scoreboardCollapse:
            guard let player = scoreboardCollapsePlayer else { return false }
            player.volume = config.volume
            player.currentTime = 0
            player.play()
            return true
        }
    }
}
