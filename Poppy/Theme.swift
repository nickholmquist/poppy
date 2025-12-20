//
//  Theme.swift
//  Poppy
//
//  v1.2 - 27 Total Themes
//  - 12 Original (indices 0-11)
//  - 4 Free Accessibility (indices 12-15)
//  - 11 Premium (indices 16-26)
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


// MARK: - Original Themes (0-11)

extension Theme {
    // 0) Daylight
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
    
    // 1) Sherbet
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
    
    // 2) Sunset
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
    
    // 3) Citrus
    static let citrus = Theme(
        accent:     hex("#FF6B9D"),
        text:       hex("#2A1810"),
        textDark:   hex("#2A1810"),
        textOnAccent: hex("#2A1810"),
        buttonInactive: hex("#F4C2A0"),
        shadow:     .black.opacity(0.25),
        stroke:     .black.opacity(0.15),
        bgTop:      hex("#FFE156"),
        bgBottom:   hex("#FF9A56")
    )
    
    // 4) Ocean
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
    
    // 5) Garden
    static let garden = Theme(
        accent:     hex("#C97B87"),
        text:       Color(red: 0.10, green: 0.12, blue: 0.14),
        textDark:   Color(red: 0.10, green: 0.12, blue: 0.14),
        textOnAccent: Color(red: 0.10, green: 0.12, blue: 0.14),
        buttonInactive: hex("#D4E5DC"),
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.10),
        bgTop:      hex("#D4E8DD"),
        bgBottom:   hex("#B8D9C6")
    )
    
    // 6) Forest
    static let forest = Theme(
        accent:     hex("#52C37E"),
        text:       hex("#0D3818"),
        textDark:   hex("#0D3818"),
        textOnAccent: hex("#0D3818"),
        buttonInactive: hex("#B8D8BE"),
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#E8F5E9"),
        bgBottom:   hex("#A5D6A7")
    )
    
    // 7) Meadow
    static let meadow = Theme(
        accent:     hex("#FFB86B"),
        text:       hex("#F0F6F2"),
        textDark:   hex("#F0F6F2"),
        textOnAccent: hex("#163A2E"),
        buttonInactive: hex("#3A4A44"),
        shadow:     .black.opacity(0.55),
        stroke:     .black.opacity(0.34),
        bgTop:      hex("#0F211B"),
        bgBottom:   hex("#1E3C32")
    )
    
    // 8) Twilight
    static let twilight = Theme(
        accent:     hex("#A78BFA"),
        text:       hex("#E8E4F3"),
        textDark:   hex("#E8E4F3"),
        textOnAccent: hex("#1E1B29"),
        buttonInactive: hex("#3D3850"),
        shadow:     .black.opacity(0.55),
        stroke:     .black.opacity(0.35),
        bgTop:      hex("#000000"),
        bgBottom:   hex("#0A0A0A")
    )
    
    // 9) Memphis
    static let memphis = Theme(
        accent:     hex("#4ECDC4"),  // Vibrant teal-mint
        text:       hex("#4A2D5C"),
        textDark:   hex("#4A2D5C"),
        textOnAccent: hex("#2A1A35"),
        buttonInactive: hex("#C9B8D9"),
        shadow:     .black.opacity(0.20),
        stroke:     .black.opacity(0.14),
        bgTop:      hex("#E0A8F0"),  // Richer orchid-lavender
        bgBottom:   hex("#FFD966")   // Brighter golden yellow
    )
    
    // 10) Minimal Light
    static let minimalLight = Theme(
        accent:     hex("#E8D5B5"),
        text:       hex("#2C2C2C"),
        textDark:   hex("#2C2C2C"),
        textOnAccent: hex("#2C2C2C"),
        buttonInactive: hex("#E5E5E5"),
        shadow:     .black.opacity(0.12),
        stroke:     .black.opacity(0.08),
        bgTop:      hex("#FAFAFA"),
        bgBottom:   hex("#F0F0F0")
    )
    
    // 11) Minimal Dark
    static let minimalDark = Theme(
        accent:     hex("#DC3545"),
        text:       hex("#FFFFFF"),
        textDark:   hex("#FFFFFF"),
        textOnAccent: hex("#FFFFFF"),
        buttonInactive: hex("#3A3A3A"),
        shadow:     .black.opacity(0.60),
        stroke:     .white.opacity(0.12),
        bgTop:      hex("#000000"),
        bgBottom:   hex("#0A0A0A")
    )
}


