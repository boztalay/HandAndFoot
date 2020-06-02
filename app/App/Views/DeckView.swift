//
//  DeckView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/25/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

protocol DeckViewDelegate: AnyObject {
    func deckSelectionChanged(selected: Bool)
    func discardPileSelectionChanged(selected: Bool)
}

class DeckView: UIView {

    private var deckCardView: FaceDownCardView!
    private var discardPileCardView: CardView!
    private var discardPileEmptyLabel: UILabel!
    
    weak var delegate: DeckViewDelegate?
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        
        self.deckCardView = FaceDownCardView()
        self.addSubview(self.deckCardView)
        self.deckCardView.pin(edge: .leading, to: .leading, of: self, with: 10.0)
        self.deckCardView.pinY(to: self, top: 10.0, bottom: -10.0)
        self.deckCardView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        
        self.discardPileCardView = CardView()
        self.addSubview(self.discardPileCardView)
        self.discardPileCardView.pin(edge: .leading, to: .trailing, of: self.deckCardView, with: 10.0)
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
        
        let deckTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DeckView.deckTapGestureRecognizerChanged))
        self.deckCardView.addGestureRecognizer(deckTapGestureRecognizer)
        
        let discardPileTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DeckView.discardPileTapGestureRecognizerChanged))
        self.discardPileCardView.addGestureRecognizer(discardPileTapGestureRecognizer)
    }
    
    func update(deck: Deck, discardPile: [Card]) {
        self.deckCardView.isHidden = deck.isEmpty
        
        if discardPile.count == 0 {
            self.discardPileCardView.isHidden = true
        } else {
            self.discardPileCardView.isHidden = false
            self.discardPileCardView.update(card: discardPile.last!)
        }
    }
    
    @objc func deckTapGestureRecognizerChanged(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }

        self.deckCardView.isSelected = !self.deckCardView.isSelected
        self.delegate?.deckSelectionChanged(selected: self.deckCardView.isSelected)
    }
    
    @objc func discardPileTapGestureRecognizerChanged(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        
        guard !self.discardPileCardView.isHidden else {
            return
        }

        self.discardPileCardView.isSelected = !self.discardPileCardView.isSelected
        self.delegate?.discardPileSelectionChanged(selected: self.discardPileCardView.isSelected)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
