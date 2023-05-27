//
//  File.swift
//  
//
//  Created by andforce on 2023/5/27.
//

import Foundation
import SwiftUI

public struct PayUI : View {
    
    @State private var isProgressShowing: Bool = false

    
    @State private var isStatueViewShowing: Bool = false
    @State private var isPaySuccess: Bool = false
    @State private var statusMessage: String = ""
    
    @State private var buttonText : String = "点击解锁"
    
    private let payManager = PayManager.shared
    
    @Environment(\.presentationMode) private var presentationMode
    
    var productId: String = ""
    var password: String? = nil
    
    public init(productId: String, password: String?) {
        self.productId = productId
        self.password = password
    }
        
    public var body : some View {
        NavigationView {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                
                VStack {
                    itemsView
                    
                    PayRestoreBtnView(buttonText: $buttonText) {
                        isProgressShowing = true
                        
                        payManager.pay(productId, password: password) { info in
                            self.handleResult(isRestore: false, info: info)
                        }
                        
                    } restoreAction: {
                        isProgressShowing = true
                        
                        payManager.restore(productId, password: password) { info in
                            self.handleResult(isRestore: true, info: info)
                        }
                    }
                }
                
                // Loading
                if isProgressShowing {
                    LoadingDialogView(isPresented: $isProgressShowing).animation(.easeInOut)
                }
                
                if isStatueViewShowing {
                    DialogStatusView(isPresented: $isStatueViewShowing, isSuccess: $isPaySuccess, message: $statusMessage).animation(.easeInOut)
                }
            }
            
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: introButton)
        }.onAppear {
            let date = payManager.expireDateMs(productId).dateString()
            buttonText = date == "" ? "点击解锁" : "订阅至" + date
        }
        
    }
    
    func handleResult(isRestore: Bool, info: PayInfo) {
        isProgressShowing = false
        
        isStatueViewShowing = true
        isPaySuccess = info.status == 0
        
        if info.status == 0 {
            statusMessage = isRestore ? "恢复成功":"解锁成功"
        } else {
            statusMessage = isRestore ? "恢复失败":"解锁失败"
        }
    }
    
    var introButton : some View {
        Button(action: {
            if isStatueViewShowing || isProgressShowing{
                return
            }
            self.presentationMode.wrappedValue.dismiss()
        }) {
            HStack {
                Image(systemName: "xmark").imageScale(.medium)
            }.frame(height: 40)
        }
    }
    
    private var itemsView : some View {
        ScrollView{
            VStack {
                Text("👑").font(.system(size: 88))
                
                Text("解锁高级功能").font(.title3).foregroundColor(Color(.systemGray)).bold()
                
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark").foregroundColor(Color.blue)
                        Text("无限制发帖").font(.system(size: 20))
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "checkmark").foregroundColor(Color.blue)
                        Text("无限制回帖").font(.system(size: 20))
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "checkmark").foregroundColor(Color.blue)
                        Text("无限制搜索").font(.system(size: 20))
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "checkmark").foregroundColor(Color.blue)
                        Text("无限制发送私信").font(.system(size: 20))
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "checkmark").foregroundColor(Color.blue)
                        Text("无限制回复私信").font(.system(size: 20))
                        Spacer()
                    }
                    
                }
                .padding(.top, 18)
                .padding(.leading, 18)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("按年订阅").foregroundColor(.primary).bold().font(.system(size: 20))
                        Spacer()
                        Text("¥12.00").foregroundColor(.primary).bold().font(.system(size: 20))
                    }.padding(.horizontal, 18)
                        .padding(.top, 18)
                    
                    HStack {
                        Text("一年内尽享所有功能，可随时取消").foregroundColor(.secondary)
                        Spacer()
                    }.padding(.horizontal, 18)
                        .padding(.bottom, 18)
                    
                }
                .background(Color(UIColor.tertiarySystemFill))
                .cornerRadius(8)
                .padding(.horizontal, 18)
                .padding(.top, 9)
                
                HStack {
                    Link(destination: URL(string: "https://andforce.com/privacy_app.html")!) {
                        Text("隐私协议")
                    }
                    
                    Divider()
                    
                    Link(destination: URL(string: "https://andforce.com/terms_of_use_app.html")!) {
                        Text("使用条款")
                    }
                }.frame(height: 25)
                    .padding(.vertical, 4)
                
                Text("订阅费用将通过您的iTunes账户进行支付，您的订阅将自动续期，除非在当前期限结束前至少24小时取消，购买后可在账户设置中管理订阅。").foregroundColor(.secondary)
                    .padding(.horizontal, 18)
                
                
                Spacer()
            }
        }
    }
    
    private struct PayRestoreBtnView : View {
        private var payAction: () -> Void
        private var restoreAction: () -> Void
        @Binding var buttonText: String
        
        init(buttonText: Binding<String>, payAction: @escaping () -> Void, restoreAction: @escaping () -> Void) {
            self.payAction = payAction
            self.restoreAction = restoreAction
            self._buttonText = buttonText
        }
        
        var body: some View {
            VStack {
                //Spacer()
                
                VStack {
                    
                    Button {
                        payAction()
                    } label: {
                        Text("\(buttonText)").bold().foregroundColor(Color(UIColor.white))
                            .frame(maxWidth: .infinity) // 将Text的宽度设置为Button的最大宽度
                            .frame(height: 50)
                        
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color(UIColor.systemYellow))
                    .cornerRadius(8)
                    .padding(.horizontal, 18)
                    
                    Button {
                        restoreAction()
                    } label: {
                        Text("恢复订阅")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                }
                .background(Color(.systemGray6).ignoresSafeArea())
                
            }
        }
        
    }
}

struct PayUI_Previews: PreviewProvider {
    static var previews: some View {
        PayUI(productId: "com.andforce.fourms.001", password: "")
    }
}
