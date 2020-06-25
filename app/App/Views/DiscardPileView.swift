//
//  DiscardPileView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/14/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class DiscardPileView: UIView, UIGestureRecognizerDelegate, Draggable, Droppable {

    private var cardView: CardView!
    private var emptyLabel: UILabel!

    weak var dragDelegate: DragDelegate?

    private var discardPile: [Card]!
    private var panGestureRecognizer: UIPanGestureRecognizer!

    init() {
        super.init(frame: .zero)

        self.cardView = CardView()
        self.addSubview(self.cardView)
        self.cardView.pin(to: self)
        self.cardView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        
        self.emptyLabel = UILabel()
        self.addSubview(self.emptyLabel)
        self.sendSubviewToBack(self.emptyLabel)
        self.emptyLabel.centerVertically(in: self)
        self.emptyLabel.pinX(to: self, leading: 2.0, trailing: -2.0)
        self.emptyLabel.textAlignment = .center
        self.emptyLabel.text = ""
        
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DiscardPileView.panGestureRecognizerChanged))
        self.panGestureRecognizer.delegate = self
        self.cardView.addGestureRecognizer(self.panGestureRecognizer)
    }
    
    func update(discardPile: [Card]) {
        self.discardPile = discardPile
        
        if discardPile.count == 0 {
            self.cardView.isHidden = true
        } else {
            self.cardView.isHidden = false
            self.cardView.update(card: self.discardPile.last!)
        }
    }
    
    func activateDragging() {
        self.cardView.isSelected = true
    }
    
    func deactivateDragging() {
        self.cardView.isSelected = false
    }

    func activateDropping() {
        self.emptyLabel.text = "👇"
        self.cardView.isSelected = true
    }
    
    func deactivateDropping() {
        self.emptyLabel.text = "❌"
        self.cardView.isSelected = false
    }
    
    @objc func panGestureRecognizerChanged(_ sender: Any) {
        let location = self.panGestureRecognizer.location(in: self)
        
        if self.panGestureRecognizer.state == .began {
            self.cardView.isDragPlaceholder = true
            self.dragDelegate?.dragStarted(.discardPile,
                with: [(self.discardPile.last!, self.cardView.center)],
                and: self.cardView.frame.size
            )
        } else if self.panGestureRecognizer.state == .changed {
            self.dragDelegate?.dragMoved(.discardPile, to: location)
        } else if self.panGestureRecognizer.state == .ended {
            self.dragDelegate?.dragEnded(.discardPile, at: location) {
                self.cardView.isDragPlaceholder = false
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        return self.cardView.isSelected
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
