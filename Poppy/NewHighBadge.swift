//
//  NewHighBadge.swift
//  Poppy
//
//  Created by Nick Holmquist on 10/9/25.
//


import SwiftUI

struct NewHighBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
            Text("New High")
                .fontWeight(.bold)
        }
        .font(.footnote)
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Capsule().fill(.yellow.opacity(0.9)))
        .foregroundStyle(.black.opacity(0.85))
        .shadow(radius: 1, y: 1)
    }
}
