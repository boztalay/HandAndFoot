//
//  HandView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class HandView: UIView {
    
    private static let minCardOverlapProportion = 0.10
    private static let maxCardOverlapProportion = 0.50

    private var cardViews: [CardView]!

    init() {
        super.init(frame: CGRect.zero)

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
        
        self.cardViews = cards.map() { CardView(card: $0) }
        
        for cardView in self.cardViews {
            self.addSubview(cardView)
        }

        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        let cardHeight = self.frame.height * 0.90
        let cardWidth = cardHeight * CGFloat(CardView.aspectRatio)
        
        let totalCardsWidth = ((cardWidth * CGFloat(1.0 - HandView.maxCardOverlapProportion)) * CGFloat(self.cardViews.count - 1)) + cardWidth
        
        let firstCardLeadingEdgeX = (self.frame.width / 2.0) - (totalCardsWidth / 2.0)
        let cardTopEdgeY = (self.frame.height / 2.0) - (cardHeight / 2.0)
        let exposedCardWidthInPoints = cardWidth * CGFloat(HandView.maxCardOverlapProportion)
        
        for (i, cardView) in self.cardViews.enumerated() {
            cardView.frame = CGRect(x: firstCardLeadingEdgeX + (CGFloat(i) * exposedCardWidthInPoints), y: cardTopEdgeY, width: cardWidth, height: cardHeight)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