// MARK: - Free Accessibility Themes (12-15)

extension Theme {
    // 12) Noir - Classic black & white
    static let noir = Theme(
        accent:     hex("#FFFFFF"),
        text:       hex("#FFFFFF"),
        textDark:   hex("#FFFFFF"),
        textOnAccent: hex("#000000"),
        buttonInactive: hex("#333333"),
        shadow:     .black.opacity(0.60),
        stroke:     .black.opacity(0.20),
        bgTop:      hex("#1A1A1A"),
        bgBottom:   hex("#000000")
    )
    
    // 13) Newsprint - Vintage bone paper
    static let newsprint = Theme(
        accent:     hex("#1A1A1A"),
        text:       hex("#1A1A1A"),
        textDark:   hex("#1A1A1A"),
        textOnAccent: hex("#FBF8F1"),
        buttonInactive: hex("#D4CFC4"),
        shadow:     .black.opacity(0.15),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#FBF8F1"),
        bgBottom:   hex("#F0EBE0")
    )
    
    // 14) High Contrast - Maximum visibility for low vision
    static let highContrast = Theme(
        accent:     hex("#FFFF00"),
        text:       hex("#FFFF00"),
        textDark:   hex("#FFFF00"),
        textOnAccent: hex("#000000"),
        buttonInactive: hex("#333333"),
        shadow:     .black.opacity(0.60),
        stroke:     .black.opacity(0.30),
        bgTop:      hex("#000000"),
        bgBottom:   hex("#000000")
    )
    
    // 15) Colorblind Safe - Blue & orange palette (works for all types)
    static let colorblindSafe = Theme(
        accent:     hex("#FF9500"),
        text:       hex("#0A3D62"),
        textDark:   hex("#0A3D62"),
        textOnAccent: hex("#0A3D62"),
        buttonInactive: hex("#A0C4D8"),
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#E8F4F8"),
        bgBottom:   hex("#B8D4E3")
    )
}


// MARK: - Premium Themes (16-26)

extension Theme {
    // 16) Tie-Dye - Retro vibrant swirls
    static let tieDye = Theme(
        accent:     hex("#FFD93D"),
        text:       hex("#4A2040"),
        textDark:   hex("#4A2040"),
        textOnAccent: hex("#2A1020"),
        buttonInactive: hex("#D4A0B0"),
        shadow:     .black.opacity(0.20),
        stroke:     .black.opacity(0.15),
        bgTop:      hex("#FF6B9D"),
        bgBottom:   hex("#7DD3FC")
    )
    
    // 17) Terminal - Hacker matrix vibes
    static let terminal = Theme(
        accent:     hex("#39FF14"),
        text:       hex("#39FF14"),
        textDark:   hex("#39FF14"),
        textOnAccent: hex("#0A1A0A"),
        buttonInactive: hex("#1A3A1A"),
        shadow:     .black.opacity(0.60),
        stroke:     .black.opacity(0.30),
        bgTop:      hex("#111111"),
        bgBottom:   hex("#000000")
    )
    
    // 18) Cotton Candy - Sweet fairground treat
    static let cottonCandy = Theme(
        accent:     hex("#7DD3FC"),
        text:       hex("#4A3050"),
        textDark:   hex("#4A3050"),
        textOnAccent: hex("#2A1830"),
        buttonInactive: hex("#D4C0D8"),
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#FCCEF0"),
        bgBottom:   hex("#CCE8FC")
    )
    
