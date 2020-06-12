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
    private var deckDragGestureRecognizer: UILongPressGestureRecognizer!
    private var discardPileDragGestureRecognizer: UILongPressGestureRecognizer!
    
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
        
        self.deckDragGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DeckView.deckDragGestureRecognizerChanged))
        self.deckCardView.addGestureRecognizer(self.deckDragGestureRecognizer)
        
        self.discardPileDragGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DeckView.discardPileDragGestureRecognizerChanged))
        self.discardPileCardView.addGestureRecognizer(self.discardPileDragGestureRecognizer)
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
    
    @objc func deckDragGestureRecognizerChanged(_ sender: Any) {
        if self.deckDragGestureRecognizer.state == .began {
            self.deckCardView.isDragPlaceholder = true
            self.dragDelegate?.dragStarted(from: .deck, with: [])
            self.deckDragGestureRecognizer.cancel()
        }
    }

    @objc func discardPileDragGestureRecognizerChanged(_ sender: Any) {
        if self.discardPileDragGestureRecognizer.state == .began {
            self.discardPileCardView.isDragPlaceholder = true
            self.dragDelegate?.dragStarted(from: .discardPile, with: [self.discardPile.last!])
            self.discardPileDragGestureRecognizer.cancel()
        }
    }
    
    func activateDragging(for source: DragDropSite) {
        switch (source) {
            case .deck:
                self.deckDragGestureRecognizer.isEnabled = true
                self.deckCardView.isSelected = true
            case .discardPile:
                self.discardPileDragGestureRecognizer.isEnabled = true
                self.discardPileCardView.isSelected = true
            default:
                fatalError()
        }
    }
    
    func deactivateDragging(for source: DragDropSite) {
        switch (source) {
            case .deck:
                self.deckDragGestureRecognizer.isEnabled = false
                self.deckCardView.isSelected = false
            case .discardPile:
                self.discardPileDragGestureRecognizer.isEnabled = false
                self.discardPileCardView.isSelected = false
            default:
                fatalError()
        }
    }
    
    func dragDone() {
        self.deckCardView.isDragPlaceholder = false
        self.discardPileCardView.isDragPlaceholder = false
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
