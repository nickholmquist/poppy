//
//  color_Hex.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/7/25.
//


import SwiftUI
import UIKit

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

    /// Returns a darker version of the color by the given percentage (0.0 to 1.0)
    func darker(by percentage: CGFloat = 0.2) -> Color {
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h), saturation: Double(s), brightness: Double(max(b - percentage, 0)), opacity: Double(a))
    }
}
