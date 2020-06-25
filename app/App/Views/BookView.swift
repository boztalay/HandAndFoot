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
        self.rankLabel = UILabel()
    }
    
    func update(rank: CardRank, complexActionCards: [Card]? = nil) {
        self.rank = rank

        for cardView in self.cardViews {
            cardView.removeFromSuperview()
        }
        
        self.cardViews = []
        
        if let complexActionCards = complexActionCards {
            self.outlineView.removeFromSuperview()
            self.rankLabel.removeFromSuperview()
            
            var lastCardView: CardView?
            
            let sortedComplexActionCards = complexActionCards.sorted { (cardA, cardB) -> Bool in
                if cardA.isWild && !cardB.isWild {
                    return true
                } else if !cardA.isWild && cardB.isWild {
                    return false
                } else {
                    return (cardA.rank > cardB.rank)
                }
            }
            
            for card in sortedComplexActionCards {
                lastCardView = self.addCardView(card: card, lastCardView: lastCardView, isComplexActionCard: true)
            }
        } else {
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
            self.rankLabel.text = rank.rawValue
        }
    }
    
    func update(book: Book, complexActionCards: [Card]? = nil) {
        self.rank = book.rank
        
        let sortedCards = book.cards.sorted() { (cardA, cardB) in
            if cardA.isWild && !cardB.isWild {
                return true
            } else if !cardA.isWild && cardB.isWild {
                return false
            } else {
                return (cardA.rank > cardB.rank)
            }
        }
        
        self.outlineView.removeFromSuperview()
        self.rankLabel.removeFromSuperview()
        
        for cardView in self.cardViews {
            cardView.removeFromSuperview()
        }
        
        self.cardViews = []
        var lastCardView: CardView?
        
        for card in sortedCards {
            lastCardView = self.addCardView(card: card, lastCardView: lastCardView, isComplexActionCard: false)
        }
        
        if let complexActionCards = complexActionCards {
            let sortedComplexActionCards = complexActionCards.sorted { (cardA, cardB) -> Bool in
                if cardA.isWild && !cardB.isWild {
                    return true
                } else if !cardA.isWild && cardB.isWild {
                    return false
                } else {
                    return (cardA.rank > cardB.rank)
                }
            }
            
            for card in sortedComplexActionCards {
                lastCardView = self.addCardView(card: card, lastCardView: lastCardView, isComplexActionCard: true)
            }
        }
        
        lastCardView!.pin(edge: .bottom, to: .bottom, of: self)
    }
    
    private func addCardView(card: Card, lastCardView: CardView?, isComplexActionCard: Bool) -> CardView {
        let cardView = CardView(card: card)
        self.cardViews.append(cardView)
        self.addSubview(cardView)

        cardView.pinX(to: self)
        cardView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        
        if let lastCardView = lastCardView {
            let lastCardViewTopToCardViewTop = lastCardView.topAnchor.anchorWithOffset(to: cardView.topAnchor)
            let cardViewTopToLastCardViewBottom = cardView.topAnchor.anchorWithOffset(to: lastCardView.bottomAnchor)
            cardViewTopToLastCardViewBottom.constraint(equalTo: lastCardViewTopToCardViewTop, multiplier: CGFloat(BookView.cardOverlapProportion / (1.0 - BookView.cardOverlapProportion))).isActive = true
        } else {
            cardView.pin(edge: .top, to: .top, of: self)
        }
        
        // TODO: Something better to indicate what's up
        cardView.isDragPlaceholder = isComplexActionCard

        return cardView
    }
    
    func activateDropping() {
        self.isSelected = true
    }
    
    func deactivateDropping() {
        self.isSelected = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
