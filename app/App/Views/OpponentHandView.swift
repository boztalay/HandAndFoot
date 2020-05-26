//
//  OpponentHandView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/25/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class OpponentHandView: UIView {
    
    private static let cardOverlapProportion = 0.9

    private var cardViews: [FaceDownCardView]!
    
    init() {
        super.init(frame: .zero)

        self.cardViews = []
    }
    
    func update(cards: [Card]) {
        for cardView in self.cardViews {
            cardView.removeFromSuperview()
        }
        
        self.cardViews = []
        var lastCardView: FaceDownCardView?
        
        for _ in cards {
            let cardView = FaceDownCardView()
            self.addSubview(cardView)
            cardView.pinY(to: self)
            cardView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
            
            if let lastCardView = lastCardView {
                let lastCardViewLeadingToCardViewLeading = lastCardView.leadingAnchor.anchorWithOffset(to: cardView.leadingAnchor)
                let cardViewLeadingToLastCardViewTrailing = cardView.leadingAnchor.anchorWithOffset(to: lastCardView.trailingAnchor)
                cardViewLeadingToLastCardViewTrailing.constraint(equalTo: lastCardViewLeadingToCardViewLeading, multiplier: CGFloat(OpponentHandView.cardOverlapProportion / (1.0 - OpponentHandView.cardOverlapProportion))).isActive = true
            } else {
                cardView.pin(edge: .leading, to: .leading, of: self)
            }
            
            lastCardView = cardView
        }
        
        lastCardView!.pin(edge: .trailing, to: .trailing, of: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
