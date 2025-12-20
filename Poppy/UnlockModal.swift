//
//  UnlockModal.swift
//  Poppy
//
//  Contextual modal for unlocking specific content (modes or themes)
//  Shows bundle purchase option with Poppy Plus as an upgrade upsell
//

import SwiftUI
import StoreKit

// MARK: - Unlock Type

enum UnlockType {
    case modes
    case themes

    var title: String {
        switch self {
        case .modes: return "Unlock Game Modes"
        case .themes: return "Unlock Themes"
        }
    }

    var icon: String {
        switch self {
        case .modes: return "gamecontroller.fill"
        case .themes: return "paintpalette.fill"
        }
    }

    var description: String {
        switch self {
        case .modes: return "Get access to Zoomy, Tappy, and Seeky"
        case .themes: return "Get access to all 11 premium themes"
        }
    }

    var bundleProductID: String {
        switch self {
        case .modes: return StoreManager.ProductID.modesBundle
        case .themes: return StoreManager.ProductID.themesBundle
        }
    }

    var bundleName: String {
        switch self {
        case .modes: return "Game Modes"
        case .themes: return "Premium Themes"
        }
    }
}

// MARK: - Unlock Modal

struct UnlockModal: View {
    let theme: Theme
    let unlockType: UnlockType
    let onDismiss: () -> Void
    let onShowPoppyPlus: () -> Void

    @EnvironmentObject var store: StoreManager
    @State private var isPurchasing = false

    private var bundleProduct: Product? {
        store.product(for: unlockType.bundleProductID)
    }

    private var poppyPlusProduct: Product? {
        store.product(for: StoreManager.ProductID.poppyPlus)
    }

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black
                .opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithSound()
                }

            // Card
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(theme.accent.opacity(0.15))
                            .frame(width: 64, height: 64)

                        Image(systemName: unlockType.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(theme.accent)
                    }

                    // Title
                    Text(unlockType.title)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundStyle(theme.textDark)

                    // Description
                    Text(unlockType.description)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textDark.opacity(0.7))
                        .multilineTextAlignment(.center)
                }

                // Purchase options
                VStack(spacing: 12) {
                    // Bundle purchase button
                    Button(action: purchaseBundle) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .tint(theme.textOnAccent)
                            } else {
                                Text("Unlock \(unlockType.bundleName)")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))

                                if let product = bundleProduct {
                                    Text("•")
                                        .font(.system(size: 17, weight: .bold))
                                    Text(product.displayPrice)
                                        .font(.system(size: 17, weight: .bold, design: .rounded))
                                }
                            }
                        }
                        .foregroundStyle(theme.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(theme.accent)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.black.opacity(0.1), lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isPurchasing || bundleProduct == nil)

                    // Poppy Plus upsell
                    Button(action: showPoppyPlus) {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))

                            Text("Get everything with Poppy Plus")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))

                            if let product = poppyPlusProduct {
                                Text("(\(product.displayPrice))")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                        }
                        .foregroundStyle(theme.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(theme.accent.opacity(0.1))
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Cancel button
                Button(action: dismissWithSound) {
                    Text("Maybe Later")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(theme.textDark.opacity(0.5))
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(theme.bgTop)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
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

    private func purchaseBundle() {
        guard let product = bundleProduct else { return }

        isPurchasing = true
        Task {
            do {
                try await store.purchase(product)
                // If purchase succeeded, dismiss
                let isUnlocked = unlockType == .modes ? store.hasModesUnlocked : store.hasThemesUnlocked
                if isUnlocked {
                    onDismiss()
                }
            } catch {
                print("Purchase failed: \(error)")
            }
            isPurchasing = false
        }
    }

    private func showPoppyPlus() {
        SoundManager.shared.play(.pop)
        HapticsManager.shared.light()
        onDismiss()
        // Small delay to let this modal dismiss first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onShowPoppyPlus()
        }
    }
}

// MARK: - Preview

#Preview("Modes Unlock") {
    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        UnlockModal(
            theme: .daylight,
            unlockType: .modes,
            onDismiss: {},
            onShowPoppyPlus: {}
        )
        .environmentObject(StoreManager.preview)
    }
}

#Preview("Themes Unlock") {
    ZStack {
        Color(hex: "#F9F6EC").ignoresSafeArea()

        UnlockModal(
            theme: .daylight,
            unlockType: .themes,
            onDismiss: {},
            onShowPoppyPlus: {}
        )
        .environmentObject(StoreManager.preview)
    }
}
