//
//  BookPlaceholderView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/29/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class BookPlaceholderView: UIView {
    
    private var rankLabel: UILabel!
    
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
    
    init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        self.layer.cornerCurve = .continuous
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        
        self.rankLabel = UILabel()
        self.addSubview(self.rankLabel)
        self.rankLabel.pin(to: self)
        self.rankLabel.textAlignment = .center
    }
    
    func update(rank: CardRank) {
        self.rankLabel.text = rank.rawValue
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
