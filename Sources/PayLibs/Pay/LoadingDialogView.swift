//
// Created by andforce on 2023/5/20.
// Copyright (c) 2023 andforce. All rights reserved.
//

import Foundation
import SwiftUI


public struct LoadingDialogView :View{
    @Binding private var isPresented: Bool
    
    @Environment(\.colorScheme) var colorScheme


    public init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        //dismiss()
                    }

            VStack {
                ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
            }.frame(width: 80, height: 80)
                .background((colorScheme == .dark) ? Color.black : Color.white)
                    .cornerRadius(10)
                    .padding()
        }
    }

    private func dismiss() {
        isPresented = false
    }
}
