//
//  File.swift
//  
//
//  Created by Dy Wang on 2023/8/16.
//

import Foundation
import StoreKit

@objcMembers public class LocalePriceHelper : NSObject, SKProductsRequestDelegate {
    
    public static let shared = LocalePriceHelper()
    
    private var products: [SKProduct]?
    
    // SKProductsRequestDelegate methods
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        products = response.products
        print("[PayManager]: LocalePriceHelper, productsRequest, didReceive, \(response.products)")
    }

    // SKProductsRequestDelegate methods
    public func request(_ request: SKRequest, didFailWithError error: Error) {
        print("[PayManager]: LocalePriceHelper, didFailWithError：\(error)")
    }

    // SKProductsRequestDelegate methods
    public func requestDidFinish(_ request: SKRequest) {
        print("[PayManager]: LocalePriceHelper, requestDidFinish")
    }
    
    public func requestProducts(productIds:[String]) {

        if SKPaymentQueue.canMakePayments() {
            print("[PayManager]: LocalePriceHelper, --> start reuqest products")
            let products = NSSet(array: productIds)
            let request = SKProductsRequest(productIdentifiers: products as! Set<String>)

            request.delegate = self
            request.start()
            
        } else {
            print("[PayManager]: LocalePriceHelper, --> 应用没有开启内购权限")
        }
    }
    
    public func localePrice(productId: String) -> String {
        guard let products = products else {
            print("[PayManager]: LocalePriceHelper, localePrice is nil")
            return ""
        }
        
        for product in products {
            let numberFormatter = NumberFormatter()
            numberFormatter.formatterBehavior = .behavior10_4 
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = product.priceLocale
            let formattedPrice = numberFormatter.string(from: product.price)
            
            print("PayManager --> LocalePriceHelper, 内购本地化货币:\(formattedPrice!), \(product.productIdentifier), \(product.priceLocale)")
            
            if product.productIdentifier == productId {
                guard let formattedPrice = formattedPrice else {
                    return ""
                }
                
                return formattedPrice
            }
        }

        return ""
    }
    
    public func localePriceOrg(productId: String) -> String {
        guard let products = products else {
            return ""
        }
        
        for product in products {
            let numberFormatter = NumberFormatter()
            numberFormatter.formatterBehavior = .behavior10_4
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = product.priceLocale
            let formattedPrice = numberFormatter.string(from: product.price.multiplying(by: 1.6))
            
            print("PayManager --> 内购本地化货币:\(formattedPrice!), \(product.productIdentifier), \(product.priceLocale)")
            
            if product.productIdentifier == productId {
                guard let formattedPrice = formattedPrice else {
                    return ""
                }
                
                return formattedPrice
            }
        }

        return ""
    }
}
