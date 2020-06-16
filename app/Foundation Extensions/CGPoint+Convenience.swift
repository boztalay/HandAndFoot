//
//  CGPoint+Convenience.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/15/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    
    func distance(from other: CGPoint) -> CGFloat {
        let x = self.x - other.x
        let y = self.y - other.y

        return CGFloat(sqrt((x * x) + (y * y)))
    }
    
    func distanceFromOrigin() -> CGFloat {
        return self.distance(from: .zero)
    }
}
