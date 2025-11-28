//
//  Theme.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/6/25.
//

import SwiftUI

struct Theme {
    // Palette
    let accent: Color
    let text: Color           // ink on the page background
    let textDark: Color       // keep for legacy, you can map it to text or onAccent
    let textOnAccent: Color   // ink on accent-filled surfaces (scoreboard/start)
    let buttonInactive: Color
    let shadow: Color
    let stroke: Color

    // Background gradient colors
    let bgTop: Color
    let bgBottom: Color

    var background: LinearGradient {
        LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
    }
}


// MARK: - Preset Themes

extension Theme {
    // 1) Daylight
    static let daylight = Theme(
        accent:     hex("#F59AA1"),
        text:       Color(red: 0.10, green: 0.12, blue: 0.14),
        textDark:   Color(red: 0.10, green: 0.12, blue: 0.14),
        textOnAccent: Color(red: 0.10, green: 0.12, blue: 0.14),
        buttonInactive: hex("#C9CFD4"),
        shadow:     .black.opacity(0.20),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#F9F6EC"),
        bgBottom:   hex("#E6F4FF")
    )
    
    // 2) Sherbet
    static let sherbet = Theme(
        accent:     hex("#E879F9"),
        text:       Color(red: 0.10, green: 0.12, blue: 0.14),
        textDark:   Color(red: 0.10, green: 0.12, blue: 0.14),
        textOnAccent: Color(red: 0.10, green: 0.12, blue: 0.14),
        buttonInactive: hex("#D9D4DC"),
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.10),
        bgTop:      hex("#FFF1E0"),
        bgBottom:   hex("#FFE4F1")
    )
    
    // 3) Sunset
    static let sunset = Theme(
        accent:     hex("#FF8B7B"),
        text:       hex("#5A3028"),
        textDark:   hex("#5A3028"),
        textOnAccent: hex("#2A1810"),
        buttonInactive: hex("#E5C4BC"),
        shadow:     .black.opacity(0.20),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#FFE8E1"),
        bgBottom:   hex("#FFB5A7")
    )
    
    // 4) Citrus
    static let citrus = Theme(
        accent:     hex("#FF6B9D"),  // Hot pink/coral
        text:       hex("#2A1810"),  // Deep brown
        textDark:   hex("#2A1810"),
        textOnAccent: hex("#2A1810"),
        buttonInactive: hex("#F4C2A0"),  // Peachy tan
        shadow:     .black.opacity(0.25),
        stroke:     .black.opacity(0.15),
        bgTop:      hex("#FFE156"),  // Bright yellow
        bgBottom:   hex("#FF9A56")   // Tangerine orange
    )
    
    // 5) Ocean
    static let ocean = Theme(
        accent:     hex("#2D9CDB"),
        text:       hex("#B3E5FC"),
        textDark:   hex("#B3E5FC"),
        textOnAccent: hex("#0A1929"),
        buttonInactive: hex("#1E3A4F"),
        shadow:     .black.opacity(0.55),
        stroke:     .black.opacity(0.35),
        bgTop:      hex("#0A1929"),
        bgBottom:   hex("#1A4E66")
    )
    
    // 6) Garden (renamed & toned down from Beachglass)
    static let garden = Theme(
        accent:     hex("#C97B87"),  // Softer dusty rose
        text:       Color(red: 0.10, green: 0.12, blue: 0.14),
        textDark:   Color(red: 0.10, green: 0.12, blue: 0.14),
        textOnAccent: Color(red: 0.10, green: 0.12, blue: 0.14),
        buttonInactive: hex("#D4E5DC"),
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.10),
        bgTop:      hex("#D4E8DD"),  // Softer sage
        bgBottom:   hex("#B8D9C6")   // Softer sage-mint
    )
    
    // 7) Forest - DARKER TEXT
    static let forest = Theme(
        accent:     hex("#52C37E"),
        text:       hex("#0D3818"),  // Much darker forest green
        textDark:   hex("#0D3818"),
        textOnAccent: hex("#0D3818"),
        buttonInactive: hex("#B8D8BE"),
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#E8F5E9"),
        bgBottom:   hex("#A5D6A7")
    )
    
    // 8) Meadow
    static let meadow = Theme(
        accent:     hex("#FFB86B"),                  // warm peach card/button
        text:       hex("#F0F6F2"),                  // light ink on dark page
        textDark:   hex("#F0F6F2"),                  // keep equal to text for now
        textOnAccent: hex("#163A2E"),                // deep pine on yellow accent
        buttonInactive: hex("#3A4A44"),
        shadow:     .black.opacity(0.55),
        stroke:     .black.opacity(0.34),
        bgTop:      hex("#0F211B"),                  // deep pine
        bgBottom:   hex("#1E3C32")                   // dark teal green
    )
    
    // 9) Twilight
    static let twilight = Theme(
        accent:     hex("#A78BFA"),  // Soft lavender
        text:       hex("#E8E4F3"),  // Light purple-grey
        textDark:   hex("#E8E4F3"),
        textOnAccent: hex("#1E1B29"),  // Deep purple-navy
        buttonInactive: hex("#3D3850"),
        shadow:     .black.opacity(0.55),
        stroke:     .black.opacity(0.35),
        bgTop:      hex("#000000"),  // Deep purple-navy
        bgBottom:   hex("#0A0A0A")   // Rich purple
    )
    
    // 10) Memphis Pastel
    static let memphis = Theme(
        accent:     hex("#7DD3C0"),  // Soft mint
        text:       hex("#5A3D6E"),  // Deep purple-brown
        textDark:   hex("#5A3D6E"),
        textOnAccent: hex("#2A1A35"),  // Very dark purple
        buttonInactive: hex("#D4C5E0"),  // Light lavender
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#E8D4F8"),  // Soft lavender
        bgBottom:   hex("#FFE8B3")   // Soft butter yellow
    )
    
    // 11) Minimal Light
    static let minimalLight = Theme(
        accent:     hex("#E8D5B5"),  // Warm cream
        text:       hex("#2C2C2C"),
        textDark:   hex("#2C2C2C"),
        textOnAccent: hex("#2C2C2C"),
        buttonInactive: hex("#E5E5E5"),
        shadow:     .black.opacity(0.12),
        stroke:     .black.opacity(0.08),
        bgTop:      hex("#FAFAFA"),
        bgBottom:   hex("#F0F0F0")
    )
    
    // 12) Minimal Dark
    static let minimalDark = Theme(
        accent:     hex("#DC3545"),  // Deep red
        text:       hex("#FFFFFF"),
        textDark:   hex("#FFFFFF"),
        textOnAccent: hex("#FFFFFF"),  // White text on red
        buttonInactive: hex("#3A3A3A"),
        shadow:     .black.opacity(0.60),
        stroke:     .white.opacity(0.12),
        bgTop:      hex("#000000"),
        bgBottom:   hex("#0A0A0A")
    )
    
}
// MARK: - Local hex helper (keeps this file self-contained)
@inline(__always)
private func hex(_ s: String, alpha: Double = 1.0) -> Color {
    var str = s.trimmingCharacters(in: .whitespacesAndNewlines)
    if str.hasPrefix("#") { str.removeFirst() }
    var v: UInt64 = 0
    Scanner(string: str).scanHexInt64(&v)

    let r, g, b: Double
    if str.count == 6 {
        r = Double((v & 0xFF0000) >> 16) / 255.0
        g = Double((v & 0x00FF00) >> 8) / 255.0
        b = Double(v & 0x0000FF) / 255.0
    } else {
        r = 1; g = 1; b = 1
    }
    return Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
}
