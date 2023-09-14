//
// Created by yancai  on 2023/4/23.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation

@objcMembers public class PayInfo: NSObject, NSCoding, NSSecureCoding {
    
    // 返回是否支持安全编码
    public static var supportsSecureCoding: Bool {
        return true
    }
    
    // 内购信息
    // https://www.cnblogs.com/itlover2013/p/15041526.html
    //
    //in_app与latest_receipt_info
    // 测试时发现，这两个字段的数值几乎相同，不过有几点需要注意：
    //（1）自动续订订阅类型，在到期后会再生成一条购买记录，这条记录会出现在last_receipt_info里，但不会出现在in_app里
    //（2）自动续订订阅类型可以配置试用，试用记录只有在latest_receipt_info里，is_trial_period字段才是true
    //（3）消耗型购买记录有可能不会出现在latest_receipt_info，因此需要检查in_app来确保校验正确
    public var inApps:[InAppBean]? = nil
    public var latestReceiptInfo:[InAppBean]? = nil

    override init() {
        super.init()
    }

    public static func create(response: Dictionary<String, Any>) -> PayInfo {
        let payInfo = PayInfo()

        var lastInAppsArr = [InAppBean]()
        if let last_receipt_infos = response["latest_receipt_info"] as? [[String: Any]] {
            for item in last_receipt_infos {
                let bean = toInApp(item: item)
                lastInAppsArr.append(bean)
            }
        }
        payInfo.latestReceiptInfo = lastInAppsArr
        
        var inAppsArr = [InAppBean]()
        if let receiptDic = response["receipt"] as? [String: Any], let inApps = receiptDic["in_app"] as? [[String: Any]] {
            for item in inApps {
                let bean = toInApp(item: item)
                inAppsArr.append(bean)
            }
        }
        payInfo.inApps = inAppsArr
        return payInfo
    }

    private static func toInApp(item: [String:Any]) -> InAppBean {
        let bean = InAppBean()
        bean.expiresDate = item["expires_date"] as? String ?? ""
        bean.expiresDateMs = Int64(item["expires_date_ms"] as? String ?? "0")!
        bean.expiresDatePst = item["expires_date_pst"] as? String ?? ""
        bean.inAppOwnershipType = item["in_app_ownership_type"] as? String ?? ""
        bean.isInIntroOfferPeriod = item["is_in_intro_offer_period"] as? Bool ?? false
        bean.isTrialPeriod = item["is_trial_period"] as? Bool ?? false
        bean.cancellationDate = item["cancellation_date"] as? String ?? ""
        bean.cancellationDateMs = Int64(item["cancellation_date_ms"] as? String ?? "0")!
        bean.cancellationDatePst = item["cancellation_date_pst"] as? String ?? ""
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
        return bean
    }

    public static func createError() -> PayInfo {
        return create(response: Dictionary())
    }

    public func encode(with coder: NSCoder) {
        coder.encode(inApps, forKey: "inApps")
        coder.encode(latestReceiptInfo, forKey: "latestReceiptInfo")
    }

    required convenience public init?(coder: NSCoder) {
        self.init()
        inApps = coder.decodeArrayOfObjects(ofClass: InAppBean.self, forKey: "inApps")
        latestReceiptInfo = coder.decodeArrayOfObjects(ofClass: InAppBean.self, forKey: "latestReceiptInfo")
    }

    public override var description: String {
        let inApps = inApps == nil ? [] : inApps!
        let latestReceiptInfo = latestReceiptInfo == nil ? [] : latestReceiptInfo!

        return """
               PayInfo(
                   inApps:
                           \(inApps),
                   latestReceiptInfo:
                           \(latestReceiptInfo)
               )
               """
    }
}



@objcMembers public class InAppBean: NSObject, NSCoding, NSSecureCoding {

