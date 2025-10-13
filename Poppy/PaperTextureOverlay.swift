// PaperTextureOverlay.swift
import SwiftUI

struct PaperTextureOverlay: ViewModifier {
    var name: String = "textureOverlay"
    var opacity: Double = 0.18
    var blend: BlendMode = .multiply   // try .overlay for a brighter wash

    func body(content: Content) -> some View {
        content.overlay(
            Image(name)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .allowsHitTesting(false)   // taps pass through
                .accessibilityHidden(true)
                .blendMode(blend)
                .opacity(opacity)
                .compositingGroup()        // keep the blend scoped
        )
    }
}

extension View {
    func paperTextureOverlay(
        name: String = "textureOverlay",
        opacity: Double = 0.18,
        blend: BlendMode = .multiply
    ) -> some View {
        modifier(PaperTextureOverlay(name: name, opacity: opacity, blend: blend))
    }
}
