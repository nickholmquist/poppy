//
//  PaperTint.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/7/25.
//


import SwiftUI

struct PaperTint: ViewModifier {
    let tint: Color
    let opacity: Double
    let brightness: Double
    func body(content: Content) -> some View {
        content
            .colorMultiply(tint)
            .opacity(opacity)
            .brightness(brightness)
    }
}

extension View {
    func paperTint(_ tint: Color,
                   opacity: Double = 0.95,
                   brightness: Double = 0.06) -> some View {
        modifier(PaperTint(tint: tint, opacity: opacity, brightness: brightness))
    }
}
