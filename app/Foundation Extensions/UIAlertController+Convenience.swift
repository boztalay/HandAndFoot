//
//  UIAlertController+Convenience.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/22/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation
import UIKit


extension UIAlertController {
    
    static func presentErrorAlert(on viewController: UIViewController, title: String, message: String? = nil, okAction: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction.init(title: "OK", style: .default) { alertAction in
            if let okAction = okAction {
                okAction()
            }
        })

        viewController.present(alert, animated: true)
    }
}
