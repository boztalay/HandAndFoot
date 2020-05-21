//
//  HandView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class HandView: UIView {
    
    private static let desiredCardOverlapProportion = 0.50
    
    private var cardContainerView: UIView!
    private var cardViews: [CardView]!

    init() {
        super.init(frame: CGRect.zero)

        self.cardContainerView = UIView()
        self.cardViews = []

        self.backgroundColor = .white
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = true;
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
    }
    
    func update(cards: [Card]) {
        for cardView in self.cardViews {
            cardView.removeFromSuperview()
        }
        
        self.cardContainerView.removeFromSuperview()
        self.cardContainerView = UIView()
        self.addSubview(self.cardContainerView)
        self.cardContainerView.pinHeight(toHeightOf: self)
        self.cardContainerView.centerHorizontally(in: self)
        
        self.cardViews = cards.map() { CardView(card: $0) }
        var lastCardView: CardView?
        
        for cardView in self.cardViews {
            self.cardContainerView.addSubview(cardView)
            cardView.pinHeight(toHeightOf: self, multiplier: 0.9, constant: 0.0)
            cardView.centerVertically(in: self)
            
            if let lastCardView = lastCardView {
                let lastCardLeadingToCardLeading = lastCardView.leadingAnchor.anchorWithOffset(to: cardView.leadingAnchor)
                let cardLeadingToLastCardTrailing = cardView.leadingAnchor.anchorWithOffset(to: lastCardView.trailingAnchor)

                let multiplier = CGFloat((1.0 / HandView.desiredCardOverlapProportion) - 1.0)
                lastCardLeadingToCardLeading.constraint(equalTo: cardLeadingToLastCardTrailing, multiplier: multiplier).isActive = true
            } else {
                cardView.pin(edge: .leading, to: .leading, of: self.cardContainerView)
            }
            
            lastCardView = cardView
        }
        
        self.cardViews.last!.pin(edge: .trailing, to: .trailing, of: self.cardContainerView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
