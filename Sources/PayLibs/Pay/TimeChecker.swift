//
// Created by yancai  on 2023/4/21.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation
import MyLoggerOC

 @objcMembers class TimeChecker: NSObject {

     static let shared = TimeChecker()

     private override init() {
         super.init()
     }

     func checkReceiptTimeHave(_ currentTime: Date, receipt: [String: Any]?) -> Int {
        guard let receiptDic = receipt?["receipt"] as? [String: Any], let inApps = receiptDic["in_app"] as? [[String: Any]] else {
            return 0
        }

        let sortedArray = inApps.sorted { (obj1, obj2) -> Bool in
            let value1 = Int64(obj1["purchase_date_ms"] as! String) ?? 0
            let value2 = Int64(obj2["purchase_date_ms"] as! String) ?? 0
            return value1 > value2
        }

        var filterArrary = [[String: Any]]()
        for one in sortedArray {
            let purchase_date_ms = Int64(one["purchase_date_ms"] as! String) ?? 0
            let date = Date(timeIntervalSince1970: TimeInterval(purchase_date_ms / 1000))
            var dateComponents = DateComponents()
            dateComponents.year = 1
            let newdate = Calendar(identifier: .gregorian).date(byAdding: dateComponents, to: date)!
            if newdate >= currentTime {
                filterArrary.append(one)
            }
        }

        if filterArrary.count == 0 {
            return 0
        }

        let one = filterArrary.first!
        let purchase_date = Int64(one["purchase_date_ms"] as! String) ?? 0
        let date = Date(timeIntervalSince1970: TimeInterval(purchase_date / 1000))
        var dateComponents = DateComponents()
        dateComponents.year = filterArrary.count
        let newdate = Calendar(identifier: .gregorian).date(byAdding: dateComponents, to: date)!
        //let newTimeInterval = newdate.timeIntervalSince1970

        //UserDefaults.standard.set(newTimeInterval, forKey: _currentProductID + "exp_time")
        let interval = Int(newdate.timeIntervalSince(currentTime))
        MyLogger.print("PayManager --> checkReceiptTimeHave: 购买过，还没有过期，剩余 \(interval) 秒")
        return interval
    }
}
