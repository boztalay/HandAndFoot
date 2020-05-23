//
//  HandView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class HandView: UIView {
    
    private static let minCardOverlapProportion = 0.50
    private static let maxCardOverlapProportion = 0.90

    private var cardViews: [CardView]!
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    private var translation: CGFloat!

    init() {
        super.init(frame: CGRect.zero)

        self.cardViews = []
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(HandView.panGestureRecognizerUpdated))
        self.translation = 0.0

        self.backgroundColor = .white
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = true;
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        
        self.addGestureRecognizer(self.panGestureRecognizer)
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
        let margin = self.frame.height * 0.05

        let cardHeight = self.frame.height - (margin * 2.0)
        let cardWidth = cardHeight * CGFloat(CardView.aspectRatio)

        let cardTopEdgeY = (self.frame.height / 2.0) - (cardHeight / 2.0)
        
        for cardView in self.cardViews {
            cardView.frame = CGRect(x: 0.0, y: cardTopEdgeY, width: cardWidth, height: cardHeight)
        }
        
        self.arrangeCards()
    }
    
    private func arrangeCards() {
        let margin = self.frame.height * 0.05

        let cardHeight = self.frame.height - (margin * 2.0)
        let cardWidth = cardHeight * CGFloat(CardView.aspectRatio)

        let minExposedCardWidth = cardWidth * CGFloat(1.0 - HandView.maxCardOverlapProportion)
        let maxExposedCardWidth = cardWidth * CGFloat(1.0 - HandView.minCardOverlapProportion)
        
        let maxCardArrangementWidth = self.frame.width - (margin * 2.0)
        let minSpaceNeededForArrangement = CGFloat(self.cardViews.count) * minExposedCardWidth
        
        guard minSpaceNeededForArrangement <= maxCardArrangementWidth else {
            fatalError("Too much sandbagging")
        }
        
        let idealArrangementWidth = (CGFloat(self.cardViews.count - 1) * maxExposedCardWidth) + cardWidth
        let excessArrangementWidth = maxCardArrangementWidth - idealArrangementWidth
        
        if excessArrangementWidth >= 0.0 {
            let firstCardLeadingEdgeX = margin + (excessArrangementWidth / 2.0)

            for (i, cardView) in self.cardViews.enumerated() {
                cardView.frame = CGRect(
                    origin: CGPoint(
                        x: firstCardLeadingEdgeX + (maxExposedCardWidth * CGFloat(i)),
                        y: cardView.frame.origin.y
                    ),
                    size: cardView.frame.size
                )
            }
        } else {
            // TODO
        }
    }
    
    @objc func panGestureRecognizerUpdated(_ sender: Any) {
        print(self.panGestureRecognizer.state.rawValue)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
