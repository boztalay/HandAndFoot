//
//  OpponentView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/25/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class OpponentView: UIView {
    
    private var footView: FootView!
    private var opponentHandView: OpponentHandView!
    private var booksView: BooksView!

    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .white
        self.layer.cornerCurve = .continuous
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        
        self.footView = FootView()
        self.addSubview(self.footView)
        self.footView.pin(edge: .leading, to: .leading, of: self, with: 30.0)
        self.footView.pin(edge: .top, to: .top, of: self, with: 30.0)
        self.footView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        
        self.opponentHandView = OpponentHandView()
        self.addSubview(self.opponentHandView)
        self.opponentHandView.pin(edge: .leading, to: .trailing, of: self.footView, with: 20.0)
        self.opponentHandView.pin(edge: .top, to: .top, of: self, with: 30.0)
        self.opponentHandView.pin(edge: .trailing, to: .trailing, of: self, with: -30.0)
        self.opponentHandView.pinHeight(toHeightOf: self.footView)
        
        self.booksView = BooksView()
        self.addSubview(self.booksView)
        self.booksView.pinX(to: self, leading: 30.0, trailing: -30.0)
        self.booksView.pin(edge: .top, to: .bottom, of: self.footView, with: 20.0)
        self.booksView.pin(edge: .bottom, to: .bottom, of: self, with: -30.0)
    }
    
    func update(player: Player, game: Game) {
        self.footView.update(footPresent: !player.isInFoot)
        self.opponentHandView.update(cards: player.hand)
        self.booksView.update(books: player.books[game.round!]!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