    // 19) Glacier - Icy cool & crisp
    static let glacier = Theme(
        accent:     hex("#67E8F9"),
        text:       hex("#1E3A4A"),
        textDark:   hex("#1E3A4A"),
        textOnAccent: hex("#0A1A20"),
        buttonInactive: hex("#A8C8D4"),
        shadow:     .black.opacity(0.15),
        stroke:     .black.opacity(0.10),
        bgTop:      hex("#F0F9FF"),
        bgBottom:   hex("#CFFAFE")
    )
    
    // 20) Stormy - Electric lightning
    static let stormy = Theme(
        accent:     hex("#FACC15"),
        text:       hex("#FACC15"),
        textDark:   hex("#FACC15"),
        textOnAccent: hex("#1C1917"),
        buttonInactive: hex("#4B5563"),
        shadow:     .black.opacity(0.50),
        stroke:     .black.opacity(0.25),
        bgTop:      hex("#374151"),
        bgBottom:   hex("#1F2937")
    )
    
    // 21) Coral Reef - Tropical underwater
    static let coralReef = Theme(
        accent:     hex("#FF7F6B"),
        text:       hex("#2D4A4A"),
        textDark:   hex("#2D4A4A"),
        textOnAccent: hex("#1A2F2F"),
        buttonInactive: hex("#A8C8C8"),
        shadow:     .black.opacity(0.18),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#E0F2F1"),
        bgBottom:   hex("#B2DFDB")
    )
    
    // 22) Cosmic - Deep space nebula
    static let cosmic = Theme(
        accent:     hex("#C084FC"),
        text:       hex("#E8D5F0"),
        textDark:   hex("#E8D5F0"),
        textOnAccent: hex("#1A0A20"),
        buttonInactive: hex("#3D2850"),
        shadow:     .black.opacity(0.55),
        stroke:     .black.opacity(0.30),
        bgTop:      hex("#1E1033"),
        bgBottom:   hex("#0D0015")
    )
    
    // 23) Ember - Cozy fireplace glow
    static let ember = Theme(
        accent:     hex("#FB923C"),
        text:       hex("#FED7AA"),
        textDark:   hex("#FED7AA"),
        textOnAccent: hex("#1C1210"),
        buttonInactive: hex("#5C4030"),
        shadow:     .black.opacity(0.50),
        stroke:     .black.opacity(0.25),
        bgTop:      hex("#292524"),
        bgBottom:   hex("#1C1917")
    )
    
    // 24) Dusk - Sunset afterglow
    static let dusk = Theme(
        accent:     hex("#FDBA74"),
        text:       hex("#FEF3C7"),
        textDark:   hex("#FEF3C7"),
        textOnAccent: hex("#1E1B4B"),
        buttonInactive: hex("#4338A0"),
        shadow:     .black.opacity(0.50),
        stroke:     .black.opacity(0.20),
        bgTop:      hex("#312E81"),
        bgBottom:   hex("#1E1B4B")
    )
    
    // 25) Vapor - Retro synthwave
    static let vapor = Theme(
        accent:     hex("#22D3EE"),
        text:       hex("#22D3EE"),
        textDark:   hex("#22D3EE"),
        textOnAccent: hex("#0F172A"),
        buttonInactive: hex("#4C1D95"),
        shadow:     .black.opacity(0.55),
        stroke:     .black.opacity(0.30),
        bgTop:      hex("#581C87"),
        bgBottom:   hex("#0F172A")
    )
    
    // 26) Matcha - Fresh zen vibes
    static let matcha = Theme(
        accent:     hex("#A3E635"),
        text:       hex("#365314"),
        textDark:   hex("#365314"),
        textOnAccent: hex("#1A2E05"),
        buttonInactive: hex("#C8D8A8"),
        shadow:     .black.opacity(0.15),
        stroke:     .black.opacity(0.12),
        bgTop:      hex("#FEFCE8"),
        bgBottom:   hex("#ECFCCB")
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
