//
//  File.swift
//  PayLibs
//
//  Created by Dy Wang on 2025/5/20.
//

import Foundation

import MyLoggerOC
import StoreKit
import CommonLibs

@available(iOS 15.0, *)
@objcMembers public class PayManager2: NSObject {
    public static let shared = PayManager2()
    
    private let internetTimeFetcher = InternetTimeFetcher.shared
    
    private var products:[Product]? = []
    
    var activeTransactions: Set<Transaction> = []
    
    /// 通过 productIds 请求 Product 列表
    /// - Parameter productIds: product ids
    /// - Returns: Product 列表
    public func requestProducts(productIds: [String]) async -> [Product]? {
        products = try? await Product.products(for: Set.init(productIds))
        return products
    }
    
//    消耗型 (Consumable)                              ✅ 可以        游戏币、体力、提示道具等
//    非消耗型 (Non-Consumable)                         ❌ 不能        解锁关卡、去广告、永久道具等
//    自动续期订阅 (Auto-Renewable Subscription)         ✅ 自动续期    视频会员、云存储空间等
//    非续期订阅 (Non-Renewing Subscription)             ✅ 手动续期    限时服务如季票、临时功能订阅等

//    public func hasPayed(_ productId: String, isSubscription: Bool, checkTime: Bool, checkDayCount: Int) -> Bool {
//        //return _payStore.hasPayed(productId, isSubscription: isSubscription, checkTime: checkTime, checkDayCount: checkDayCount)
//        let filterTrans = self.activeTransactions.filter { t in
//            t.productID == productId
//        }
//        
//        if filterTrans.isEmpty {
//            return false
//        } else {
//            
//            if checkTime {
//                // 消耗型商品，比如 论坛 的 VIP 时间
//                let trans = filterTrans.first
//                if trans?.productType == .autoRenewable {
//                    // 自动续期的订阅
//                    let currentTime = internetTimeFetcher.getInternetDate()?.timeIntervalSince1970 ?? 0
//                    let expirtime = trans?.expirationDate?.timeIntervalSince1970 ?? -1
//                    if expirtime >= currentTime {
//                        return true
//                    } else {
//                        return false
//                    }
//                } else {
//                    return false
//                }
//                
//            } else {
//                // 非消耗型商品，比如 AI酱 的皮肤，适用于一次购买，永远使用
//                return filterTrans.count > 0
//            }
//        }
//    }
    
