//
// Created by andforce on 2023/4/23.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation

@objcMembers public class PayInfo: NSObject, NSCoding, NSSecureCoding {
    
    // 返回是否支持安全编码
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    // 状态
    public var status: Int = -1;
    public var productId: String = ""
    // 网络时间：毫秒
    public var netDataMs: Int64? = nil
    // 内购信息
    public var inApps:[InAppBean]? = nil

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
                bean.expiresDate = item["expires_date"] as? String ?? ""
                bean.expiresDateMs = Int64(item["expires_date_ms"] as? String ?? "0")!
                bean.expiresDatePst = item["expires_date_pst"] as? String ?? ""
                bean.inAppOwnershipType = item["in_app_ownership_type"] as? String ?? ""
                bean.isInIntroOfferPeriod = item["is_in_intro_offer_period"] as? Bool ?? false
                bean.isTrialPeriod = item["is_trial_period"] as? Bool ?? false
                bean.originalPurchaseDate = item["original_purchase_date"] as? String ?? ""
                bean.originalPurchaseDateMs = Int64(item["original_purchase_date_ms"] as? String ?? "0")!
                bean.originalPurchaseDatePst = item["original_purchase_date_pst"] as? String ?? ""
                bean.originalTransactionId = item["original_transaction_id"] as? String ?? ""
                bean.productId = item["product_id"] as? String ?? ""
                bean.purchaseDate = item["purchase_date"] as? String ?? ""
                bean.purchaseDateMs = Int64(item["purchase_date_ms"] as? String ?? "0")!
                bean.purchaseDatePst = item["purchase_date_pst"] as? String ?? ""
                bean.quantity = Int(item["quantity"] as? String ?? "0")!
                bean.subscriptionGroupIdentifier = item["subscription_group_identifier"] as? String ?? ""
                bean.transactionId = item["transaction_id"] as? String ?? ""
                bean.webOrderLineItemId = item["web_order_line_item_id"] as? String ?? ""

                inAppsArr.append(bean)
            }
        }

        //let nsArray = NSArray(array: inAppsArr)
        payInfo.inApps = inAppsArr
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
        inApps = coder.decodeArrayOfObjects(ofClass: InAppBean.self, forKey: "inApps")
    }

}



@objcMembers public class InAppBean: NSObject, NSCoding, NSSecureCoding {

    //{
    ////    "expires_date": "2023-05-27 17:20:21 Etc/GMT",
    ////    "expires_date_ms": 1685208021000,
    ////    "expires_date_pst": "2023-05-27 10:20:21 America/Los_Angeles",

    //    "in_app_ownership_type": "PURCHASED",
    ////    "is_in_intro_offer_period": false,
    //    "is_trial_period": false,
    //    "original_purchase_date": "2023-05-27 14:20:29 Etc/GMT",
    //    "original_purchase_date_ms": 1685197229000,
    //    "original_purchase_date_pst": "2023-05-27 07:20:29 America/Los_Angeles",
    //    "original_transaction_id": 2000000339154501,
    //    "product_id": "forum_post_1_year",
    //    "purchase_date": "2023-05-27 16:20:21 Etc/GMT",
    //    "purchase_date_ms": 1685204421000,
    //    "purchase_date_pst": "2023-05-27 09:20:21 America/Los_Angeles",
    //    "quantity": 1,
    ////    "subscription_group_identifier": 21345454,
    //    "transaction_id": 2000000339174296,
    ////    "web_order_line_item_id": 2000000028366196
    //}
    

    // {
    //            "in_app_ownership_type" = PURCHASED;
    //            "is_trial_period" = false;
    //            "original_purchase_date" = "2023-05-27 10:03:25 Etc/GMT";
    //            "original_purchase_date_ms" = 1685181805000;
    //            "original_purchase_date_pst" = "2023-05-27 03:03:25 America/Los_Angeles";
    //            "original_transaction_id" = 2000000339110824;
    //            "product_id" = "com.andforce.fourms.001";
    //            "purchase_date" = "2023-05-27 10:03:25 Etc/GMT";
    //            "purchase_date_ms" = 1685181805000;
    //            "purchase_date_pst" = "2023-05-27 03:03:25 America/Los_Angeles";
    //            quantity = 1;
    //            "transaction_id" = 2000000339110824;
    //        }

    // 返回是否支持安全编码
    public static var supportsSecureCoding: Bool {
        return true
    }
    public var expiresDate: String = ""
    /**
     苹果自动续费订阅（Auto renewable Subscription）

     实际订阅有效期      Sandbox测试有效期
     1 周                         3 分钟
     1 个月                      5 分钟
     2 个月                     10 分钟
     3 个月                     15 分钟
     6 个月                     30 分钟
     1 年                         1 小时

     作者：StevenC
     链接：https://www.jianshu.com/p/ec6ecce027ff
     */
    public var expiresDateMs: Int64 = 0
    public var expiresDatePst: String = ""
    public var inAppOwnershipType: String = ""
    public var isInIntroOfferPeriod: Bool = false
    public var isTrialPeriod: Bool = false
    public var originalPurchaseDate: String = ""
    public var originalPurchaseDateMs: Int64 = 0
    public var originalPurchaseDatePst: String = ""
    public var originalTransactionId: String = ""
    public var productId: String = ""
    public var purchaseDate: String = ""
    public var purchaseDateMs: Int64 = 0
    public var purchaseDatePst: String = ""
    public var quantity: Int = 0
    public var subscriptionGroupIdentifier: String = ""
    public var transactionId: String = ""
    public var webOrderLineItemId: String = ""

