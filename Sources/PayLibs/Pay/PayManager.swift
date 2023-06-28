import StoreKit

//typealias PayHandler = (PayInfo) -> Void

@objcMembers public class PayManager: NSObject {
    
    public static let shared = PayManager()
    private let paymentTransactionObserver = PaymentTransactionObserver.shared
    
    private var _productID: String?
    private var _password: String?
    
    private var _handler: (PayInfo) -> Void = {_ in }
    private var _isRestore = false

    private let _payStore = PayStore.shared

    private var _delegateProxy: AppStoreRequestDelegate? = nil

    public func hasPayed(_ productId: String, isSubscription: Bool, checkTime: Bool, checkDayCount: Int) -> Bool {
        return _payStore.hasPayed(productId, isSubscription: isSubscription, checkTime: checkTime, checkDayCount: checkDayCount)
    }
    
//    public func expireDateMs(_ productId: String, isSubscription: Bool) -> Int64 {
//        return _payStore.expireDateMs(productId: productId, isSubscription: isSubscription)
//    }
    
    public func pay(_ productId: String, password: String?, needCheckTime: Bool, with handler: @escaping (PayInfo) -> Void) {

        paymentTransactionObserver.setProductInfo(productId, password, handler)

        _handler = handler
        _productID = productId
        _password = password
        _isRestore = false

        if SKPaymentQueue.canMakePayments() {
            let product = [productId]
            let products = NSSet(array: product)
            let request = SKProductsRequest(productIdentifiers: products as! Set<String>)

            _delegateProxy = AppStoreRequestDelegate(productId: productId, password: _password, isRestore: false, needCheckTime: needCheckTime, _handler)
            request.delegate = self
            request.start()
        } else {
            print("[PayManager]: --> 应用没有开启内购权限")
            DispatchQueue.main.async {
                self._handler(PayInfo.createError())
            }
        }
    }

    public func restore(_ productId: String, password: String?, needCheckTime: Bool, with handler: @escaping (PayInfo) -> Void) {

        _handler = handler
        _productID = productId
        _password = password
        _isRestore = true

        let request = SKReceiptRefreshRequest()
        _delegateProxy = AppStoreRequestDelegate(productId: _productID!, password: _password, isRestore: true, needCheckTime: needCheckTime,  _handler)
        request.delegate = self
        request.start()
        print("[PayManager]: --> On refresh receipt started")
    }


    public func verifyLocal(password: String) {

        print("[PayManager]: --> verifyLocal()")

        ReceiptDataVerifier.shared.verifyLocal(password: password) { (date, dictionary) in
            let isEmpty = dictionary.isEmpty
            if isEmpty {
                print("[PayManager]: --> verifyPay: 获取网络时间失败，没法验证是否购买了")
            }
            
            let info = isEmpty ? PayInfo.createError() : PayInfo.create(response: dictionary)
            self._payStore.savePayInfo(info)
            print("[PayManager]: --> verifyPay: savePayInfo. data is empty: \(isEmpty)")
        }
    }

    private func checkReceiptTimeHave(_ currentTime: Date, receipt: [String : Any]) -> Int {
        TimeChecker.shared.checkReceiptTimeHave(currentTime, receipt: receipt)
    }

    public func addObserver() {
        SKPaymentQueue.default().add(paymentTransactionObserver)
    }

    public func removeObserver() {
        SKPaymentQueue.default().remove(paymentTransactionObserver)
    }

}

extension PayManager: SKProductsRequestDelegate {

    // SKProductsRequestDelegate methods
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        _delegateProxy?.productsRequest(request, didReceive: response)
    }

    // SKProductsRequestDelegate methods
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        _delegateProxy?.requestDidFail(request, didFailWithError: error)
    }

    // SKProductsRequestDelegate methods
    public func requestDidFinish(_ request: SKRequest) {
        _delegateProxy?.requestDidFinish(request)
    }
}
