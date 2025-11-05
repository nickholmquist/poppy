//
//  StoreManager.swift
//  Poppy
//
//  Handles In-App Purchases for tips
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
        
        static var allProductIDs: [String] {
            [smallTip, mediumTip, largeTip]
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
            let storeProducts = try await Product.products(for: ProductID.allProductIDs)
            
            // Sort tips by size
            products = storeProducts.sorted { p1, p2 in
                let p1Order = productOrder(p1.id)
                let p2Order = productOrder(p2.id)
                return p1Order < p2Order
            }
        } catch {
            print("Failed to request products: \(error)")
        }
    }
    
    private func productOrder(_ id: String) -> Int {
        switch id {
        case ProductID.smallTip: return 0
        case ProductID.mediumTip: return 1
        case ProductID.largeTip: return 2
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
            
            // For consumables (tips), show thank you and finish
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
            
        case .userCancelled:
            break
            
        case .pending:
            purchaseError = "Purchase is pending approval"
            
        @unknown default:
            break
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
                    
                    // For tips, just finish the transaction
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
}

// MARK: - Error Types

enum StoreError: Error {
    case failedVerification
}
