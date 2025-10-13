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
    
    // 2) Breeze
    static let breeze = Theme(
        accent:     hex("#7AC8FF"),
        text:       Color(red: 0.10, green: 0.12, blue: 0.14),
        textDark:   Color(red: 0.10, green: 0.12, blue: 0.14),
        textOnAccent: Color(red: 0.10, green: 0.12, blue: 0.14),
        buttonInactive: hex("#D5DBE0"),
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.10),
        bgTop:      hex("#CDEBFF"),
        bgBottom:   hex("#F4FBFF")
    )
    
    // 3) Meadow — night vibe
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
    
    // 4) Sherbet
    static let sherbet = Theme(
        accent:     hex("#6B8CFF"),
        text:       Color(red: 0.10, green: 0.12, blue: 0.14),
        textDark:   Color(red: 0.10, green: 0.12, blue: 0.14),
        textOnAccent: Color(red: 0.10, green: 0.12, blue: 0.14),
        buttonInactive: hex("#D9D4DC"),
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.10),
        bgTop:      hex("#FFF1E0"),
        bgBottom:   hex("#FFE4F1")
    )
    
    // 5) Beachglass — slightly darker day
    static let beachglass = Theme(
        accent:     hex("#FFA6B0"),
        text:       Color(red: 0.10, green: 0.12, blue: 0.14),
        textDark:   Color(red: 0.10, green: 0.12, blue: 0.14),
        textOnAccent: Color(red: 0.10, green: 0.12, blue: 0.14),
        buttonInactive: hex("#CFE3DD"),
        shadow:     .black.opacity(0.20),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#D0F7EA"),
        bgBottom:   hex("#AEE6D4")
    )
    
    // 6) Citrus — night vibe
    static let citrus = Theme(
        accent:     hex("#FFB673"),                  // soft tangerine
        text:       Color.white.opacity(0.92),       // light ink on warm dark page
        textDark:   Color.white.opacity(0.92),
        textOnAccent: hex("#2A1F12"),                // cocoa-brown on accent
        buttonInactive: hex("#3E372A"),
        shadow:     .black.opacity(0.60),
        stroke:     .black.opacity(0.36),
        bgTop:      hex("#17130D"),
        bgBottom:   hex("#2B2115")
    )
    
    // 7) Ember — night vibe with orange and charcoal
    static let ember = Theme(
        accent:     hex("#FF8C42"),                  // vibrant orange
        text:       hex("#E8E8E8"),                  // light grey text on dark
        textDark:   hex("#E8E8E8"),
        textOnAccent: hex("#1A1A1A"),                // dark charcoal on orange
        buttonInactive: hex("#3D3D3D"),
        shadow:     .black.opacity(0.65),
        stroke:     .black.opacity(0.40),
        bgTop:      hex("#2A2A2A"),                  // charcoal grey
        bgBottom:   hex("#1A1A1A")                   // deeper charcoal
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
