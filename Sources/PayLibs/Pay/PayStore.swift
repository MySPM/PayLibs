//
// Created by yancai  on 2023/4/26.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation
import CommonLibs

class PayStore: NSObject {
    public static let shared = PayStore()
    private let internetTimeFetcher = InternetTimeFetcher.shared
    
    private let PAY_INFO_KEY = "PayInfo"

    private override init() {
        super.init()
    }

    public func savePayInfo(_ payInfo: PayInfo) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: payInfo, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: PAY_INFO_KEY)
        } catch {
            print("save PayInfo failed: \(error)")
        }
    }

    public func payInfo() -> PayInfo? {

        do {
            // 检索 PayInfo 对象
            if let data = UserDefaults.standard.object(forKey: PAY_INFO_KEY) as? Data {
                if let payInfo = try NSKeyedUnarchiver.unarchivedObject(ofClass: PayInfo.self, from: data) {
                    // 使用 payInfo 对象
                    return payInfo
                }
            }
        } catch {
            print("get PayInfo failed: \(error)")
        }
        return nil
    }

    public func hasPayed(_ productId: String, isSubscription: Bool, checkTime: Bool, checkDayCount: Int) -> Bool {
        guard let payInfo = payInfo() else {
            return false
        }
        return Bundle.main.isDebug() || isPayInfoValid(payInfo, productId: productId, isSubscription: isSubscription, checkTime: checkTime, checkDayCount: checkDayCount)
    }

    private func isPayInfoValid(_ payInfo: PayInfo?, productId: String, isSubscription: Bool, checkTime: Bool, checkDayCount: Int) -> Bool {

        guard let payInfo else {
            return false
        }

        if checkTime {
            // 网络时间，不能区本地时间，否则用户可以修改本地时间，从而绕过支付
            guard let netDataMs = internetTimeFetcher.getInternetDate()?.timeIntervalSince1970 else {
                return false
            }

            let netInt64 = Int64(netDataMs)
            return expireDateMs(productId: productId, checkDayCount: checkDayCount, payInfo: payInfo, isSubscription: isSubscription) >= netInt64
        } else {
            let inAppBean = payInfo.inApps?.filter { (bean: InAppBean) -> Swift.Bool in bean.productId == productId }

            if inAppBean == nil || inAppBean?.count == 0{
                return false
            }

            let inApp = inAppBean![0]
            return inApp.isPurchase() && !inApp.isCanceled()
        }

    }

    private func expireDateMs(productId: String, checkDayCount:Int, payInfo: PayInfo?, isSubscription: Bool) -> Int64{
        guard let payInfo = payInfo else {
            return 0
        }

        guard let inApps = isSubscription ? payInfo.latestReceiptInfo : payInfo.inApps else {
            return 0
        }

        // 网络时间，不能区本地时间，否则用户可以修改本地时间，从而绕过支付
        if internetTimeFetcher.getInternetDate() == nil {
            return 0
        }


        let inAppBeans:[InAppBean] = inApps.filter { bean in
            bean.productId == productId
        }
        //.filter { (bean: InAppBean) -> Swift.Bool in bean.productId == productId }

        
        let sortInApps = inAppBeans.sorted { (a, b) -> Bool in
            a.purchaseDateMs > b.purchaseDateMs
        }
        
        let reduceInApps:[InAppBean] = sortInApps.filter { (bean: InAppBean) -> Swift.Bool in
            !bean.isCanceled() && bean.isPurchase()
        }


        if reduceInApps.isEmpty {
            return 0
        }

        let bean = reduceInApps.first!
        if bean.isAutoSubscription() {
            return bean.expiresDateMs
        } else {
            let firstPurchaseDataMs: Int64 = reduceInApps.last?.purchaseDateMs ?? 0
            // 有效期是一年, 买了几个就延长几年, 毫秒
            let duration: Int64 = Int64(checkDayCount * 24 * 60 * 60 * 1000 * reduceInApps.count)
            let expireDateMS: Int64 = firstPurchaseDataMs + duration
            return expireDateMS
        }

    }
}
