//
//  BookView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/25/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class BookView: UIView, Droppable {

    private static let cardOverlapProportion = 0.9
    
    private(set) var cardViews: [CardView]!
    private var outlineView: UIView!
    private var rankLabel: UILabel!
    
    private var rank: CardRank!
    private var cards: [Card]?
    private var placeholderCards: [Card]?
    
    var isSelected: Bool {
        get {
            return self.outlineView.layer.borderColor == UIColor.systemRed.cgColor
        }
        set {
            if newValue {
                self.outlineView.layer.borderColor = UIColor.systemRed.cgColor
            } else {
                self.outlineView.layer.borderColor = UIColor.black.cgColor
            }
            
            for cardView in self.cardViews {
                cardView.isSelected = newValue
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.cardViews = []

        self.outlineView = UIView()
        self.addSubview(self.outlineView)
        self.outlineView.pin(to: self)
        self.outlineView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        self.outlineView.backgroundColor = .white
        self.outlineView.layer.cornerCurve = .continuous
        self.outlineView.layer.cornerRadius = 10;
        self.outlineView.layer.masksToBounds = true
        self.outlineView.layer.borderWidth = 1
        self.outlineView.layer.borderColor = UIColor.black.cgColor

        self.rankLabel = UILabel()
        self.addSubview(self.rankLabel)
        self.rankLabel.centerVertically(in: self)
        self.rankLabel.pinX(to: self, leading: 2.0, trailing: -2.0)
        self.rankLabel.textAlignment = .center
    }
    
    func update(rank: CardRank, cards: [Card]?) {
        self.rank = rank
        self.cards = cards

        for cardView in self.cardViews {
            cardView.removeFromSuperview()
        }
        
        self.cardViews = []
        self.outlineView.isHidden = true
        self.rankLabel.isHidden = true
        
        if self.cards == nil && self.placeholderCards == nil {
            self.outlineView.isHidden = false
            self.rankLabel.isHidden = false
            self.rankLabel.text = rank.rawValue
        } else {
            var lastCardView: CardView?
            
            if let cards = self.cards {
                for card in self.sortCards(cards) {
                    lastCardView = self.addCardView(card: card, lastCardView: lastCardView, isPlaceholder: false)
                }
            }
            
            if let cards = self.placeholderCards {
                for card in self.sortCards(cards) {
                    lastCardView = self.addCardView(card: card, lastCardView: lastCardView, isPlaceholder: true)
                }
            }
            
            lastCardView!.pin(edge: .bottom, to: .bottom, of: self)
        }
    }
    
    private func sortCards(_ cards: [Card]) -> [Card] {
        return cards.sorted() { (cardA, cardB) in
            if cardA.isWild && !cardB.isWild {
                return true
            } else if !cardA.isWild && cardB.isWild {
                return false
            } else {
                return (cardA.rank > cardB.rank)
            }
        }
    }
    
    private func addCardView(card: Card, lastCardView: CardView?, isPlaceholder: Bool) -> CardView {
        let cardView = CardView(card: card)
        self.cardViews.append(cardView)
        self.addSubview(cardView)

        cardView.pinX(to: self)
        cardView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        cardView.isDragPlaceholder = isPlaceholder
        
        if let lastCardView = lastCardView {
            let lastCardViewTopToCardViewTop = lastCardView.topAnchor.anchorWithOffset(to: cardView.topAnchor)
            let cardViewTopToLastCardViewBottom = cardView.topAnchor.anchorWithOffset(to: lastCardView.bottomAnchor)
            cardViewTopToLastCardViewBottom.constraint(equalTo: lastCardViewTopToCardViewTop, multiplier: CGFloat(BookView.cardOverlapProportion / (1.0 - BookView.cardOverlapProportion))).isActive = true
        } else {
            cardView.pin(edge: .top, to: .top, of: self)
        }

        return cardView
    }
    
    func setDropState(_ state: DropState, with cards: [Card]?) {
        switch state {
            case .disabled:
                self.isSelected = false
            case .enabled:
                self.isSelected = true
        }
        
        self.placeholderCards = cards
        self.update(rank: self.rank, cards: self.cards)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
