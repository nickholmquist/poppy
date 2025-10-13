//
//  color_Hex.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/7/25.
//


import SwiftUI

extension Color {
    init(hex: String, alpha: Double = 1.0) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b: Double
        switch s.count {
        case 6:
            r = Double((v & 0xFF0000) >> 16) / 255.0
            g = Double((v & 0x00FF00) >> 8) / 255.0
            b = Double(v & 0x0000FF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