    //{
    ////    "expires_date": "2023-05-27 17:20:21 Etc/GMT",
    ////    "expires_date_ms": 1685208021000,
    ////    "expires_date_pst": "2023-05-27 10:20:21 America/Los_Angeles",
//            "cancellation_date": "2019-12-05 19:14:48 Etc/GMT",
//            "cancellation_date_ms": "1575573288000",
//            "cancellation_date_pst": "2019-12-05 11:14:48 America/Los_Angeles",

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
//"cancellation_date": "2019-12-05 19:14:48 Etc/GMT",
//"cancellation_date_ms": "1575573288000",
//"cancellation_date_pst": "2019-12-05 11:14:48 America/Los_Angeles",
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
    // 用户退款时间，如果存在，说明用户已经退款
    public var cancellationDate: String = ""
    public var cancellationDateMs: Int64 = 0
    public var cancellationDatePst: String = ""

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
        coder.encode(cancellationDate, forKey: "cancellation_date")
        coder.encode(cancellationDateMs, forKey: "cancellation_date_ms")
        coder.encode(cancellationDatePst, forKey: "cancellation_date_pst")
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
        if let decodedExpression = coder.decodeObject(of: NSString.self, forKey: "expires_date") as String? {
            expiresDate = decodedExpression
        } else {
            expiresDate = ""
        }

