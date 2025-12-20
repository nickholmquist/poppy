//
//  PoppyPlusUpsell.swift
//  Poppy
//
//  Full-screen upsell for Poppy Plus ($5.99 - everything unlocked)
//

import SwiftUI
import StoreKit

struct PoppyPlusUpsell: View {
    let theme: Theme
    let onDismiss: () -> Void

    @EnvironmentObject var store: StoreManager
    @State private var isPurchasing = false

    private var poppyPlusProduct: Product? {
        store.product(for: StoreManager.ProductID.poppyPlus)
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black
                .opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithSound()
                }

            // Card
            VStack(spacing: 24) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: dismissWithSound) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.textDark.opacity(0.5))
                            .frame(width: 32, height: 32)
                    }
                }

                // Hero section
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(theme.accent.opacity(0.15))
                            .frame(width: 80, height: 80)

                        Image(systemName: "star.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(theme.accent)
                    }

                    // Title
                    Text("Poppy Plus")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.textDark)

                    // Subtitle
                    Text("Unlock everything. Forever.")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textDark.opacity(0.7))
                }

                // Features list
                VStack(alignment: .leading, spacing: 14) {
                    FeatureRow(icon: "gamecontroller.fill", text: "All 8 game modes", theme: theme)
                    FeatureRow(icon: "paintpalette.fill", text: "All 27 premium themes", theme: theme)
                    FeatureRow(icon: "nosign", text: "No ads. Ever.", theme: theme)
                    FeatureRow(icon: "heart.fill", text: "Support indie development", theme: theme)
                }
                .padding(.horizontal, 8)

                Spacer()

                // Purchase button
                VStack(spacing: 12) {
                    Button(action: purchasePoppyPlus) {
                        HStack(spacing: 10) {
                            if isPurchasing {
                                ProgressView()
                                    .tint(theme.textOnAccent)
                            } else {
                                Text("Get Poppy Plus")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))

                                if let product = poppyPlusProduct {
                                    Text("•")
                                        .font(.system(size: 18, weight: .bold))
                                    Text(product.displayPrice)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                }
                            }
                        }
                        .foregroundStyle(theme.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(theme.accent)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.1), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing || poppyPlusProduct == nil)

                    // One-time purchase note
                    Text("One-time purchase. No subscription.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textDark.opacity(0.5))
                }

                // Restore purchases link
                Button(action: restorePurchases) {
                    Text("Restore Purchases")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.accent)
                }
                .padding(.bottom, 8)
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(theme.bgTop)
                    .shadow(color: Color.black.opacity(0.3), radius: 24, y: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(theme.textDark.opacity(0.1), lineWidth: 2)
            )
        }
        .transition(.opacity)
    }

    private func dismissWithSound() {
        SoundManager.shared.play(.pop)
        HapticsManager.shared.light()
        onDismiss()
    }

    private func purchasePoppyPlus() {
        guard let product = poppyPlusProduct else { return }

        isPurchasing = true
        Task {
            do {
                try await store.purchase(product)
                // If purchase succeeded, dismiss
                if store.hasPoppyPlus {
                    onDismiss()
                }
            } catch {
                print("Purchase failed: \(error)")
            }
            isPurchasing = false
        }
    }

    private func restorePurchases() {
        SoundManager.shared.play(.pop)
        HapticsManager.shared.light()

        Task {
            await store.restorePurchases()
            // If restore succeeded and we now have Poppy Plus, dismiss
            if store.hasPoppyPlus {
                onDismiss()
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String
    let theme: Theme

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(theme.accent)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(theme.textDark)

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Poppy Plus Upsell") {
    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        PoppyPlusUpsell(
            theme: .daylight,
            onDismiss: {}
        )
        .environmentObject(StoreManager.preview)
    }
}
