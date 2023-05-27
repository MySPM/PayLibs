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

        guard let data = UserDefaults.standard.data(forKey: productId) else {
            return nil
        }
        
        do {
            let payInfo = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? PayInfo
            return payInfo
        } catch {
            print("get PayInfo failed: \(error)")
        }
        return nil
    }

    public func hasPayed(_ productId: String) -> Bool {
        guard let payInfo = payInfo(productId) else {
            return false
        }
        return Bundle.main.isDebug() || isPayInfoValid(payInfo)
    }

    private func isPayInfoValid(_ payInfo: PayInfo?) -> Bool {

        // 网络时间，不能区本地时间，否则用户可以修改本地时间，从而绕过支付
        guard let netDataMs = payInfo?.netDataMs else {
            return false
        }

        return expireDateMs(payInfo: payInfo) >= netDataMs
    }

    public func expireDateMs(productId: String) -> Int64{
        let payInfo = payInfo(productId)
        return expireDateMs(payInfo:payInfo)
    }

    public func expireDateMs(payInfo: PayInfo?) -> Int64{
        guard let payInfo = payInfo else {
            return 0
        }

        guard let inapps = payInfo.inApps else {
            return 0
        }

        // 网络时间，不能区本地时间，否则用户可以修改本地时间，从而绕过支付
        guard payInfo.netDataMs != nil else {
            return 0
        }

        let swiftArray = inapps.map { $0 as! InAppBean }

        let sortInApps = swiftArray.sorted { (a, b) -> Bool in
            a.purchaseDateMs > b.purchaseDateMs
        }

        let firstPurchaseDataMs: Int64 = sortInApps.last?.purchaseDateMs ?? 0
        // 有效期是一年, 买了几个就延长几年, 毫秒
        let duration: Int64 = Int64(365 * 24 * 60 * 60 * 1000 * sortInApps.count)
        let expireDateMS: Int64 = firstPurchaseDataMs + duration
        return expireDateMS
    }

    private func getLocalDateFormatAnyDate(_ anyDate: Date) -> Date {
        let sourceTimeZone = TimeZone(abbreviation: "UTC") //或GMT
        let desTimeZone = TimeZone.current
        //得到源日期与世界标准时间的偏移量
        let sourceGMTOffset = sourceTimeZone?.secondsFromGMT(for: anyDate) ?? 0
        //目标日期与本地时区的偏移量
        let destinationGMTOffset = desTimeZone.secondsFromGMT(for: anyDate)
        //得到时间偏移量的差值
        let interval = TimeInterval(destinationGMTOffset - sourceGMTOffset)
        //转为现在时间
        let destinationDateNow = Date(timeInterval: interval, since: anyDate)
        return destinationDateNow
    }
    
    public func expireDateString(_ productId: String) -> String{
        // 毫秒转成秒
        let expireTime = expireDateMs(productId: productId) / 1000
        if expireTime != 0 {
            let date = Date(timeIntervalSince1970: TimeInterval(expireTime))
            let localDate = getLocalDateFormatAnyDate(date)
            let dateFormatter = DateFormatter()

            //设置格式：zzz表示时区
            dateFormatter.dateFormat = "yyyy/MM/dd"

            //NSDate转NSString
            let currentDateString = dateFormatter.string(from: localDate)
//            restoreLabel.text = "高级功能到期:\(currentDateString)"
            return currentDateString
        } else {
//            restoreLabel.text = "恢复之前购买"
            return ""
        }
    }
}
