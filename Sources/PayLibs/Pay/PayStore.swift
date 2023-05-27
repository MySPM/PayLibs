//
// Created by andforce on 2023/4/26.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation
import CommonLibs

class PayStore: NSObject {
    public static let shared = PayStore()

    private override init() {
        super.init()
    }

    public func savePayInfo(_ payInfo: PayInfo) {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: payInfo, requiringSecureCoding: true)
            UserDefaults.standard.set(data, forKey: payInfo.productId)
        } catch {
            print("save PayInfo failed: \(error)")
        }
    }

    public func payInfo(_ productId: String) -> PayInfo? {

        
        do {
            // 检索 PayInfo 对象
            if let data = UserDefaults.standard.object(forKey: productId) as? Data {
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

    public func hasPayed(_ productId: String) -> Bool {
        guard let payInfo = payInfo(productId) else {
            return false
        }
        return Bundle.main.isDebug() || isPayInfoValid(payInfo, productId: productId)
    }

    private func isPayInfoValid(_ payInfo: PayInfo?, productId: String) -> Bool {

        // 网络时间，不能区本地时间，否则用户可以修改本地时间，从而绕过支付
        guard let netDataMs = payInfo?.netDataMs else {
            return false
        }

        return expireDateMs(productId: productId, payInfo: payInfo) >= netDataMs
    }


    public func expireDateMs(productId: String) -> Int64{
        let payInfo = payInfo(productId)
        return expireDateMs(productId: productId, payInfo:payInfo)
    }

    private func expireDateMs(productId: String, payInfo: PayInfo?) -> Int64{
        guard let payInfo = payInfo else {
            return 0
        }

        guard let inApps = payInfo.inApps else {
            return 0
        }

        // 网络时间，不能区本地时间，否则用户可以修改本地时间，从而绕过支付
        guard payInfo.netDataMs != nil else {
            return 0
        }

        let inAppBeans:[InAppBean] = inApps.filter { bean in
            bean.productId == productId
        }
        //.filter { (bean: InAppBean) -> Swift.Bool in bean.productId == productId }

        
        let sortInApps = inAppBeans.sorted { (a, b) -> Bool in
            a.purchaseDateMs > b.purchaseDateMs
        }
        
        let redueceInApps:[InAppBean] = sortInApps

        
        if redueceInApps.isEmpty {
            return 0
        }

        let bean = redueceInApps.first!
        if bean.isAutoSubscription() {
            return bean.expiresDateMs
        } else {
            let firstPurchaseDataMs: Int64 = redueceInApps.last?.purchaseDateMs ?? 0
            // 有效期是一年, 买了几个就延长几年, 毫秒
            let duration: Int64 = Int64(365 * 24 * 60 * 60 * 1000 * redueceInApps.count)
            let expireDateMS: Int64 = firstPurchaseDataMs + duration
            return expireDateMS
        }

    }
}
