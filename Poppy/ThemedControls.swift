//
//  ThemedCard.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/9/25.
//


import SwiftUI

struct ThemedCard<Content: View>: View {
    let theme: Theme
    let corner: CGFloat
    let content: Content

    init(theme: Theme, corner: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.corner = corner
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(theme.bgBottom.opacity(0.95))
                    RoundedRectangle(cornerRadius: corner - 2, style: .continuous)
                        .fill(.white.opacity(0.10))
                        .padding(3)
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .stroke(.black.opacity(0.25), lineWidth: 1.25)
                }
            )
            
    }
}

struct ThemedButton: View {
    let title: String
    let action: () -> Void
    var prominent = false
    var theme = Theme.daylight

    var fill: Color? = nil
    var textColor: Color? = nil
    var height: CGFloat = 52
    var corner: CGFloat = 14
    var font: Font = .system(size: 24, weight: .heavy, design: .rounded)

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .kerning(0.5)
                .frame(maxWidth: .infinity, minHeight: height)
                .padding(.horizontal, 18)
                .background(
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(fill ?? (prominent ? theme.accent : .white.opacity(0.12)))
                )
                .foregroundStyle(
                    textColor ?? (prominent ? theme.textOnAccent : theme.text)
                )
        }
    }
}
