//
// Created by andforce on 2023/5/21.
// Copyright (c) 2023 andforce. All rights reserved.
//

import Foundation
import SwiftUI
import Network


extension UIViewController{

    func showSwiftUIView<Content>(content: Content, style: UIModalPresentationStyle, delegate: UIAdaptivePresentationControllerDelegate?) where Content : View {
        let vc = UIHostingController(rootView: content)
        vc.modalPresentationStyle = style
        vc.presentationController?.delegate = delegate
        self.present(vc, animated: true, completion: nil)
    }

    public func showViewControllerInSB(identifier: String, style: UIModalPresentationStyle) {
        //self.present(SettingController(), animated: true, completion: nil)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: identifier)
        viewController.modalPresentationStyle = style
        viewController.modalTransitionStyle = .crossDissolve
        viewController.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        viewController.view.alpha = 0.0

        UIView.animate(withDuration: 0.3, animations: {
            viewController.view.transform = CGAffineTransform.identity
            viewController.view.alpha = 1.0
        }) { _ in
            self.present(viewController, animated: false, completion: nil)
        }
    }
}