    override init() {
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(expiresDate, forKey: "expires_date")
        coder.encode(expiresDateMs, forKey: "expires_date_ms")
        coder.encode(expiresDatePst, forKey: "expires_date_pst")
        coder.encode(inAppOwnershipType, forKey: "in_app_ownership_type")
        coder.encode(isInIntroOfferPeriod, forKey: "is_in_intro_offer_period")
        coder.encode(isTrialPeriod, forKey: "is_trial_period")
        coder.encode(originalPurchaseDate, forKey: "original_purchase_date")
        coder.encode(originalPurchaseDateMs, forKey: "original_purchase_date_ms")
        coder.encode(originalPurchaseDatePst, forKey: "original_purchase_date_pst")
        coder.encode(originalTransactionId, forKey: "original_transaction_id")
        coder.encode(productId, forKey: "product_id")
        coder.encode(purchaseDate, forKey: "purchase_date")
        coder.encode(purchaseDateMs, forKey: "purchase_date_ms")
        coder.encode(purchaseDatePst, forKey: "purchase_date_pst")
        coder.encode(quantity, forKey: "quantity")
        coder.encode(subscriptionGroupIdentifier, forKey: "subscription_group_identifier")
        coder.encode(transactionId, forKey: "transaction_id")
        coder.encode(webOrderLineItemId, forKey: "web_order_line_item_id")

    }

    required public init?(coder: NSCoder) {
        expiresDate = coder.decodeObject(forKey: "expires_date") as? String ?? ""
        expiresDateMs = coder.decodeInt64(forKey: "expires_date_ms")
        expiresDatePst = coder.decodeObject(forKey: "expires_date_pst") as? String ?? ""
        inAppOwnershipType = coder.decodeObject(forKey: "in_app_ownership_type") as? String ?? ""
        isInIntroOfferPeriod = coder.decodeBool(forKey: "is_in_intro_offer_period")
        isTrialPeriod = coder.decodeBool(forKey: "is_trial_period")
        originalPurchaseDate = coder.decodeObject(forKey: "original_purchase_date") as? String ?? ""
        originalPurchaseDateMs = coder.decodeInt64(forKey: "original_purchase_date_ms")
        originalPurchaseDatePst = coder.decodeObject(forKey: "original_purchase_date_pst") as? String ?? ""
        originalTransactionId = coder.decodeObject(forKey: "original_transaction_id") as? String ?? ""
        productId = coder.decodeObject(forKey: "product_id") as? String ?? ""
        purchaseDate = coder.decodeObject(forKey: "purchase_date") as? String ?? ""
        purchaseDateMs = coder.decodeInt64(forKey: "purchase_date_ms")
        purchaseDatePst = coder.decodeObject(forKey: "purchase_date_pst") as? String ?? ""
        quantity = coder.decodeInteger(forKey: "quantity")
        subscriptionGroupIdentifier = coder.decodeObject(forKey: "subscription_group_identifier") as? String ?? ""
        transactionId = coder.decodeObject(forKey: "transaction_id") as? String ?? ""
        webOrderLineItemId = coder.decodeObject(forKey: "web_order_line_item_id") as? String ?? ""
    }

    public func isAutoSubscription() -> Bool {
        return expiresDate != ""
    }
    
    private func expiresDateCurrentTimezone() -> String{
        let date = Date(timeIntervalSince1970: TimeInterval(self.expiresDateMs) / 1000)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        let currentTime = dateFormatter.string(from: date)
        return currentTime
    }

    public override var description: String {
        if isAutoSubscription() {
            return """
                   {
                       expiresDate: \(expiresDate),
                       expiresDateCurrentTimezone: \(self.expiresDateCurrentTimezone()),
                       expiresDateMs: \(expiresDateMs), 
                       expiresDatePst: \(expiresDatePst), 
                       inAppOwnershipType: \(inAppOwnershipType), 
                       isInIntroOfferPeriod: \(isInIntroOfferPeriod), 
                       isTrialPeriod: \(isTrialPeriod), 
                       originalPurchaseDate: \(originalPurchaseDate), 
                       originalPurchaseDateMs: \(originalPurchaseDateMs), 
                       originalPurchaseDatePst: \(originalPurchaseDatePst), 
                       originalTransactionId: \(originalTransactionId), 
                       productId: \(productId), 
                       purchaseDate: \(purchaseDate), 
                       purchaseDateMs: \(purchaseDateMs), 
                       purchaseDatePst: \(purchaseDatePst), 
                       quantity: \(quantity), 
                       subscriptionGroupIdentifier: \(subscriptionGroupIdentifier), 
                       transactionId: \(transactionId), 
                       webOrderLineItemId: \(webOrderLineItemId)
                   }
                   """
        } else {
            return """
                   {
                       inAppOwnershipType: \(inAppOwnershipType), 
                       isInIntroOfferPeriod: \(isInIntroOfferPeriod), 
                       isTrialPeriod: \(isTrialPeriod), 
                       originalPurchaseDate: \(originalPurchaseDate), 
                       originalPurchaseDateMs: \(originalPurchaseDateMs), 
                       originalPurchaseDatePst: \(originalPurchaseDatePst), 
                       originalTransactionId: \(originalTransactionId), 
                       productId: \(productId), 
                       purchaseDate: \(purchaseDate), 
                       purchaseDateMs: \(purchaseDateMs), 
                       purchaseDatePst: \(purchaseDatePst), 
                       quantity: \(quantity), 
                       transactionId: \(transactionId), 
                   }
                   """
        }
    }
}
