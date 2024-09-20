//
// Created by yancai  on 2023/4/21.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation
import StoreKit
import MyLoggerOC

class AppStoreRequestDelegate {

    private var _paymentHandler: (PayInfo) -> Void = {_ in}
    private var _productId: String
    private var _password: String?
    private var _isRestore: Bool
    private var _needCheckTime : Bool
    private let _payStore = PayStore.shared

    init(productId: String, password: String?, isRestore: Bool, needCheckTime: Bool, _ handler: @escaping (PayInfo) -> Void) {
        _productId = productId
        _password = password
        _isRestore = isRestore
        _paymentHandler = handler
        _needCheckTime = needCheckTime
    }

    func requestDidFail(_ request: SKRequest, didFailWithError error: Error) {
        MyLogger.print("--->> Pay: error: \(error)")
        DispatchQueue.main.async {
            self._paymentHandler(PayInfo.createError())
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        if products.count == 0 {
            return
        }

        MyLogger.print("PayManager --> invalidProductIdentifiers:\(response.invalidProductIdentifiers)")
        MyLogger.print("PayManager --> 产品付费数量:\(products.count)")

        var payProduct: SKProduct?
        for product in products {
            MyLogger.print("PayManager --> \(product.description)")
            MyLogger.print("PayManager --> \(product.price)")
            MyLogger.print("PayManager --> \(product.productIdentifier)")

            let numberFormatter = NumberFormatter()
            numberFormatter.formatterBehavior = .behavior10_4
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = product.priceLocale
            let formattedPrice = numberFormatter.string(from: product.price)
            MyLogger.print("PayManager --> 内购本地化货币:\(formattedPrice!)")
            
            if product.productIdentifier == _productId {
                payProduct = product
                break
            }
        }

        let payment = SKPayment(product: payProduct!)

        if _isRestore {
            MyLogger.print("PayManager --> 发送恢复购买请求")
            SKPaymentQueue.default().restoreCompletedTransactions()
        } else {
            MyLogger.print("PayManager --> 发送购买请求")
            SKPaymentQueue.default().add(payment)
        }
    }

    func requestDidFinish(_ request: SKRequest) {
        NSLog("PayManager --> On refresh receipt finished")
        if request is SKReceiptRefreshRequest {
            let receiptUrl = Bundle.main.appStoreReceiptURL
            let receiptData = try? Data(contentsOf: receiptUrl!)
            let receiptBase64Str = receiptData?.base64EncodedString(options: [])

            var receiptDataStr = """
                                    {
                                        "receipt-data" : "\(receiptBase64Str!)"
                                    }
                                    """
            if _password != nil && !_password!.isEmpty {
                receiptDataStr = """
                                    {
                                        "receipt-data" : "\(receiptBase64Str!)",
                                        "password":"\(_password!)"
                                    }
                                    """
            }

            let data = receiptDataStr.data(using: .utf8)

            guard let data else {
                DispatchQueue.main.async {
                    self._paymentHandler(PayInfo.createError())
                }
                return
            }

            MyLogger.print("PayManager --> requestDidFinish: 获取交易信息成功, 开始验证交易信息")
            ReceiptDataVerifier.shared.verifyAfterInternetTime(receipt: data) { [self] date, response in
                let timeHave = TimeChecker.shared.checkReceiptTimeHave(date, receipt: response)
                let resultPayInfo = PayInfo.create(response: response)
                // 保存数据
                _payStore.savePayInfo(resultPayInfo)

                DispatchQueue.main.async {
                    if response.count > 0 {
                        MyLogger.print("PayManager --> requestDidFinish: 获取交易信息成功, 是否需要检查剩余时间：\(self._needCheckTime)")
                        
                        if self._needCheckTime {
                            MyLogger.print("PayManager --> requestDidFinish: 产品订阅剩余时间：\(timeHave) 秒")
                            self._paymentHandler((timeHave > 0) ? resultPayInfo :PayInfo.createError())
                        } else {
                            self._paymentHandler(resultPayInfo)
                        }

                    } else {
                        MyLogger.print("PayManager --> requestDidFinish: 获取网络时间失败，没法验证是否购买了")
                        self._paymentHandler(PayInfo.createError())
                    }
                }
            }
        } else {
            MyLogger.print("PayManager --> requestDidFinish: 不是SKReceiptRefreshRequest")
        }
    }
}
