//
// Created by yancai  on 2023/4/21.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation
import StoreKit

@objcMembers class PaymentTransactionObserver: NSObject {

    static let shared = PaymentTransactionObserver()

    private var _paymentHandler: (PayInfo) -> Void = {_ in}
    private var _productId: String? = nil
    private var _password: String? = nil

    private override init() {
        super.init()
    }

    func setProductInfo(_ productId: String, _ password: String?, _ handler: @escaping (PayInfo) -> Void) {
        _productId = productId
        _password = password
        _paymentHandler = handler
    }

    private func verifyLocal() {
        ReceiptDataVerifier.shared.verifyLocal(password: _password) { [self] (date, response) in

            if !response.isEmpty, let code = response["status"] as? Int {

                switch code {
                case 0:
                    print("[PayManager]: --> 购买成功!")
                    let payInfo = PayInfo.create(response: response)
                    PayStore.shared.savePayInfo(payInfo)
                    _paymentHandler(payInfo)
                case 21002:
                    print("[PayManager]: --> 从未购买过商品")
                    _paymentHandler(PayInfo.createError())
                default:
                    print("[PayManager]: --> 购买失败，未通过验证！")
                    _paymentHandler(PayInfo.createError())
                }
            } else {
                print("[PayManager]: --> verifyPay: response is nil.")
                _paymentHandler(PayInfo.createError())
            }
        }
    }

}

extension PaymentTransactionObserver: SKPaymentTransactionObserver {

    /**
     https://xiaovv.me/2018/05/03/My-iOS-In-App-Purchase-Summarize/

     前面提到iOS 11 之后，开发者可以在 App Store 自己App的下载页面推广自己的内购商品，用户可以直接在App下载页面购买内购商品，
     这就涉及到从App Store跳转到自己App，所以苹果在 SKPaymentTransactionObserver 新增了一个代理方法：

     func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment,
     for product: SKProduct) -> Bool {

         return false
     }

     用户在 App下载页面点击购买你推广的内购商品，如果用户已经安装过你的 App 则会直接跳转你的App并调用上述代理方法；
     如果用户还没有安装你的 App 那么就会去下载你的 App，下载完成之后系统会推送一个通知，如果用户点击该通知就会跳转到你的App并且调用上面的代理方法

     上面的代理方法返回 true 则表示跳转到你的 App，IAP 继续完成交易，如果返回 false 则表示推迟或者取消购买，实际开发中因为可能还需要用户登录自己的账号、生成订单等，一般都是返回 false，之后自己手动把代理方法里面返回的 SKPayment 加入支付队列，然后在按照自己的支付、验证逻辑完成支付
     */
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        print("[PayManager]: [PaymentTransactionObserver]: --> paymentQueue-shouldAddStorePayment")
        return true
    }

    public func paymentQueue(_ queue: SKPaymentQueue, didRevokeEntitlementsForProductIdentifiers productIdentifiers: [String]) {
        print("[PayManager]: [PaymentTransactionObserver]: --> paymentQueue-didRevokeEntitlementsForProductIdentifiers")
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        print("[PayManager]: [PaymentTransactionObserver]: --> paymentQueue-updatedTransactions")

        for tran in transactions {
            switch tran.transactionState {
            case .purchasing:
                print("[PayManager]: --> 商品添加进列表")
            case .purchased:
                SKPaymentQueue.default().finishTransaction(tran)

                if (tran.original != nil) {
                    // 说明是自动续期
                    print("[PayManager]: --> 自动续期，或者重复购买，开始验证")
                } else {
                    // 首次购买
                    print("[PayManager]: --> 首次交易已经支付，开始验证")
                }
                // 异步方法验证
                verifyLocal()
            case .restored:
                print("[PayManager]: --> 恢复操作完成，开始验证")
                SKPaymentQueue.default().finishTransaction(tran)

                // 异步方法验证
                verifyLocal()

            case .failed:
                SKPaymentQueue.default().finishTransaction(tran)

                print("[PayManager]: --> 交易失败")
                if let error = tran.error {
                    print("[PayManager]: --> 交易失败 error: \(error.localizedDescription)")
                }
                self._paymentHandler(PayInfo.createError())
            default:
                break
            }
        }
    }

    public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        print("[PayManager]: [PaymentTransactionObserver]: --> paymentQueue-removedTransactions")
    }

//    public func paymentQueue(_ queue: SKPaymentQueue, updatedDownloads downloads: [SKDownload]) {
//        print("[PayManager]: [PaymentTransactionObserver]: --> paymentQueue-updatedDownloads")
//    }

    public func paymentQueueDidChangeStorefront(_ queue: SKPaymentQueue) {
        print("[PayManager]: [PaymentTransactionObserver]: --> paymentQueue-didChangeStorefront")
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        print("[PayManager]: [PaymentTransactionObserver]: --> paymentQueue-restoreCompletedTransactionsFailedWithError")

        for tran in queue.transactions {
            if let error = tran.error {
                print("[PayManager]: --> 交易失败 error: \(error.localizedDescription)")
            }
        }
        _paymentHandler(PayInfo.createError())
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        var purchasedItemIDs = [String]()
        print("[PayManager]: --> paymentQueueRestoreCompletedTransactionsFinished: \(queue.transactions.count)")
        for transaction in queue.transactions {
            let productID = transaction.payment.productIdentifier
            purchasedItemIDs.append(productID)
            print("[PayManager]: --> paymentQueueRestoreCompletedTransactionsFinished \(purchasedItemIDs)")
        }
    }

}
