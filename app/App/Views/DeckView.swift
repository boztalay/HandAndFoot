//
//  DeckView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/25/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class DeckView: UIView, Draggable, Droppable {

    private var deckCardView: FaceDownCardView!
    private var discardPileCardView: CardView!
    private var discardPileEmptyLabel: UILabel!
    
    var dragDelegate: DragDelegate?
    
    private var discardPile: [Card]!
    private var deckPanGestureRecognizer: UIPanGestureRecognizer!
    private var discardPilePanGestureRecognizer: UIPanGestureRecognizer!
    private var lastPanGestureTranslation: CGPoint?
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        
        self.deckCardView = FaceDownCardView()
        self.addSubview(self.deckCardView)
        self.deckCardView.pin(edge: .leading, to: .leading, of: self, with: 10.0)
        self.deckCardView.pinY(to: self, top: 10.0, bottom: -10.0)
        self.deckCardView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        
        self.discardPileCardView = CardView()
        self.addSubview(self.discardPileCardView)
        self.discardPileCardView.pin(edge: .leading, to: .trailing, of: self.deckCardView, with: 10.0)
        self.discardPileCardView.pinY(to: self, top: 10.0, bottom: -10.0)
        self.discardPileCardView.pin(edge: .trailing, to: .trailing, of: self, with: -10.0)
        self.discardPileCardView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        
        self.discardPileEmptyLabel = UILabel()
        self.addSubview(self.discardPileEmptyLabel)
        self.discardPileEmptyLabel.centerVertically(in: self.discardPileCardView)
        self.discardPileEmptyLabel.pinX(to: self.discardPileCardView, leading: 2.0, trailing: -2.0)
        self.sendSubviewToBack(self.discardPileEmptyLabel)
        self.discardPileEmptyLabel.textAlignment = .center
        self.discardPileEmptyLabel.text = ""
        
        self.deckPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DeckView.deckPanGestureRecognizerChanged))
        self.deckCardView.addGestureRecognizer(self.deckPanGestureRecognizer)
        
        self.discardPilePanGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DeckView.discardPilePanGestureRecognizerChanged))
        self.discardPileCardView.addGestureRecognizer(self.discardPilePanGestureRecognizer)
    }
    
    func update(deck: Deck, discardPile: [Card]) {
        self.discardPile = discardPile
        self.deckCardView.isHidden = deck.isEmpty
        
        if discardPile.count == 0 {
            self.discardPileCardView.isHidden = true
        } else {
            self.discardPileCardView.isHidden = false
            self.discardPileCardView.update(card: self.discardPile.last!)
        }
    }
    
    @objc func deckPanGestureRecognizerChanged(_ sender: Any) {
        if self.deckPanGestureRecognizer.state == .began {
            self.deckCardView.isDragPlaceholder = true
            self.dragDelegate?.dragStarted(
                from: .deck,
                with: [],
                at: self.deckCardView.center,
                with: self.deckCardView.frame.size
            )
            self.lastPanGestureTranslation = .zero
        } else if self.deckPanGestureRecognizer.state == .changed {
            let translation = self.deckPanGestureRecognizer.translation(in: self)
            let delta = CGPoint(
                x: translation.x - self.lastPanGestureTranslation!.x,
                y: translation.y - self.lastPanGestureTranslation!.y
            )
            
            self.dragDelegate?.dragMoved(delta)
            self.lastPanGestureTranslation = translation
        } else if self.deckPanGestureRecognizer.state == .ended || self.deckPanGestureRecognizer.state == .cancelled {
            self.dragDelegate?.dragEnded()
            self.deckCardView.isDragPlaceholder = false
            self.lastPanGestureTranslation = nil
        }
    }

    @objc func discardPilePanGestureRecognizerChanged(_ sender: Any) {
        if self.discardPilePanGestureRecognizer.state == .began {
            self.discardPileCardView.isDragPlaceholder = true
            self.dragDelegate?.dragStarted(
                from: .discardPile,
                with: [self.discardPile.last!],
                at: self.discardPileCardView.center,
                with: self.discardPileCardView.frame.size
            )
            self.lastPanGestureTranslation = .zero
        } else if self.discardPilePanGestureRecognizer.state == .changed {
           let translation = self.discardPilePanGestureRecognizer.translation(in: self)
           let delta = CGPoint(
               x: translation.x - self.lastPanGestureTranslation!.x,
               y: translation.y - self.lastPanGestureTranslation!.y
           )
           
           self.dragDelegate?.dragMoved(delta)
           self.lastPanGestureTranslation = translation
       } else if self.discardPilePanGestureRecognizer.state == .ended {
           self.dragDelegate?.dragEnded()
           self.discardPileCardView.isDragPlaceholder = false
           self.lastPanGestureTranslation = nil
       }
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === self.deckPanGestureRecognizer {
            return self.deckCardView.isSelected
        } else if gestureRecognizer === self.discardPilePanGestureRecognizer {
            return self.discardPileCardView.isSelected
        } else {
            return super.gestureRecognizerShouldBegin(gestureRecognizer)
        }
    }
    
    func activateDragging(for source: DragDropSite) {
        switch (source) {
            case .deck:
                self.deckCardView.isSelected = true
            case .discardPile:
                self.discardPileCardView.isSelected = true
            default:
                fatalError()
        }
    }
    
    func deactivateDragging(for source: DragDropSite) {
        switch (source) {
            case .deck:
                self.deckCardView.isSelected = false
            case .discardPile:
                self.discardPileCardView.isSelected = false
            default:
                fatalError()
        }
    }
    
    func activateDropping(for destination: DragDropSite) {
        guard destination == .discardPile else {
            fatalError()
        }
        
        self.discardPileEmptyLabel.text = "👇"
        self.discardPileCardView.isSelected = true
    }
    
    func deactivateDropping(for destination: DragDropSite) {
        guard destination == .discardPile else {
            fatalError()
        }
        
        self.discardPileEmptyLabel.text = ""
        self.discardPileCardView.isSelected = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
