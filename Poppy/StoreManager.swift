//
//  StoreManager.swift
//  Poppy
//
//  Handles In-App Purchases for tips, Poppy Plus, and bundles
//

import Foundation
import StoreKit
import Combine

@MainActor
final class StoreManager: NSObject, ObservableObject {
    // Published state
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs = Set<String>()
    @Published var isPurchasing = false
    @Published var purchaseError: String?
    @Published var showTipSuccess = false
    @Published var tipSuccessMessage = ""
    @Published var showPurchaseSuccess = false
    @Published var purchaseSuccessMessage = ""

    // Product IDs - these must match what you create in App Store Connect
    enum ProductID {
        // Poppy Plus (everything)
        static let poppyPlus = "com.poppy.plus"

        // Bundles
        static let modesBundle = "com.poppy.modes"
        static let themesBundle = "com.poppy.themes"
        static let removeAds = "com.poppy.removeads"

        // Tips (consumables)
        static let smallTip = "com.poppy.tip.small"
        static let mediumTip = "com.poppy.tip.medium"
        static let largeTip = "com.poppy.tip.large"

        // All non-consumable product IDs
        static var unlockProductIDs: [String] {
            [poppyPlus, modesBundle, themesBundle, removeAds]
        }

        // All tip product IDs
        static var tipProductIDs: [String] {
            [smallTip, mediumTip, largeTip]
        }

        static var allProductIDs: [String] {
            unlockProductIDs + tipProductIDs
        }
    }

    private let userDefaultsKey = "poppy.purchased.products"
    private var updateListenerTask: Task<Void, Error>?

    override init() {
        super.init()

        // Don't load products or start listeners in preview mode
        guard !ProcessInfo.processInfo.environment.keys.contains("XCODE_RUNNING_FOR_PREVIEWS") else {
            return
        }

        loadPurchasedProducts()
        updateListenerTask = listenForTransactions()

        // Sync unlock state on launch
        Task {
            await requestProducts()
            await checkForExistingPurchases()
            updateUnlockState()
        }
    }

    // Mock initializer for previews
    init(mock: Bool) {
        super.init()
        // Mock mode - no products loaded
    }

    // Convenience for previews
    static var preview: StoreManager {
        StoreManager(mock: true)
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Product Loading

    func requestProducts() async {
        do {
            print("🛒 Requesting products: \(ProductID.allProductIDs)")
            let storeProducts = try await Product.products(for: ProductID.allProductIDs)
            print("🛒 Loaded \(storeProducts.count) products: \(storeProducts.map { $0.id })")

            // Sort products: Poppy Plus first, then bundles, then tips
            products = storeProducts.sorted { p1, p2 in
                let p1Order = productOrder(p1.id)
                let p2Order = productOrder(p2.id)
                return p1Order < p2Order
            }
        } catch {
            print("❌ Failed to request products: \(error)")
        }
    }

    private func productOrder(_ id: String) -> Int {
        switch id {
        case ProductID.poppyPlus: return 0
        case ProductID.modesBundle: return 1
        case ProductID.themesBundle: return 2
        case ProductID.removeAds: return 3
        case ProductID.smallTip: return 10
        case ProductID.mediumTip: return 11
        case ProductID.largeTip: return 12
        default: return 999
        }
    }

    // MARK: - Check Existing Purchases

    /// Check for existing purchases on app launch
    func checkForExistingPurchases() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Only track non-consumables
                if ProductID.unlockProductIDs.contains(transaction.productID) {
                    purchasedProductIDs.insert(transaction.productID)
                }
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        savePurchasedProducts()
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        isPurchasing = true
        purchaseError = nil

        defer { isPurchasing = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Handle based on product type
            if ProductID.tipProductIDs.contains(product.id) {
                // Consumable tip - just finish
                await transaction.finish()

                let tipSize = product.id.contains("small") ? "small" :
                              product.id.contains("medium") ? "medium" : "large"

                AnalyticsManager.shared.trackTipJarPurchase(
                    tier: tipSize,
                    amount: product.displayPrice
                )

                tipSuccessMessage = "Thank you for the \(tipSize) tip!"
                showTipSuccess = true

                UINotificationFeedbackGenerator().notificationOccurred(.success)

                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    showTipSuccess = false
                }
            } else {
                // Non-consumable unlock - save and finish
                await transaction.finish()
                purchasedProductIDs.insert(product.id)
                savePurchasedProducts()

                // Update UnlockManager based on what was purchased
                updateUnlockState()

                // Show success message
                let productName = displayName(for: product.id)
                purchaseSuccessMessage = "\(productName) unlocked!"
                showPurchaseSuccess = true

                UINotificationFeedbackGenerator().notificationOccurred(.success)
                SoundManager.shared.play(.pop)

                Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    showPurchaseSuccess = false
                }
            }

