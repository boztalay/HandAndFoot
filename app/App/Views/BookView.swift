//
//  BookView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/25/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class BookView: UIView {

    private static let cardOverlapProportion = 0.9
    
    private(set) var cardViews: [CardView]!
    private var outlineView: UIView!
    private var rankLabel: UILabel!
    
    init() {
        super.init(frame: .zero)
        
        self.cardViews = []
        self.outlineView = UIView()
        self.rankLabel = UILabel()
    }
    
    func update(rank: CardRank) {
        for cardView in self.cardViews {
            cardView.removeFromSuperview()
        }
        
        self.cardViews = []
        
        self.outlineView = UIView()
        self.addSubview(self.outlineView)
        self.outlineView.pin(to: self)
        self.outlineView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        self.outlineView.backgroundColor = .white
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
    
    func update(book: Book) {
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
            
            lastCardView = cardView
        }
        
        lastCardView!.pin(edge: .bottom, to: .bottom, of: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
