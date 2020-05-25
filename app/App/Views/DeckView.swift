//
//  DeckView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/25/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class DeckView: UIView {

    var deckOutlineView: UIView!
    var deckStatusLabel: UILabel!
    var discardPileCardView: CardView!
    var discardPileEmptyLabel: UILabel!
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        
        self.deckOutlineView = UIView()
        self.addSubview(self.deckOutlineView)
        self.deckOutlineView.pin(edge: .leading, to: .leading, of: self, with: 10.0)
        self.deckOutlineView.pinY(to: self, top: 10.0, bottom: -10.0)
        self.deckOutlineView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        self.deckOutlineView.layer.cornerRadius = 10
        self.deckOutlineView.layer.masksToBounds = true
        self.deckOutlineView.layer.borderWidth = 1
        self.deckOutlineView.layer.borderColor = UIColor.black.cgColor
        
        self.deckStatusLabel = UILabel()
        self.addSubview(self.deckStatusLabel)
        self.deckStatusLabel.centerVertically(in: self.deckOutlineView)
        self.deckStatusLabel.pinX(to: self.deckOutlineView, leading: 2.0, trailing: -2.0)
        self.deckStatusLabel.textAlignment = .center
        
        self.discardPileCardView = CardView()
        self.addSubview(self.discardPileCardView)
        self.discardPileCardView.pin(edge: .leading, to: .trailing, of: self.deckOutlineView, with: 10.0)
        self.discardPileCardView.pinY(to: self, top: 10.0, bottom: -10.0)
        self.discardPileCardView.pin(edge: .trailing, to: .trailing, of: self, with: -10.0)
        self.discardPileCardView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        
        self.discardPileEmptyLabel = UILabel()
        self.addSubview(self.discardPileEmptyLabel)
        self.discardPileEmptyLabel.centerVertically(in: self.discardPileCardView)
        self.discardPileEmptyLabel.pinX(to: self.discardPileCardView, leading: 2.0, trailing: -2.0)
        self.sendSubviewToBack(self.discardPileEmptyLabel)
        self.discardPileEmptyLabel.textAlignment = .center
        self.discardPileEmptyLabel.text = "❌"
    }
    
    func update(deck: Deck, discardPile: [Card]) {
        if deck.isEmpty {
            self.deckStatusLabel.text = "❌"
        } else {
            self.deckStatusLabel.text = "🂠"
        }
        
        if discardPile.count == 0 {
            self.discardPileCardView.isHidden = true
        } else {
            self.discardPileCardView.isHidden = false
            self.discardPileCardView.update(card: discardPile.last!)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
