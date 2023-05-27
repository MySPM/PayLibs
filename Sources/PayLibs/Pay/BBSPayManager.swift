import StoreKit

//typealias PayHandler = (PayInfo) -> Void

@objcMembers public class BBSPayManager: NSObject, SKProductsRequestDelegate {
    
    public static let shared = BBSPayManager()
    
    private var _productID: String?
    private var _handler: (PayInfo) -> Void = {_ in }
    private var _isRestore = false
    private var _transactionObserver: PaymentTransactionObserver?

    private var _delegateProxy: RestoreRequestDelegate? = nil

    public func pay(_ productId: String, with handler: @escaping (PayInfo) -> Void) {
        _transactionObserver = PaymentTransactionObserver(productId, handler)
        SKPaymentQueue.default().add(_transactionObserver!)

        _handler = handler
        _productID = productId
        _isRestore = false

        if SKPaymentQueue.canMakePayments() {
            let product = [productId]
            let products = NSSet(array: product)
            let request = SKProductsRequest(productIdentifiers: products as! Set<String>)

            _delegateProxy = RestoreRequestDelegate(productId, false, _handler)
            request.delegate = self
            request.start()
        } else {
            print("PayManager --> 应用没有开启内购权限")
            DispatchQueue.main.async {
                self._handler(PayInfo.createError(productId, status: -1))
            }
        }
    }

    public func restore(_ productId: String, with handler: @escaping (PayInfo) -> Void) {
        _handler = handler
        _productID = productId
        _isRestore = true

        let request = SKReceiptRefreshRequest()
        _delegateProxy = RestoreRequestDelegate(productId, true, _handler)
        request.delegate = self
        request.start()
        print("PayManager --> On refresh receipt started")
    }


    public func verify(_ productId: String, with handler: @escaping (PayInfo) -> Void) {
        _productID = productId

        print("PayManager --> verifyPay:\tproductId:\(_productID!)")

        ReceiptDataVerifier.shared.verifyLocal { (date, dictionary) in
            if let dictionary = dictionary as? [String: Any], dictionary.count > 0 {
                let info = PayInfo.create(self._productID!, status: 0, netDateMs: Int64(date.timeIntervalSince1970), response: dictionary)
                DispatchQueue.main.async {
                    handler(info)
                }
            } else {
                print("PayManager --> verifyPay: 获取网络时间失败，没法验证是否购买了")
                DispatchQueue.main.async {
                    handler(PayInfo.createError(self._productID!, status: -1))
                }
            }
        }
    }

    private func checkReceiptTimeHave(_ currentTime: Date, receipt: [String : Any]) -> Int {
        TimeChecker.shared.checkReceiptTimeHave(currentTime, receipt: receipt)
    }


    public func removeTransactionObserver() {
        if let observer = _transactionObserver {
            SKPaymentQueue.default().remove(observer)
        }
    }

    // SKProductsRequestDelegate methods
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        _delegateProxy?.productsRequest(request, didReceive: response)
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        _delegateProxy?.request(request, didFailWithError: error)
    }

    public func requestDidFinish(_ request: SKRequest) {
        _delegateProxy?.requestDidFinish(request)
    }
    // SKProductsRequestDelegate methods end
}
