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
    private var minTranslation: CGFloat!
    private var maxTranslation: CGFloat!
    private var translation: CGFloat!

    init() {
        super.init(frame: CGRect.zero)

        self.cardViews = []
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(HandView.panGestureRecognizerUpdated))
        self.minTranslation = 0.0
        self.maxTranslation = 0.0
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
        
        self.arrangeCards(panTranslation: 0.0)
    }
    
    private func arrangeCards(panTranslation: CGFloat) {
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
        
        // First pass:
        //    - Lay out all of the cards with the minimum amount of overlap,
        //      centered horizontally as a group
        //    - Translate the group according to the given translation
        //    - It's expected that some cards will overrun the bounds
        
        let fullArrangementWidth = (CGFloat(self.cardViews.count - 1) * maxExposedCardWidth) + cardWidth
        let excessWidth = maxCardArrangementWidth - fullArrangementWidth
        let firstCardLeadingEdgeX = margin + (excessWidth / 2.0)

        for (i, cardView) in self.cardViews.enumerated() {
            cardView.frame = cardView.frame.setting(x: firstCardLeadingEdgeX + (maxExposedCardWidth * CGFloat(i)) + self.translation + panTranslation)
        }
        
        // Second pass:
        //    - Move the leftmost card such that it's within the bounds
        //      (including margin)
        //    - If the next card is overlapping that card too much, move it such
        //      that it meets the maximum overlap
        //    - Repeat until the next card is not overlapping too much
        
        var lastCardView: CardView?
        
        for cardView in self.cardViews {
            if let lastCardView = lastCardView {
                let exposedCardWidth = cardView.frame.minX - lastCardView.frame.minX
                if exposedCardWidth < minExposedCardWidth {
                    cardView.frame = cardView.frame.setting(x: lastCardView.frame.minX + minExposedCardWidth)
                }
            } else {
                if cardView.frame.minX < margin {
                    cardView.frame = cardView.frame.setting(x: margin)
                }
            }
            
            lastCardView = cardView
        }

        // Third pass:
        //    - Same as the second pass, but working from the right side
        
        lastCardView = nil
        
        for cardView in self.cardViews.reversed() {
            if let lastCardView = lastCardView {
                let exposedCardWidth = lastCardView.frame.minX - cardView.frame.minX
                if exposedCardWidth < minExposedCardWidth {
                    cardView.frame = cardView.frame.setting(x: lastCardView.frame.minX - minExposedCardWidth)
                }
            } else {
                if cardView.frame.maxX > (self.frame.width - margin) {
                    cardView.frame = cardView.frame.setting(x: (self.frame.width - margin - cardWidth))
                }
            }
            
            lastCardView = cardView
        }
    }
    
    @objc func panGestureRecognizerUpdated(_ sender: Any) {
        let panTranslation = self.panGestureRecognizer.translation(in: self).x
        
        switch (self.panGestureRecognizer.state) {
            case .began:
                break
            case .changed:
                self.arrangeCards(panTranslation: panTranslation)
            case .ended, .cancelled, .failed:
                self.translation += panTranslation
            default:
                break
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
