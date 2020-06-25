//
//  HandView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

enum HandViewState {
    case idle
    case dragging
    case scrolling
}

class HandView: UIView, Draggable, Droppable {
    
    private static let minCardOverlapProportion = 0.52
    private static let maxCardOverlapProportion = 0.90

    private var borderView: UIView!
    private var cardViews: [CardView]!
    
    weak var dragDelegate: DragDelegate?
    
    private var state: HandViewState!
    private var isDraggingActive: Bool!
    private var minScrollTranslation: CGFloat!
    private var maxScrollTranslation: CGFloat!
    private var scrollTranslation: CGFloat!
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    var selectedCardViews: [CardView] {
        return self.cardViews.filter({ $0.isSelected })
    }
    
    var selectedCards: [Card] {
        return self.selectedCardViews.map({ $0.card! })
    }

    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = .white

        self.borderView = UIView()
        self.addSubview(self.borderView)
        self.borderView.pin(to: self)
        self.borderView.layer.cornerCurve = .continuous
        self.borderView.layer.cornerRadius = 10
        self.borderView.layer.masksToBounds = true
        self.borderView.layer.borderWidth = 1
        self.borderView.layer.borderColor = UIColor.black.cgColor
        
        self.cardViews = []
        self.state = .idle
        self.isDraggingActive = false
        self.minScrollTranslation = 0.0
        self.maxScrollTranslation = 0.0
        self.scrollTranslation = 0.0
        
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(HandView.panGestureRecognizerChanged))
        self.addGestureRecognizer(self.panGestureRecognizer)
    }
    
    func update(cards: [Card]) {
        var cardViewsToKeep = [CardView]()
        var cardsWithoutCardViews = cards
        
        for card in cards {
            if let cardViewIndex = self.cardViews.firstIndex(where: { $0.card! == card}) {
                cardViewsToKeep.append(self.cardViews[cardViewIndex])
                self.cardViews.remove(at: cardViewIndex)
                
                let cardIndex = cardsWithoutCardViews.firstIndex(of: card)!
                cardsWithoutCardViews.remove(at: cardIndex)
            }
        }

        for cardView in self.cardViews {
            cardView.removeFromSuperview()
        }

        self.cardViews = cardViewsToKeep
        for card in cardsWithoutCardViews {
            let cardView = CardView(card: card)
            // TODO: This is kinda hacky to avoid the flying in animation
            cardView.isHidden = true
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(HandView.cardTapGestureRecognizerChanged))
            cardView.addGestureRecognizer(tapGestureRecognizer)
            self.addSubview(cardView)
            
            self.cardViews.append(cardView)
        }
        
        self.cardViews.sort { (cardViewA, cardViewB) -> Bool in
            return cardViewA.card!.rank < cardViewB.card!.rank
        }
    
        for cardView in self.cardViews {
            self.bringSubviewToFront(cardView)
        }

        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        let animationOptions = UIView.AnimationOptions(arrayLiteral: .curveEaseInOut)
        UIView.animate(withDuration: 0.10, delay: 0.0, options: animationOptions, animations: {
            let margin = self.frame.height * 0.05

            let cardHeight = self.frame.height - (margin * 2.0)
            let cardWidth = cardHeight * CGFloat(CardView.aspectRatio)

            let unselectedCardTopEdgeY = (self.frame.height / 2.0) - (cardHeight / 2.0)
            let selectedCardTopEdgeY = unselectedCardTopEdgeY - (self.frame.height * 0.15)
            
            for cardView in self.cardViews {
                if cardView.isSelected || cardView.isDragPlaceholder {
                    cardView.frame = CGRect(x: 0.0, y: selectedCardTopEdgeY, width: cardWidth, height: cardHeight)
                } else {
                    cardView.frame = CGRect(x: 0.0, y: unselectedCardTopEdgeY, width: cardWidth, height: cardHeight)
                }
            }
            
            self.arrangeCards(scrollTranslation: 0.0)
        }, completion: { (_) in
            // TODO: This is kinda hacky to avoid the flying in animation
            for cardView in self.cardViews {
                cardView.isHidden = false
            }
        })
    }
    
    private func arrangeCards(scrollTranslation: CGFloat) {
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
            cardView.frame = cardView.frame.setting(x: firstCardLeadingEdgeX + (maxExposedCardWidth * CGFloat(i)) + self.scrollTranslation + scrollTranslation)
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
    
    @objc func panGestureRecognizerChanged(_ sender: Any) {
        switch (self.state!) {
            case .idle:
                self.determinePanType()
            case .scrolling:
                self.updateScrollPan()
            case .dragging:
                self.updateDragPan()
        }
    }
    
    private func determinePanType() {
        guard self.isDraggingActive && (self.selectedCardViews.count > 0) else {
            self.state = .scrolling
            return
        }
        
        let translation = self.panGestureRecognizer.translation(in: self)

        guard translation.distanceFromOrigin() > 5.0 else {
            return
        }
        
        guard translation.x.magnitude < translation.y.magnitude else {
            self.state = .scrolling
            return
        }
        
        self.state = .dragging
        self.beginDrag()
    }
    
    private func updateScrollPan() {
        let scrollTranslation = self.panGestureRecognizer.translation(in: self).x
        
        switch (self.panGestureRecognizer.state) {
            case .began:
                break
            case .changed:
                self.arrangeCards(scrollTranslation: scrollTranslation)
            case .ended, .cancelled, .failed:
                self.scrollTranslation += scrollTranslation
                self.state = .idle
            default:
                break
        }
    }
    
    private func beginDrag() {
        for cardView in self.selectedCardViews {
            cardView.isDragPlaceholder = true
        }
        
        var cardsWithPoints = [(Card, CGPoint)]()
        for cardView in self.selectedCardViews {
            cardsWithPoints.append((cardView.card!, cardView.center))
        }

        self.dragDelegate?.dragStarted(.hand,
            with: cardsWithPoints,
            and: self.cardViews.first!.frame.size
        )
    }
    
    private func updateDragPan() {
        let location = self.panGestureRecognizer.location(in: self)
        
        switch (self.panGestureRecognizer.state) {
            case .began:
                break
            case .changed:
                self.dragDelegate?.dragMoved(.hand, to: location)
            case .ended, .cancelled, .failed:
                self.dragDelegate?.dragEnded(.hand, at: location) {
                    self.state = .idle
                
                    for cardView in self.cardViews {
                        cardView.isSelected = false
                        cardView.isDragPlaceholder = false
                    }
                
                    self.setNeedsLayout()
                }
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
        
        guard self.isDraggingActive else {
            return
        }
        
        guard self.state != .dragging else {
            return
        }
        
        cardView.isSelected = !cardView.isSelected
        self.setNeedsLayout()
    }
    
    func activateDragging() {
        self.borderView.layer.borderColor = UIColor.systemRed.cgColor
        self.isDraggingActive = true
    }
    
    func deactivateDragging() {
        for cardView in self.cardViews {
            cardView.isSelected = false
        }

        self.setNeedsLayout()

        self.borderView.layer.borderColor = UIColor.black.cgColor
        self.isDraggingActive = false
    }
    
    func activateDropping() {
        self.borderView.layer.borderColor = UIColor.systemRed.cgColor
    }

    func deactivateDropping() {
        self.borderView.layer.borderColor = UIColor.black.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
