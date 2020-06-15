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
    
    var dragDelegate: DragDelegate?

    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var lastPanGestureTranslation: CGPoint?
    
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
        self.cardView.isHidden = deck.isEmpty
    }

    func activateDragging() {
        self.cardView.isSelected = true
    }
    
    func deactivateDragging() {
        self.cardView.isSelected = false
    }
    
    @objc func panGestureRecognizerChanged(_ sender: Any) {
        if self.panGestureRecognizer.state == .began {
            self.cardView.isDragPlaceholder = true
            self.dragDelegate?.dragStarted(
                from: .deck,
                with: [],
                at: self.cardView.center,
                with: self.cardView.frame.size
            )
            self.lastPanGestureTranslation = .zero
        } else if self.panGestureRecognizer.state == .changed {
            let translation = self.panGestureRecognizer.translation(in: self)
            let delta = CGPoint(
                x: translation.x - self.lastPanGestureTranslation!.x,
                y: translation.y - self.lastPanGestureTranslation!.y
            )
            
            self.dragDelegate?.dragMoved(delta)
            self.lastPanGestureTranslation = translation
        } else if self.panGestureRecognizer.state == .ended || self.panGestureRecognizer.state == .cancelled {
            self.dragDelegate?.dragEnded()
            self.cardView.isDragPlaceholder = false
            self.lastPanGestureTranslation = nil
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        return self.cardView.isSelected
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
