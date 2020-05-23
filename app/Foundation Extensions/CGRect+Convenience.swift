//
//  CGRect+Convenience.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/22/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

extension CGRect {
    
    func setting(x: CGFloat) -> CGRect {
        return CGRect(x: x, y: self.origin.y, width: self.width, height: self.height)
    }
    
    func setting(y: CGFloat) -> CGRect {
        return CGRect(x: self.origin.x, y: y, width: self.width, height: self.height)
    }
}
