//
// Created by andforce on 2023/5/20.
// Copyright (c) 2023 andforce. All rights reserved.
//

import Foundation
import SwiftUI


struct LoadingDialogView :View{
    @Binding private var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        //dismiss()
                    }

            VStack {
                ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
            }.frame(width: 80, height: 80)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding()
        }
    }

    private func dismiss() {
        isPresented = false
    }
}
