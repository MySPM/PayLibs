//
// Created by andforce on 2023/4/21.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation
import StoreKit

@objcMembers class PaymentTransactionObserver: NSObject, SKPaymentTransactionObserver {

    private var _paymentHandler: (PayInfo) -> Void = {_ in}
    private var _productId: String? = nil
    private var _password: String? = nil

    init(_ productId: String, _ password: String?, _ handler: @escaping (PayInfo) -> Void) {
        super.init()
        _productId = productId
        _paymentHandler = handler
        _password = password
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for tran in transactions {
            switch tran.transactionState {
            case .purchasing:
                print("PayManager --> 商品添加进列表")
                
            case .purchased, .restored:
                print("PayManager --> 交易已经支付，开始验证")
                SKPaymentQueue.default().finishTransaction(tran)
                
                // 异步方法验证
                verify()

            case .failed:
                SKPaymentQueue.default().finishTransaction(tran)
                
                print("PayManager --> 交易失败")
                if let error = tran.error {
                    print("PayManager --> 交易失败 error: \(error.localizedDescription)")
                }
                self._paymentHandler(PayInfo.createError(_productId!, status: -1))
            default:
                break
            }
        }
    }

    private func verify() {
        ReceiptDataVerifier.shared.verifyLocal(password: _password) { [self] (date, response) in
            if let responseChecked = response as? [String:Any],
               responseChecked.count > 0,
               let code = responseChecked["status"] as? Int {
                
                switch code {
                case 0:
                    print("PayManager --> 购买成功!")
                    _paymentHandler(PayInfo.create(_productId!, status: 0, netDateMs: Int64(date.timeIntervalSince1970), response: response))
                case 21002:
                    print("PayManager --> 从未购买过商品")
                    _paymentHandler(PayInfo.createError(_productId!, status: code))
                default:
                    print("PayManager --> 购买失败，未通过验证！")
                    _paymentHandler(PayInfo.createError(_productId!, status: -1))
                }
            } else {
                print("PayManager --> verifyPay: response is nil.")
                _paymentHandler(PayInfo.createError(_productId!, status: -1))
            }
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        print("PayManager --> restore payment finished")

        var purchasedItemIDs = [String]()
        print("PayManager --> received restored transactions: \(queue.transactions.count)")
        for transaction in queue.transactions {
            let productID = transaction.payment.productIdentifier
            purchasedItemIDs.append(productID)
            print("PayManager --> paymentQueueRestoreCompletedTransactionsFinished \(purchasedItemIDs)")
        }
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        for tran in queue.transactions {
            if let error = tran.error {
                print("PayManager --> 交易失败 error: \(error.localizedDescription)")
            }
        }
        _paymentHandler(PayInfo.createError(_productId!, status: -1))
    }
}
