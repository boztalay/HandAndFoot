//
//  FaceDownCardView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class FaceDownCardView: UIView {

    var handLabel: UILabel!
    var footLabel: UILabel!
    
    var isSelected: Bool {
        get {
            return (self.layer.borderColor == UIColor.systemRed.cgColor)
        }
        set {
            if newValue {
                self.layer.borderColor = UIColor.systemRed.cgColor
            } else {
                self.layer.borderColor = UIColor.black.cgColor
            }
        }
    }
    
    var isDragPlaceholder: Bool {
        get {
            return (self.alpha == 0.50)
        }
        set {
            if newValue {
                self.alpha = 0.50
            } else {
                self.alpha = 1.00
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        
        self.handLabel = UILabel()
        self.addSubview(self.handLabel)
        self.handLabel.pin(edge: .leading, to: .leading, of: self)
        self.handLabel.pin(edge: .top, to: .top, of: self)
        self.handLabel.pinWidth(toWidthOf: self, multiplier: 0.5, constant: 0.0)
        self.handLabel.pinHeight(toHeightOf: self, multiplier: 0.5, constant: 0.0)
        self.handLabel.textAlignment = .center
        self.handLabel.text = "✋"
        
        self.footLabel = UILabel()
        self.addSubview(self.footLabel)
        self.footLabel.pin(edge: .trailing, to: .trailing, of: self)
        self.footLabel.pin(edge: .bottom, to: .bottom, of: self)
        self.footLabel.pinWidth(toWidthOf: self, multiplier: 0.5, constant: 0.0)
        self.footLabel.pinHeight(toHeightOf: self, multiplier: 0.5, constant: 0.0)
        self.footLabel.textAlignment = .center
        self.footLabel.text = "🦶"
        
        self.isSelected = false
        self.isDragPlaceholder = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
