//
// Created by andforce on 2023/4/21.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation
import StoreKit

class RestoreRequestDelegate {

    private var _paymentHandler: (PayInfo) -> Void = {_ in}
    private var _productId: String
    private var _isRestore: Bool
    
    private let _payStore = PayStore.shared

    init(_ productId: String, _ isRestore: Bool, _ handler: @escaping (PayInfo) -> Void) {
        _productId = productId
        _isRestore = isRestore
        _paymentHandler = handler
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("--->> Pay: error: \(error)")
        DispatchQueue.main.async {
            self._paymentHandler(PayInfo.createError(self._productId, status: -1))
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        if products.count == 0 {
            return
        }

        print("PayManager --> productID:\(response.invalidProductIdentifiers)")
        print("PayManager --> 产品付费数量:\(products.count)")

        var p: SKProduct?
        for pro in products {
            print("PayManager --> \(pro.description)")
            print("PayManager --> \(pro.price)")
            print("PayManager --> \(pro.productIdentifier)")

            if pro.productIdentifier == _productId {
                p = pro
                break
            }
        }

        let payment = SKPayment(product: p!)

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

            let receiptDataStr = "{\"receipt-data\" : \"\(receiptBase64Str!)\"}"
            let data = receiptDataStr.data(using: .utf8)

            guard let data else {
                DispatchQueue.main.async {
                    self._paymentHandler(PayInfo.createError(self._productId, status: -1))
                }
                return
            }

            print("PayManager --> requestDidFinish: 获取交易信息成功, 开始验证交易信息")
            ReceiptDataVerifier.shared.verify(receipt: data) { [self] date, response in
                let timeHave = TimeChecker.shared.checkReceiptTimeHave(date, receipt: response)
                var payInfoSuccess: PayInfo?
                if timeHave > 0 {
                    payInfoSuccess  = PayInfo.create(self._productId, status: 0, netDateMs: Int64(date.timeIntervalSince1970), response: response)
                    // 保存数据
                    _payStore.savePayInfo(payInfoSuccess!)
                }
                DispatchQueue.main.async {
                    if response.count > 0 {
                        print("PayManager --> requestDidFinish: 获取交易信息成功")
                        if timeHave > 0 {
                            if (payInfoSuccess == nil) {
                                self._paymentHandler(PayInfo.createError(self._productId, status: -1))
                            } else {
                                self._paymentHandler(payInfoSuccess!)
                            }
                        } else {
                            self._paymentHandler(PayInfo.createError(self._productId, status: -1))
                        }
                    } else {
                        print("PayManager --> requestDidFinish: 获取网络时间失败，没法验证是否购买了")
                        self._paymentHandler(PayInfo.createError(self._productId, status: -1))
                    }
                }
            }
        } else {
            print("PayManager --> requestDidFinish: 不是SKReceiptRefreshRequest")
        }
    }
}
