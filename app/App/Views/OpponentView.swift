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
    private var bookViews: [CardRank : BookView]!

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
        
        self.bookViews = [:]
        var lastBookView: BookView?
        var tallestBookView: BookView?
        
        for rank in CardRank.allCases {
            guard rank != .two && rank != .three && rank != .joker else {
                continue
            }
            
            let bookView = BookView()
            self.bookViews[rank] = bookView
            self.addSubview(bookView)
            bookView.pin(edge: .top, to: .bottom, of: self.footView, with: 20.0)
            
            if let lastBookView = lastBookView {
                bookView.pinWidth(toWidthOf: lastBookView)
                bookView.pin(edge: .leading, to: .trailing, of: lastBookView, with: 5.0)

                if rank == .ace {
                    bookView.pin(edge: .trailing, to: .trailing, of: self, with: -30.0)
                }
            } else {
                bookView.pin(edge: .leading, to: .leading, of: self, with: 30.0)
            }
            
            if tallestBookView == nil || bookView.cardViews.count > tallestBookView!.cardViews.count {
                tallestBookView = bookView
            }
            
            lastBookView = bookView
        }
        
        tallestBookView!.pin(edge: .bottom, to: .bottom, of: self, with: -30.0)
        self.footView.pinWidth(toWidthOf: lastBookView!)
    }
    
    func update(player: Player, game: Game) {
        self.footView.update(footPresent: !player.isInFoot)
        self.opponentHandView.update(cards: player.hand)
        
        for rank in CardRank.allCases {
            guard rank != .two && rank != .three && rank != .joker else {
                continue
            }
            
            let bookView = self.bookViews[rank]!

            if let book = player.books[game.round!]![rank] {
                bookView.update(book: book)
            } else {
                bookView.update(rank: rank)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
