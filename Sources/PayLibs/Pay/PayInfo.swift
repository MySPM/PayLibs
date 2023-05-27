//
// Created by andforce on 2023/4/23.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation

@objcMembers public class PayInfo: NSObject, NSCoding, NSSecureCoding {
    public static var supportsSecureCoding: Bool = true
    
    // 状态
    public var status: Int = -1;
    public var productId: String = ""
    // 网络时间：毫秒
    public var netDataMs: Int64? = nil
    // 内购信息
    public var inApps:NSArray? = nil

    override init() {
        super.init()
    }

    public static func create(_ productId: String, status: Int, netDateMs: Int64, response: Dictionary<String, Any>) -> PayInfo {
        let payInfo = PayInfo()
        payInfo.productId = productId
        payInfo.status = status
        payInfo.netDataMs = netDateMs

        var inAppsArr = [InAppBean]()
        if let receiptDic = response["receipt"] as? [String: Any], let inApps = receiptDic["in_app"] as? [[String: Any]] {
            for item in inApps {
                guard let in_app_ownership_type = item["in_app_ownership_type"], in_app_ownership_type as! String == "PURCHASED" else {
                    continue
                }
                let bean = InAppBean()
                let dateStr: String = item["purchase_date_ms"] as? String ?? "0"
                bean.purchaseDateMs = Int64(dateStr) ?? 0
                inAppsArr.append(bean)
            }
        }

        let nsArray = NSArray(array: inAppsArr)
        payInfo.inApps = nsArray
        return payInfo
    }

    public static func createError(_ productId: String, status: Int) -> PayInfo {
        return create(productId, status: status, netDateMs: 0, response: Dictionary())
    }

    public func encode(with coder: NSCoder) {
        coder.encode(status, forKey: "status")
        coder.encode(productId, forKey: "productId")
        coder.encode(netDataMs, forKey: "netDataMs")
        coder.encode(inApps, forKey: "inApps")
    }

    required convenience public init?(coder: NSCoder) {
        self.init()
        status = coder.decodeInteger(forKey: "status")
        productId = coder.decodeObject(forKey: "productId") as? String ?? ""
        netDataMs = coder.decodeObject(forKey: "netDataMs") as? Int64
        inApps = coder.decodeObject(forKey: "inApps") as? NSArray
    }

}



@objcMembers class InAppBean: NSObject, NSCoding, NSSecureCoding {
    static var supportsSecureCoding: Bool = true
    
    
    var purchaseDateMs: Int64 = 0

    override init() {
        super.init()
    }

    func encode(with coder: NSCoder) {
        // encode purchaseDateMs
        coder.encode(purchaseDateMs, forKey: "purchaseDateMs")
    }

    required init?(coder: NSCoder) {
        // decode purchaseDateMs
        purchaseDateMs = coder.decodeInt64(forKey: "purchaseDateMs")
    }
}