        case .userCancelled:
            break

        case .pending:
            purchaseError = "Purchase is pending approval"

        @unknown default:
            break
        }
    }

    // MARK: - Unlock State

    /// Check if user has purchased a specific product
    func hasPurchased(_ productID: String) -> Bool {
        purchasedProductIDs.contains(productID)
    }

    /// Check if modes are unlocked (via Poppy Plus or modes bundle)
    var hasModesUnlocked: Bool {
        hasPurchased(ProductID.poppyPlus) || hasPurchased(ProductID.modesBundle)
    }

    /// Check if themes are unlocked (via Poppy Plus or themes bundle)
    var hasThemesUnlocked: Bool {
        hasPurchased(ProductID.poppyPlus) || hasPurchased(ProductID.themesBundle)
    }

    /// Check if ads are removed (via Poppy Plus or remove ads)
    var hasAdsRemoved: Bool {
        hasPurchased(ProductID.poppyPlus) || hasPurchased(ProductID.removeAds)
    }

    /// Check if user has Poppy Plus (everything)
    var hasPoppyPlus: Bool {
        hasPurchased(ProductID.poppyPlus)
    }

    /// Update UnlockManager based on purchases
    func updateUnlockState() {
        // If user has Poppy Plus, unlock everything
        if hasPoppyPlus {
            UnlockManager.shared.unlockEverything()
        } else {
            // Update individual unlock states
            UnlockManager.shared.setModesUnlocked(hasModesUnlocked)
            UnlockManager.shared.setThemesUnlocked(hasThemesUnlocked)
            UnlockManager.shared.setAdsRemoved(hasAdsRemoved)
        }
    }

    /// Get display name for a product
    func displayName(for productID: String) -> String {
        switch productID {
        case ProductID.poppyPlus: return "Poppy Plus"
        case ProductID.modesBundle: return "All Game Modes"
        case ProductID.themesBundle: return "All Themes"
        case ProductID.removeAds: return "Ad-Free"
        default: return "Content"
        }
    }

    // MARK: - Clear Purchases (For Testing)

    func clearPurchases() {
        purchasedProductIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UnlockManager.shared.lock()
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        do {
            try await AppStore.sync()

            // Re-check entitlements after sync
            await checkForExistingPurchases()
            updateUnlockState()

            HapticsManager.shared.medium()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Track non-consumables
                    if Self.ProductID.unlockProductIDs.contains(transaction.productID) {
                        await MainActor.run {
                            self.purchasedProductIDs.insert(transaction.productID)
                            self.savePurchasedProducts()
                            self.updateUnlockState()
                        }
                    }

                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verification

    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Persistence

    private func loadPurchasedProducts() {
        if let ids = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            purchasedProductIDs = Set(ids)
        }
    }

    private func savePurchasedProducts() {
        UserDefaults.standard.set(Array(purchasedProductIDs), forKey: userDefaultsKey)
    }

    // MARK: - Helper Methods

    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }

    /// Get products for unlock purchases (not tips)
    var unlockProducts: [Product] {
        products.filter { ProductID.unlockProductIDs.contains($0.id) }
    }

    /// Get tip products only
    var tipProducts: [Product] {
        products.filter { ProductID.tipProductIDs.contains($0.id) }
    }
}

// MARK: - Error Types

enum StoreError: Error {
    case failedVerification
}
