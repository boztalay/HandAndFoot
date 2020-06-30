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
    
    private var cardViews: [CardView]?
    private var bookPlaceholderView: BookPlaceholderView?
    
    private var rank: CardRank!
    private var cards: [Card]?
    private var placeholderCards: [Card]?
    
    var cardViewCount: Int {
        if let cardViews = self.cardViews {
            return cardViews.count
        } else {
            return 0
        }
    }
    
    var isSelected: Bool {
        get {
            if let cardViews = self.cardViews {
                return cardViews.first!.isSelected
            } else if let bookPlaceholderView = self.bookPlaceholderView {
                return bookPlaceholderView.isSelected
            } else {
                return false
            }
        }
        set {
            if let cardViews = self.cardViews {
                for cardView in cardViews {
                    cardView.isSelected = newValue
                }
            }
            
            self.bookPlaceholderView?.isSelected = newValue
        }
    }
    
    init() {
        super.init(frame: .zero)
    }
    
    func update(rank: CardRank, cards: [Card]?) {
        self.rank = rank
        self.cards = cards

        if let cardViews = self.cardViews {
            for cardView in cardViews {
                cardView.removeFromSuperview()
            }
        }
        
        self.bookPlaceholderView?.removeFromSuperview()

        self.cardViews = nil
        self.bookPlaceholderView = nil
        
        if self.cards == nil && self.placeholderCards == nil {
            let bookPlaceholderView = BookPlaceholderView()
            self.addSubview(bookPlaceholderView)
            bookPlaceholderView.pin(to: self)
            bookPlaceholderView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
            bookPlaceholderView.update(rank: self.rank)
            self.bookPlaceholderView = bookPlaceholderView
        } else {
            self.cardViews = []
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
        self.cardViews!.append(cardView)
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
        self.placeholderCards = cards
        self.update(rank: self.rank, cards: self.cards)
        
        switch state {
            case .disabled:
                self.isSelected = false
            case .enabled:
                self.isSelected = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
