//
//  UIGestureRecognizer+Cancel.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/12/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

extension UIGestureRecognizer {
    
    func cancel() {
        self.isEnabled = !self.isEnabled
        self.isEnabled = !self.isEnabled
    }
}
