//
// Created by andforce on 2023/4/21.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation

@objcMembers public class InternetTimeFetcher: NSObject {

    private let AppStore = "https://buy.itunes.apple.com/verifyReceipt"
    static let shared = InternetTimeFetcher()

    private override init() {
        super.init()
    }

    func getInternetDate(success: @escaping (Date) -> Void, failure: @escaping (Error) -> Void) {
        // 1. 创建URL
        guard let url = URL(string: AppStore.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            return
        }

        // 2. 创建request请求对象
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 5
        request.httpShouldHandleCookies = false
        request.httpMethod = "GET"

        // 3. 创建URLSession对象
        let session = URLSession.shared

        // 4. 设置数据返回回调的block
        let task = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    failure(error)
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    failure(NSError(domain: "Invalid response", code: 0, userInfo: nil))
                }
                return
            }

            // 这么做的原因是简体中文下的手机不能识别“MMM”，只能识别“MM”
            let monthEnglishArray = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sept", "Sep", "Oct", "Nov", "Dec"]
            let monthNumArray = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "09", "10", "11", "12"]
            guard let dateStr = httpResponse.allHeaderFields["Date"] as? String else {
                DispatchQueue.main.async {
                    failure(NSError(domain: "Invalid date string", code: 0, userInfo: nil))
                }
                return
            }

            var newDateStr = dateStr
            newDateStr = String(newDateStr.dropFirst(5))
            newDateStr = String(newDateStr.dropLast(4))
            newDateStr = newDateStr + " +0000"
            // 当前语言是中文的话，识别不了英文缩写
            for i in 0..<monthEnglishArray.count {
                let monthEngStr = monthEnglishArray[i]
                let monthNumStr = monthNumArray[i]
                newDateStr = newDateStr.replacingOccurrences(of: monthEngStr, with: monthNumStr)
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MM yyyy HH:mm:ss Z"
            guard let netDate = dateFormatter.date(from: newDateStr) else {
                DispatchQueue.main.async {
                    failure(NSError(domain: "Invalid date format", code: 0, userInfo: nil))
                }
                return
            }

            DispatchQueue.main.async {
                success(netDate)
            }
        }

        // 5. 执行网络请求
        task.resume()
    }
}
