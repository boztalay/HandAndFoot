//
//  CardView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/21/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class CardView: UIView {
    
    var rankLabel: UILabel
    var suitLabel: UILabel
    
    init(card: Card) {
        self.rankLabel = UILabel()
        self.suitLabel = UILabel()

        super.init(frame: CGRect.zero)
    }
    
    override func layoutSubviews() {
        self.rankLabel.pin(edge: .leading, to: .leading, of: self, with: 5.0)
        self.rankLabel.pin(edge: .trailing, to: .trailing, of: self, with: 5.0)
        self.rankLabel.pin(edge: .top, to: .top, of: self, with: 5.0)
        
        self.suitLabel.pin(edge: .leading, to: .leading, of: self, with: 5.0)
        self.suitLabel.pin(edge: .trailing, to: .trailing, of: self, with: 5.0)
        self.suitLabel.pin(edge: .bottom, to: .bottom, of: self, with: 5.0)
    }
    
    func update(card: Card) {
        self.rankLabel.text = card.rank.rawValue
        self.suitLabel.text = card.suit.rawValue
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}
