//
//  Int64+ext.swift
//  Forum
//
//  Created by andforce on 2023/5/28.
//  Copyright © 2023 None. All rights reserved.
//

import Foundation

extension Int64 {
    func dateString() -> String {
        
        let expireTime = self / 1000
        if expireTime != 0 {
            let date = Date(timeIntervalSince1970: TimeInterval(expireTime))
            let localDate = getLocalDateFormatAnyDate(date)
            let dateFormatter = DateFormatter()

            //设置格式：zzz表示时区
            dateFormatter.dateFormat = "yyyy/MM/dd"

            //NSDate转NSString
            let currentDateString = dateFormatter.string(from: localDate)
            return currentDateString
        } else {
            return ""
        }
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
}