        expiresDateMs = coder.decodeInt64(forKey: "expires_date_ms")
        //expiresDatePst = coder.decodeObject(forKey: "expires_date_pst") as? String ?? ""
        if let expiresDatePst = coder.decodeObject(of: NSString.self, forKey: "expires_date_pst") as String? {
            self.expiresDatePst = expiresDatePst
        } else {
            self.expiresDatePst = ""
        }
        //inAppOwnershipType = coder.decodeObject(forKey: "in_app_ownership_type") as? String ?? ""
        if let inAppOwnershipType = coder.decodeObject(of: NSString.self, forKey: "in_app_ownership_type") as String? {
            self.inAppOwnershipType = inAppOwnershipType
        } else {
            self.inAppOwnershipType = ""
        }
        isInIntroOfferPeriod = coder.decodeBool(forKey: "is_in_intro_offer_period")
        isTrialPeriod = coder.decodeBool(forKey: "is_trial_period")
        //cancellationDate = coder.decodeObject(forKey: "cancellation_date") as? String ?? ""
        if let cancellationDate = coder.decodeObject(of: NSString.self, forKey: "cancellation_date") as String? {
            self.cancellationDate = cancellationDate
        } else {
            self.cancellationDate = ""
        }
        cancellationDateMs = coder.decodeInt64(forKey: "cancellation_date_ms")
        //cancellationDatePst = coder.decodeObject(forKey: "cancellation_date_pst") as? String ?? ""
        if let cancellationDatePst = coder.decodeObject(of: NSString.self, forKey: "cancellation_date_pst") as String? {
            self.cancellationDatePst = cancellationDatePst
        } else {
            self.cancellationDatePst = ""
        }
        //originalPurchaseDate = coder.decodeObject(forKey: "original_purchase_date") as? String ?? ""
        if let originalPurchaseDate = coder.decodeObject(of: NSString.self, forKey: "original_purchase_date") as String? {
            self.originalPurchaseDate = originalPurchaseDate
        } else {
            self.originalPurchaseDate = ""
        }
        originalPurchaseDateMs = coder.decodeInt64(forKey: "original_purchase_date_ms")
        //originalPurchaseDatePst = coder.decodeObject(forKey: "original_purchase_date_pst") as? String ?? ""
        if let originalPurchaseDatePst = coder.decodeObject(of: NSString.self, forKey: "original_purchase_date_pst") as String? {
            self.originalPurchaseDatePst = originalPurchaseDatePst
        } else {
            self.originalPurchaseDatePst = ""
        }
        //originalTransactionId = coder.decodeObject(forKey: "original_transaction_id") as? String ?? ""
        if let originalTransactionId = coder.decodeObject(of: NSString.self, forKey: "original_transaction_id") as String? {
            self.originalTransactionId = originalTransactionId
        } else {
            self.originalTransactionId = ""
        }
        //productId = coder.decodeObject(forKey: "product_id") as? String ?? ""
        if let productId = coder.decodeObject(of: NSString.self, forKey: "product_id") as String? {
            self.productId = productId
        } else {
            self.productId = ""
        }
        //purchaseDate = coder.decodeObject(forKey: "purchase_date") as? String ?? ""
        if let purchaseDate = coder.decodeObject(of: NSString.self, forKey: "purchase_date") as String? {
            self.purchaseDate = purchaseDate
        } else {
            self.purchaseDate = ""
        }
        purchaseDateMs = coder.decodeInt64(forKey: "purchase_date_ms")
        //purchaseDatePst = coder.decodeObject(forKey: "purchase_date_pst") as? String ?? ""
        if let purchaseDatePst = coder.decodeObject(of: NSString.self, forKey: "purchase_date_pst") as String? {
            self.purchaseDatePst = purchaseDatePst
        } else {
            self.purchaseDatePst = ""
        }
        quantity = coder.decodeInteger(forKey: "quantity")
        //subscriptionGroupIdentifier = coder.decodeObject(forKey: "subscription_group_identifier") as? String ?? ""
        if let subscriptionGroupIdentifier = coder.decodeObject(of: NSString.self, forKey: "subscription_group_identifier") as String? {
            self.subscriptionGroupIdentifier = subscriptionGroupIdentifier
        } else {
            self.subscriptionGroupIdentifier = ""
        }
        //transactionId = coder.decodeObject(forKey: "transaction_id") as? String ?? ""
        if let transactionId = coder.decodeObject(of: NSString.self, forKey: "transaction_id") as String? {
            self.transactionId = transactionId
        } else {
            self.transactionId = ""
        }
        //webOrderLineItemId = coder.decodeObject(forKey: "web_order_line_item_id") as? String ?? ""
        if let webOrderLineItemId = coder.decodeObject(of: NSString.self, forKey: "web_order_line_item_id") as String? {
            self.webOrderLineItemId = webOrderLineItemId
        } else {
            self.webOrderLineItemId = ""
        }
    }

    public func isAutoSubscription() -> Bool {
        return expiresDate != ""
    }

    public func isCanceled() -> Bool {
        return cancellationDate != ""
    }

    public func isPurchase() -> Bool {
        return inAppOwnershipType == "PURCHASED"
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
                   \r\n\t\t{
                   \t\t    expiresDate: \(expiresDate),
                   \t\t    expiresDateCurrentTimezone: \(self.expiresDateCurrentTimezone()),
                   \t\t    expiresDateMs: \(expiresDateMs), 
                   \t\t    expiresDatePst: \(expiresDatePst), 
                   \t\t    inAppOwnershipType: \(inAppOwnershipType), 
                   \t\t    isInIntroOfferPeriod: \(isInIntroOfferPeriod), 
                   \t\t    isTrialPeriod: \(isTrialPeriod), 
                   \t\t    cancellationDate: \(cancellationDate),
                   \t\t    cancellationDateMs: \(cancellationDateMs),
                   \t\t    cancellationDatePst: \(cancellationDatePst),
                   \t\t    originalPurchaseDate: \(originalPurchaseDate), 
                   \t\t    originalPurchaseDateMs: \(originalPurchaseDateMs), 
                   \t\t    originalPurchaseDatePst: \(originalPurchaseDatePst), 
                   \t\t    originalTransactionId: \(originalTransactionId), 
                   \t\t    productId: \(productId), 
                   \t\t    purchaseDate: \(purchaseDate), 
                   \t\t    purchaseDateMs: \(purchaseDateMs), 
                   \t\t    purchaseDatePst: \(purchaseDatePst), 
                   \t\t    quantity: \(quantity), 
                   \t\t    subscriptionGroupIdentifier: \(subscriptionGroupIdentifier), 
                   \t\t    transactionId: \(transactionId), 
                   \t\t    webOrderLineItemId: \(webOrderLineItemId)
                   \t\t}
                   """
        } else {
            return """
                   \r\n\t\t{
                   \t\t    inAppOwnershipType: \(inAppOwnershipType), 
                   \t\t    isInIntroOfferPeriod: \(isInIntroOfferPeriod), 
                   \t\t    isTrialPeriod: \(isTrialPeriod), 
                   \t\t    cancellationDate: \(cancellationDate),
                   \t\t    cancellationDateMs: \(cancellationDateMs),
                   \t\t    cancellationDatePst: \(cancellationDatePst),
                   \t\t    originalPurchaseDate: \(originalPurchaseDate), 
                   \t\t    originalPurchaseDateMs: \(originalPurchaseDateMs), 
                   \t\t    originalPurchaseDatePst: \(originalPurchaseDatePst), 
                   \t\t    originalTransactionId: \(originalTransactionId), 
                   \t\t    productId: \(productId), 
                   \t\t    purchaseDate: \(purchaseDate), 
                   \t\t    purchaseDateMs: \(purchaseDateMs), 
                   \t\t    purchaseDatePst: \(purchaseDatePst), 
                   \t\t    quantity: \(quantity), 
                   \t\t    transactionId: \(transactionId), 
                   \t\t}
                   """
        }
    }
}
