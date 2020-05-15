//
//  CardView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/21/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class CardView: UIView {
    
    var rankLabel: UILabel!
    var suitLabel: UILabel!
    
    init(card: Card) {
        super.init(frame: CGRect.zero)
        
        self.rankLabel = UILabel()
        self.addSubview(self.rankLabel)
        self.rankLabel.pin(edge: .leading, to: .leading, of: self, with: 5.0)
        self.rankLabel.pin(edge: .trailing, to: .trailing, of: self, with: 5.0)
        self.rankLabel.pin(edge: .top, to: .top, of: self, with: 5.0)
        
        self.suitLabel = UILabel()
        self.addSubview(self.suitLabel)
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
