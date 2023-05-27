//
//  File.swift
//
//
//  Created by andforce on 2023/5/27.
//

import Foundation
import SwiftUI

public struct DialogStatusView :View{
    @State private var timer: Timer?

    @Binding private var isPresented: Bool
    @Binding private var isSuccess: Bool
    @Binding private var message: String
    
    @Environment(\.colorScheme) var colorScheme


    public init(isPresented: Binding<Bool>, isSuccess: Binding<Bool>, message: Binding<String>) {
        self._isPresented = isPresented
        self._isSuccess = isSuccess
        self._message = message
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        //dismiss()
                    }

            VStack {
                Image(systemName: isSuccess ? "checkmark" : "xmark")
                if !message.isEmpty {
                    Text(message).font(.system(size: 13)).padding(.top, 8).padding(.horizontal, 8)
                }
            }.frame(minWidth: 80, minHeight: 80)
                .background((colorScheme == .dark) ? Color.black : Color.white)
                    .cornerRadius(10)
                    .padding()
        }.onAppear {
            self.timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                dismiss()
            }
        }
    }

    private func dismiss() {
        timer?.invalidate()
        timer = nil
        
        isPresented = false
    }
}

struct DialogStatusView_Previews: PreviewProvider {
    
    static var previews: some View {
        @State var isPresented = true
        @State var isSuccess = true
        @State var message = "解锁成功"
        DialogStatusView(isPresented: $isPresented, isSuccess: $isSuccess, message: $message)
    }
}