    public func hasPayed(_ productId: String) -> Bool {
        for result in activeTransactions {
            let transaction = result
            
            guard transaction.productID == productId else { continue }
            
            // ✅ 检查是否退款
            if transaction.revocationDate != nil {
                continue
            }
            
            // ✅ 检查订阅是否在有效期内（针对订阅类型）
            if let expiryDate = transaction.expirationDate {
                let currentTime = (internetTimeFetcher.getInternetDate() ?? Date())
                if expiryDate > currentTime {
                    return true
                } else {
                    continue
                }
            }
            
            
            // ✅ 非订阅，且未退款
            return true
        }
        
        return false
    }
    
    
    //                            {
    //                              "appTransactionId" : "704506429246648850",
    //                              "bundleId" : "com.andforce.forums",
    //                              "currency" : "CNY",
    //                              "deviceVerification" : "oXKqgbW38uMg73\/fBgauhLeWIWcZ89xW+skdkOGhnm2uD7aD9YMj\/y9QMm\/njXUJ",
    //                              "deviceVerificationNonce" : "d095ea86-4a50-4748-96f6-5f710fd91a5c",
    //                              "environment" : "Sandbox",
    //                              "expiresDate" : 1747722799000,
    //                              "inAppOwnershipType" : "PURCHASED",
    //                              "originalPurchaseDate" : 1747719199000,
    //                              "originalTransactionId" : "2000000922462310",
    //                              "price" : 12000,
    //                              "productId" : "forum_post_1_year",
    //                              "purchaseDate" : 1747719199000,
    //                              "quantity" : 1,
    //                              "signedDate" : 1747719198963,
    //                              "storefront" : "CHN",
    //                              "storefrontId" : "143465",
    //                              "subscriptionGroupIdentifier" : "21345454",
    //                              "transactionId" : "2000000922462310",
    //                              "transactionReason" : "PURCHASE",
    //                              "type" : "Auto-Renewable Subscription",
    //                              "webOrderLineItemId" : "2000000099948733"
    //                            }
                                
                                
    //                            {
    //                              "appTransactionId" : "704506429246648850",
    //                              "bundleId" : "com.andforce.forums",
    //                              "currency" : "CNY",
    //                              "deviceVerification" : "2Ald4MXU2W4Sj2iN1oXueZ+k1KO7auBP9yWHmZ9wV559B90nOeRUgjLHA2vd8bw+",
    //                              "deviceVerificationNonce" : "35c97df8-c173-4bae-8669-e992e8563d45",
    //                              "environment" : "Sandbox",
    //                              "inAppOwnershipType" : "PURCHASED",
    //                              "originalPurchaseDate" : 1747731789943,
    //                              "originalTransactionId" : "2000000922667200",
    //                              "price" : 12000,
    //                              "productId" : "com.andforce.fourms.001",
    //                              "purchaseDate" : 1747731789943,
    //                              "quantity" : 1,
    //                              "signedDate" : 1747731789260,
    //                              "storefront" : "CHN",
    //                              "storefrontId" : "143465",
    //                              "transactionId" : "2000000922667200",
    //                              "transactionReason" : "PURCHASE",
    //                              "type" : "Non-Renewing Subscription"
    //                            }
    public func pay(_ productId: String, with handler: @escaping (Bool) -> Void) {
        Task {
            let products = await requestProducts(productIds: [productId])
            if products != nil && !(products!.isEmpty) {
                let needPurchase = products?.first
                
                do {
                    let result = try await needPurchase?.purchase()
                    await MainActor.run {
                        switch result {
                        case .success(let verificationReuslt):
                            switch verificationReuslt {
                            case .unverified(let signedType, let error):
                                print("PayManager2 --->> 未验证购买：\(signedType), \(error)")
                                handler(false)
                            case .verified(let trans):
                                print("PayManager2 --->> 购买成功:\(trans)")
                                handler(true)
                            }
                        case .userCancelled:
                            print("PayManager2 --->> 用户取消")
                            handler(false)
                        case .pending:
                            print("PayManager2 --->> 购买挂起，正在处理")
                            handler(false)
                        case .none:
                            print("PayManager2 --->> none")
                            handler(false)
                        case .some(_):
                            print("PayManager2 --->> some")
                            handler(false)
                        }
                    }
                    
                } catch {
                    await MainActor.run {
                        print("PayManager2 --->> 购买失败 \(error)")
                        handler(false)
                    }
                }
            }
        }
    }
    
    public func restore(_ productId: String, with handler: @escaping (Bool) -> Void) {
        Task {
            try? await AppStore.sync()

            // 等待 5 秒
            try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)

            let result = hasPayed(productId)

            // 保证 handler 在主线程调用（尤其如果 UI 会使用它）
            await MainActor.run {
                handler(result)
            }
        }
    }
    
    
    public func addObserver() {
        listenForTransaction { trans in
            print("PayManager2 --->> 监听到订单更新了：\(trans.productID)")
        }
    }
    
    /// 支付监听事件
    private func listenForTransaction(completion:@escaping (Transaction) -> Void) -> Void {
        Task.detached {
            for await verificationResult in Transaction.updates {
                let checkResult = self.checkTransactionVerificationResult(verificationResult)
                
                if checkResult.verified {
                    let validatedTransaction = checkResult.transaction
                    await validatedTransaction.finish()
                    //有未完成的订单，需要重新发送给服务端验证，是否下发权益
                    completion(validatedTransaction)
                } else {
                    print("Transaction failed verification.")
                }
            }
        }
    }
    
    /// 校验
    /// - Parameter result: 支付返回结果
    /// - Returns: 是否验证成功
    private func checkTransactionVerificationResult(_ result: VerificationResult<Transaction>) -> (transaction: Transaction, verified: Bool) {
        //Check whether the JWS parses StoreKit verification.
        switch result {
        case .unverified(let transaction, _):
            //StoreKit parses the JWS， but it fails verification.
            return (transaction: transaction, verified: false)
        case .verified(let transaction):
            //The reult is verified. Return the unwrapped value.
            return (transaction: transaction, verified: true)
        }
    }
    

    public func fetchActiveTransactions() async {
        var activeTransactions: Set<Transaction> = []
        
        for await entitlement in Transaction.currentEntitlements {
            
            print("PayManager2 --->> fetchActiveTransactions_all: \(entitlement)")
            
            switch entitlement {
            case .verified(let trans):
                if let transaction = try? entitlement.payloadValue {
                    print("PayManager2 --->> fetchActiveTransactions: \(transaction)")
                    activeTransactions.insert(transaction)
                }
            default:
                continue  // 跳过未验证的（可能被篡改或非法）
            }

        }
        
        self.activeTransactions = activeTransactions
    }


}
