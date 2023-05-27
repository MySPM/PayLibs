//
// Created by andforce on 2023/4/21.
// Copyright (c) 2023 None. All rights reserved.
//

import Foundation

@objcMembers public class ReceiptDataVerifier: NSObject {

    static let shared = ReceiptDataVerifier()

    private override init() {
        super.init()
    }

    private let SANDBOX = "https://sandbox.itunes.apple.com/verifyReceipt"
    private let AppStore = "https://buy.itunes.apple.com/verifyReceipt"

    func verify(receipt: Data, handler: @escaping (Date, Dictionary<String, Any>) -> Void) {
        // 先检查网络时间
        InternetTimeFetcher.shared.getInternetDate(success: { [self] date in
            // 向苹果服务器验证凭证
            post(url: AppStore, receiptData: receipt) { [self] dictionary in
                if dictionary.isEmpty {
                    handler(date, dictionary)
                } else {
                    // 21007 说明是 Sandbox 下的收据却拿到正式环境进行了验证，因此需要重新在 Sandbox 下进行验证
                    if let status = dictionary["status"] as? Int, status == 21007 {
                        post(url: SANDBOX, receiptData: receipt) { sandboxDictionary in
                            handler(date, sandboxDictionary)
                        }
                    } else {
                        handler(date, dictionary)
                    }
                }
            }
        }, failure: { error in
            // 时间检查失败就返回空
            handler(Date(), Dictionary())
        })
    }

    func verifyLocal(password: String?, handler: @escaping (Date, Dictionary<String, Any>) -> Void) {
        guard let data = appStoreReceiptData(password: password) else {
            handler(Date(), Dictionary())
            return
        }
        verify(receipt: data, handler: handler)
    }
    
    private func post(url: String, receiptData: Data, handler: @escaping (Dictionary<String, Any>) -> Void) {
        guard let URL = URL(string: url) else {
            handler(Dictionary())
            return
        }
        //创建请求到苹果官方进行购买验证
        //1.创建NSURLSession对象（可以获取单例对象）
        let session = URLSession.shared

        //2.根据NSURLSession对象创建一个Task

        var request = URLRequest(url: URL)
        request.httpBody = receiptData
        request.httpMethod = "POST"

        let dataTask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("PayManager --> verify->:\tverifyWithUrl() \(URL): 验证发生错误: \(error.localizedDescription)")
                handler(Dictionary())
                return
            }
            guard let data = data, let dic = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
                print("PayManager --> verify->:\tverifyWithUrl() \(URL): 验证返回数据为空")
                handler(Dictionary())
                return
            }
            print("PayManager --> verify->:\tverifyWithUrl() \(URL): 验证返回数据: \(dic)")
            handler(dic)
        }

        //3.执行Task
        //注意：刚创建出来的task默认是挂起状态的，需要调用该方法来启动任务（执行任务）
        dataTask.resume()
    }

    private func appStoreReceiptData(password: String?) -> Data? {
        //从沙盒中获取交易凭证并且拼接成请求体数据
        let receiptUrl = Bundle.main.appStoreReceiptURL
        guard let receiptData = try? Data(contentsOf: receiptUrl!) else {
            print("PayManager --> verify->:\tverifyWithUrl() : 没有任何收据，无需再次验证了")
            return nil
        }

        //转化为base64字符串
        let receiptBase64Str = receiptData.base64EncodedString(options: .endLineWithLineFeed)

        //http://cwqqq.com/2017/12/05/ios_in-app_pay_server_side_code
        //let bodyString = "{\"receipt-data\" : \"\(receiptString)\", \"password\":\"b3189c215c0b423d985bc8d2548bb91a\"}"
        
        var receiptDataStr = """
                                {
                                    "receipt-data" : "\(receiptBase64Str)"
                                }
                                """
        if password != nil && !password!.isEmpty {
            receiptDataStr = """
                                {
                                    "receipt-data" : "\(receiptBase64Str)",
                                    "password":"\(password!)"
                                }
                                """
        }
        
        guard let bodyData = receiptDataStr.data(using: .utf8) else {
            return nil
        }
        return bodyData
    }
}
