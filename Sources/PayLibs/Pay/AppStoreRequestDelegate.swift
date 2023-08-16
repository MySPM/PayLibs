//
// Created by andforce on 2023/4/21.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation
import StoreKit

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
        print("--->> Pay: error: \(error)")
        DispatchQueue.main.async {
            self._paymentHandler(PayInfo.createError())
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        if products.count == 0 {
            return
        }

        print("PayManager --> invalidProductIdentifiers:\(response.invalidProductIdentifiers)")
        print("PayManager --> 产品付费数量:\(products.count)")

        var payProduct: SKProduct?
        for product in products {
            print("PayManager --> \(product.description)")
            print("PayManager --> \(product.price)")
            print("PayManager --> \(product.productIdentifier)")

            let numberFormatter = NumberFormatter()
            numberFormatter.formatterBehavior = .behavior10_4
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = product.priceLocale
            let formattedPrice = numberFormatter.string(from: product.price)
            print("PayManager --> 内购本地化货币:\(formattedPrice!)")
            
            if product.productIdentifier == _productId {
                payProduct = product
                break
            }
        }

        let payment = SKPayment(product: payProduct!)

        if _isRestore {
            print("PayManager --> 发送恢复购买请求")
            SKPaymentQueue.default().restoreCompletedTransactions()
        } else {
            print("PayManager --> 发送购买请求")
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

            print("PayManager --> requestDidFinish: 获取交易信息成功, 开始验证交易信息")
            ReceiptDataVerifier.shared.verifyAfterInternetTime(receipt: data) { [self] date, response in
                let timeHave = TimeChecker.shared.checkReceiptTimeHave(date, receipt: response)
                let resultPayInfo = PayInfo.create(response: response)
                // 保存数据
                _payStore.savePayInfo(resultPayInfo)

                DispatchQueue.main.async {
                    if response.count > 0 {
                        print("PayManager --> requestDidFinish: 获取交易信息成功")
                        
                        if self._needCheckTime {
                            self._paymentHandler((timeHave > 0) ? resultPayInfo :PayInfo.createError())
                        } else {
                            self._paymentHandler(resultPayInfo)
                        }

                    } else {
                        print("PayManager --> requestDidFinish: 获取网络时间失败，没法验证是否购买了")
                        self._paymentHandler(PayInfo.createError())
                    }
                }
            }
        } else {
            print("PayManager --> requestDidFinish: 不是SKReceiptRefreshRequest")
        }
    }
}
