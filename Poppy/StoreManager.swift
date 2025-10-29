//
//  StoreManager.swift
//  Poppy
//
//  Handles In-App Purchases for tips and theme unlocks
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
    
    // Product IDs - these must match what you create in App Store Connect
    enum ProductID {
        // Tips
        static let smallTip = "com.poppy.tip.small"
        static let mediumTip = "com.poppy.tip.medium"
        static let largeTip = "com.poppy.tip.large"
        
        // Theme unlocks
        static let citrusTheme = "com.poppy.theme.citrus"
        static let beachglassTheme = "com.poppy.theme.beachglass"
        static let memphisTheme = "com.poppy.theme.memphis"
        static let minimalLightTheme = "com.poppy.theme.minimallight"
        static let minimalDarkTheme = "com.poppy.theme.minimaldark"
        static let allThemes = "com.poppy.themes.all"
        
        static var allProductIDs: [String] {
            [smallTip, mediumTip, largeTip, citrusTheme, beachglassTheme,
             memphisTheme, minimalLightTheme, minimalDarkTheme, allThemes]
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
        
        Task {
            await requestProducts()
        }
    }
    
    // Mock initializer for previews
    init(mock: Bool) {
        super.init()
        if mock {
            // Simulate having some themes unlocked for preview
            purchasedProductIDs = [ProductID.citrusTheme]
        }
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
            let storeProducts = try await Product.products(for: ProductID.allProductIDs)
            
            // Sort: tips first, then themes, then bundle
            products = storeProducts.sorted { p1, p2 in
                let p1Order = productOrder(p1.id)
                let p2Order = productOrder(p2.id)
                return p1Order < p2Order
            }
        } catch {
        }
    }
    
    private func productOrder(_ id: String) -> Int {
        switch id {
        case ProductID.smallTip: return 0
        case ProductID.mediumTip: return 1
        case ProductID.largeTip: return 2
        case ProductID.citrusTheme: return 3
        case ProductID.beachglassTheme: return 4
        case ProductID.memphisTheme: return 5
        case ProductID.minimalLightTheme: return 6
        case ProductID.minimalDarkTheme: return 7
        case ProductID.allThemes: return 8
        default: return 999
        }
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
            
            // For consumables (tips), just finish the transaction
               if product.id.contains("tip") {
                   await transaction.finish()
                   
                   // Show thank you message
                   let tipSize = product.id.contains("small") ? "small" :
                                 product.id.contains("medium") ? "medium" : "large"
                   tipSuccessMessage = "Thank you for the \(tipSize) tip! ❤️"
                   showTipSuccess = true
                   
                   // Success haptic
                   UINotificationFeedbackGenerator().notificationOccurred(.success)
                   
                   // Auto-dismiss after 2.5 seconds
                   Task {
                       try? await Task.sleep(nanoseconds: 2_500_000_000)
                       showTipSuccess = false
                   }
                   
                   return
               }
            
            // For non-consumables (themes), save and finish
            purchasedProductIDs.insert(transaction.productID)
            savePurchasedProducts()
            await transaction.finish()
            
        case .userCancelled:
            break
            
        case .pending:
            purchaseError = "Purchase is pending approval"
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        isPurchasing = true
        purchaseError = nil
        
        defer { isPurchasing = false }
        
        do {
            try await AppStore.sync()
            
            // Reload current entitlements
            var restoredIDs = Set<String>()
            
            for await result in Transaction.currentEntitlements {
                let transaction = try checkVerified(result)
                restoredIDs.insert(transaction.productID)
            }
            
            purchasedProductIDs = restoredIDs
            savePurchasedProducts()
            
        } catch {
            purchaseError = "Failed to restore purchases"
        }
    }
    
    // MARK: - Clear Purchases (For Testing)
    
    func clearPurchases() {
        purchasedProductIDs.removeAll()
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Transaction Listener
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    await MainActor.run {
                        if !transaction.productID.contains("tip") {
                            self.purchasedProductIDs.insert(transaction.productID)
                            self.savePurchasedProducts()
                        }
                    }
                    
                    await transaction.finish()
                } catch {
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
    
    func isThemeUnlocked(_ themeName: String) -> Bool {
        // All themes unlocked for initial release
        return true
    }
    
    private func themeToProductID(_ themeName: String) -> String {
        switch themeName {
        case "Citrus": return ProductID.citrusTheme
        case "Beachglass": return ProductID.beachglassTheme
        case "Memphis": return ProductID.memphisTheme
        case "Minimal Light": return ProductID.minimalLightTheme
        case "Minimal Dark": return ProductID.minimalDarkTheme
        default: return ""
        }
    }
    
    func product(for id: String) -> Product? {
        products.first { $0.id == id }
    }
}

// MARK: - Error Types

enum StoreError: Error {
    case failedVerification
}
