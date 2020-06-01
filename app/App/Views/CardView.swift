//
//  CardView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/21/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class CardView: UIView {
    
    static let aspectRatio = (2.5 / 3.5)
    
    var rankLabel: UILabel!
    var suitLabel: UILabel!

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
    
    init(card: Card? = nil) {
        super.init(frame: CGRect.zero)
        self.backgroundColor = .white
        
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        
        self.rankLabel = UILabel()
        self.addSubview(self.rankLabel)
        self.rankLabel.pin(edge: .leading, to: .leading, of: self, with: 10.0)
        self.rankLabel.pin(edge: .trailing, to: .trailing, of: self, with: 10.0)
        self.rankLabel.pin(edge: .top, to: .top, of: self, with: 10.0)
        
        self.suitLabel = UILabel()
        self.addSubview(self.suitLabel)
        self.suitLabel.pin(edge: .leading, to: .leading, of: self, with: 10.0)
        self.suitLabel.pin(edge: .trailing, to: .trailing, of: self, with: 10.0)
        self.suitLabel.pin(edge: .bottom, to: .bottom, of: self, with: -10.0)

        self.isSelected = false
        
        if let card = card {
            self.update(card: card)
        }
    }
    
    func update(card: Card) {
        self.rankLabel.text = card.rank.rawValue
        self.suitLabel.text = card.suit.rawValue
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}
