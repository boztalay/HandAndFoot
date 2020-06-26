//
//  DeckView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/25/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class DeckView: UIView, UIGestureRecognizerDelegate, Draggable {

    private var cardView: FaceDownCardView!
    
    weak var dragDelegate: DragDelegate?

    private var panGestureRecognizer: UIPanGestureRecognizer!
    
    init() {
        super.init(frame: .zero)
        
        self.cardView = FaceDownCardView()
        self.addSubview(self.cardView)
        self.cardView.pin(to: self)
        
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DeckView.panGestureRecognizerChanged))
        self.panGestureRecognizer.delegate = self
        self.cardView.addGestureRecognizer(self.panGestureRecognizer)
    }
    
    func update(deck: Deck) {
        self.cardView.isSelected = false
        self.cardView.isDragPlaceholder = false
        self.cardView.isHidden = deck.isEmpty
    }

    func activateDragging() {
        self.cardView.isSelected = true
    }

    func setCardsDragged(_ cards: [Card]) {
        self.cardView.isDragPlaceholder = true
    }
    
    @objc func panGestureRecognizerChanged(_ sender: Any) {
        let location = self.panGestureRecognizer.location(in: self)
        
        if self.panGestureRecognizer.state == .began {
            self.dragDelegate?.dragStartedFaceDown(.deck,
                with: self.cardView.center,
                and: self.cardView.frame.size
            )
        } else if self.panGestureRecognizer.state == .changed {
            self.dragDelegate?.dragMoved(.deck, to: location)
        } else if self.panGestureRecognizer.state == .ended || self.panGestureRecognizer.state == .cancelled {
            self.dragDelegate?.dragEnded(.deck, at: location)
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        return self.cardView.isSelected
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
