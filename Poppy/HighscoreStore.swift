//
//  HighscoreStore.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/6/25.
//


import Foundation
import Combine   // <-- required

@MainActor
final class HighscoreStore: ObservableObject {
    // best score per round length in seconds
    @Published private(set) var best: [Int: Int] = [:]
    private let key = "poppy.best.scores"

    init() {
        if let data = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] {
            var out: [Int: Int] = [:]
            for (k, v) in data where Int(k) != nil {
                out[Int(k)!] = v
            }
            best = out
        }
    }

    func register(score: Int, for seconds: Int) {
        if score > (best[seconds] ?? 0) {
            best[seconds] = score

            var toSave: [String: Int] = [:]
            for (k, v) in best { toSave["\(k)"] = v }
            UserDefaults.standard.set(toSave, forKey: key)
        }
    }
    
    func reset() {
        best = [:]
        UserDefaults.standard.removeObject(forKey: key)
    }
}
