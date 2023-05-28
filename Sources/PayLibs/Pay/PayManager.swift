import StoreKit

//typealias PayHandler = (PayInfo) -> Void

@objcMembers public class PayManager: NSObject, SKProductsRequestDelegate {
    
    public static let shared = PayManager()
    private let _transactionObserver = PaymentTransactionObserver.shared
    
    private var _productID: String?
    private var _password: String?
    
    private var _handler: (PayInfo) -> Void = {_ in }
    private var _isRestore = false

    private let _payStore = PayStore.shared

    private var _delegateProxy: AppStoreRequestDelegate? = nil

    public func hasPayed(_ productId: String) -> Bool {
        return _payStore.hasPayed(productId)
    }
    
    public func expireDateMs(_ productId: String) -> Int64 {
        return _payStore.expireDateMs(productId: productId)
    }
    
    public func pay(_ productId: String, password: String?, with handler: @escaping (PayInfo) -> Void) {
        _transactionObserver.setProductInfo(productId, password, handler)

        _handler = handler
        _productID = productId
        _password = password
        _isRestore = false

        if SKPaymentQueue.canMakePayments() {
            let product = [productId]
            let products = NSSet(array: product)
            let request = SKProductsRequest(productIdentifiers: products as! Set<String>)

            _delegateProxy = AppStoreRequestDelegate(productId, _password, false, _handler)
            request.delegate = self
            request.start()
        } else {
            print("PayManager --> 应用没有开启内购权限")
            DispatchQueue.main.async {
                self._handler(PayInfo.createError(productId, status: -1))
            }
        }
    }

    public func restore(_ productId: String, password: String?, with handler: @escaping (PayInfo) -> Void) {
        _handler = handler
        _productID = productId
        _password = password
        _isRestore = true

        let request = SKReceiptRefreshRequest()
        _delegateProxy = AppStoreRequestDelegate(_productID!, _password, true, _handler)
        request.delegate = self
        request.start()
        print("PayManager --> On refresh receipt started")
    }


    public func verifyLocal(_ productId: String, password: String, with handler: @escaping (PayInfo) -> Void) {
        _productID = productId
        _password = password

        print("PayManager --> verifyPay:\tproductId:\(String(describing: _productID))")

        ReceiptDataVerifier.shared.verifyLocal(password: password) { (date, dictionary) in
            DispatchQueue.main.async {
                if dictionary.isEmpty {
                    print("PayManager --> verifyPay: 获取网络时间失败，没法验证是否购买了")
                    handler(PayInfo.createError(self._productID!, status: -1))
                } else {
                    let info = PayInfo.create(self._productID!, status: 0, netDateMs: Int64(date.timeIntervalSince1970), response: dictionary)
                    self._payStore.savePayInfo(info)
                    handler(info)
                }
            }
        }
    }

    private func checkReceiptTimeHave(_ currentTime: Date, receipt: [String : Any]) -> Int {
        TimeChecker.shared.checkReceiptTimeHave(currentTime, receipt: receipt)
    }

    public func addObserver() {
        SKPaymentQueue.default().add(_transactionObserver)
    }

    public func removeObserver() {
        SKPaymentQueue.default().remove(_transactionObserver)
    }

    // SKProductsRequestDelegate methods
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        _delegateProxy?.productsRequest(request, didReceive: response)
    }

    public func request(_ request: SKRequest, didFailWithError error: Error) {
        _delegateProxy?.requestDidFail(request, didFailWithError: error)
    }

    public func requestDidFinish(_ request: SKRequest) {
        _delegateProxy?.requestDidFinish(request)
    }
    // SKProductsRequestDelegate methods end
}
