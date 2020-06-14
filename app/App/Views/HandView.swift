//
//  HandView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

protocol HandViewDelegate: AnyObject {
    func cardSelectionChanged(cards: [Card])
}

class HandView: UIView, Droppable {
    
    private static let minCardOverlapProportion = 0.52
    private static let maxCardOverlapProportion = 0.90

    private var borderView: UIView!
    private var cardViews: [CardView]!

    private var minTranslation: CGFloat!
    private var maxTranslation: CGFloat!
    private var translation: CGFloat!
    
    weak var delegate: HandViewDelegate?

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = .white

        self.borderView = UIView()
        self.addSubview(self.borderView)
        self.borderView.pin(to: self)
        self.borderView.layer.cornerRadius = 10
        self.borderView.layer.masksToBounds = true
        self.borderView.layer.borderWidth = 1
        self.borderView.layer.borderColor = UIColor.black.cgColor
        
        self.cardViews = []
        self.minTranslation = 0.0
        self.maxTranslation = 0.0
        self.translation = 0.0
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(HandView.panGestureRecognizerUpdated))
        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    func update(cards: [Card]) {
        for cardView in self.cardViews {
            cardView.removeFromSuperview()
        }
        
        let sortedCards = cards.sorted() { (cardA, cardB) in
            return cardA.rank < cardB.rank
        }
        
        self.cardViews = sortedCards.map() { CardView(card: $0) }
        
        for cardView in self.cardViews {
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(HandView.cardTapGestureRecognizerChanged))
            cardView.addGestureRecognizer(tapGestureRecognizer)
            self.addSubview(cardView)
        }

        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        let margin = self.frame.height * 0.05

        let cardHeight = self.frame.height - (margin * 2.0)
        let cardWidth = cardHeight * CGFloat(CardView.aspectRatio)

        let unselectedCardTopEdgeY = (self.frame.height / 2.0) - (cardHeight / 2.0)
        let selectedCardTopEdgeY = unselectedCardTopEdgeY - (self.frame.height * 0.15)
        
        for cardView in self.cardViews {
            if cardView.isSelected {
                cardView.frame = CGRect(x: 0.0, y: selectedCardTopEdgeY, width: cardWidth, height: cardHeight)
            } else {
                cardView.frame = CGRect(x: 0.0, y: unselectedCardTopEdgeY, width: cardWidth, height: cardHeight)
            }
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
    
    @objc func panGestureRecognizerUpdated(_ sender: UIPanGestureRecognizer) {
        let panTranslation = sender.translation(in: self).x
        
        switch (sender.state) {
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
    
    @objc func cardTapGestureRecognizerChanged(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        
        guard let cardView = sender.view as? CardView else {
            fatalError()
        }
        
        cardView.isSelected = !cardView.isSelected
        self.setNeedsLayout()
        
        let selectedCards = self.cardViews.filter({ $0.isSelected }).map({ $0.card! })
        self.delegate?.cardSelectionChanged(cards: selectedCards)
    }
    
    func activateDropping(for destination: DragDropSite) {
        self.borderView.layer.borderColor = UIColor.systemRed.cgColor
    }

    func deactivateDropping(for destination: DragDropSite) {
        self.borderView.layer.borderColor = UIColor.black.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
