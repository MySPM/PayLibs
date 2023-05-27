//
// Created by andforce on 2023/5/20.
// Copyright (c) 2023 andforce. All rights reserved.
//

import Foundation
import SwiftUI

struct DialogView<Content: View>: View {
    @Binding private var isPresented: Bool
    private let content: () -> Content

    init(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self._isPresented = isPresented
        self.content = content
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        dismiss()
                    }

            VStack {
                content()
            }.frame(maxHeight: 500)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding()
        }
    }

    private func dismiss() {
        isPresented = false
    }
}
