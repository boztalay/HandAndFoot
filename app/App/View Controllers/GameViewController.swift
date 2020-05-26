//
//  GameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, OpponentPreviewViewDelegate {
    
    private var opponentPreviewViews: [String : OpponentPreviewView]!
    private var footView: FootView!
    private var handView: HandView!
    private var booksContainerView: UIView!
    private var bookViews: [BookView]!
    private var deckView: DeckView!
    
    private var gameModel: GameModel!
    
    init(game: GameModel) {
        super.init(nibName: nil, bundle: nil)
        
        self.opponentPreviewViews = [:]
        self.footView = FootView()
        self.handView = HandView()
        self.booksContainerView = UIView()
        self.bookViews = []
        self.deckView = DeckView()
        
        self.gameModel = game
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = self.gameModel.title!
        
        let game = self.gameModel.game!
        let currentPlayer = game.getPlayer(named: DataManager.shared.currentUser!.email!)!
        
        var lastOpponentPreviewView: OpponentPreviewView?
        
        for player in game.players.filter({ $0.name != currentPlayer.name }) {
            let opponentPreviewView = OpponentPreviewView()
            self.view.addSubview(opponentPreviewView)
            opponentPreviewView.pin(edge: .leading, to: .leading, of: self.view.safeAreaLayoutGuide, with: 40)
            opponentPreviewView.setAspectRatio(to: 1.0)
            opponentPreviewView.pinHeight(toHeightOf: self.view, multiplier: 0.10, constant: 0.0)
            opponentPreviewView.delegate = self
            
            if let lastPlayerPreviewView = lastOpponentPreviewView {
                opponentPreviewView.pin(edge: .top, to: .bottom, of: lastPlayerPreviewView, with: 20)
            } else {
                opponentPreviewView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 40)
            }
            
            self.opponentPreviewViews[player.name] = opponentPreviewView
            
            let user = DataManager.shared.fetchUser(with: player.name)!
            opponentPreviewView.update(user: user, player: player, game: game)
            lastOpponentPreviewView = opponentPreviewView
        }
        
        self.view.addSubview(self.footView)
        self.footView.pin(edge: .leading, to: .leading, of: self.view.safeAreaLayoutGuide, with: 40)
        self.footView.pin(edge: .bottom, to: .bottom, of: self.view.safeAreaLayoutGuide, with: -40)
        self.footView.pinHeight(toHeightOf: self.view, multiplier: 0.2, constant: 0.0)
        self.footView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        self.footView.update(footPresent: !currentPlayer.isInFoot)
        
        self.view.addSubview(self.handView)
        self.handView.pin(edge: .leading, to: .trailing, of: self.footView, with: 30)
        self.handView.pin(edge: .trailing, to: .trailing, of: self.view.safeAreaLayoutGuide, with: -40)
        self.handView.pin(edge: .top, to: .top, of: self.footView)
        self.handView.pin(edge: .bottom, to: .bottom, of: self.view, with: -40)
        self.handView.update(cards: currentPlayer.hand)
        
        self.view.addSubview(self.booksContainerView)
        self.booksContainerView.pinX(to: self.handView)
        self.booksContainerView.pin(edge: .bottom, to: .top, of: self.handView, with: -30)
        
        var lastBookView: BookView?
        var tallestBookView: BookView?
        
        for rank in CardRank.allCases {
            guard rank != .two && rank != .three && rank != .joker else {
                continue
            }
            
            let bookView = BookView()
            self.booksContainerView.addSubview(bookView)
            bookView.pin(edge: .top, to: .top, of: self.booksContainerView)

            if let book = currentPlayer.books[game.round!]![rank] {
                bookView.update(book: book)
            } else {
                bookView.update(rank: rank)
            }
            
            if let lastBookView = lastBookView {
                bookView.pinWidth(toWidthOf: lastBookView)
                bookView.pin(edge: .leading, to: .trailing, of: lastBookView, with: 10.0)

                if rank == .ace {
                    bookView.pin(edge: .trailing, to: .trailing, of: self.booksContainerView)
                }
            } else {
                bookView.pin(edge: .leading, to: .leading, of: self.booksContainerView)
            }
            
            if tallestBookView == nil || bookView.cardViews.count > tallestBookView!.cardViews.count {
                tallestBookView = bookView
            }
            
            lastBookView = bookView
        }
        
        self.booksContainerView.pinHeight(toHeightOf: tallestBookView!)
        
        self.view.addSubview(self.deckView)
        self.deckView.centerHorizontally(in: self.view)
        self.deckView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 100.0)
        self.deckView.pinHeight(toHeightOf: self.view, multiplier: 0.2, constant: 0.0)
        self.deckView.update(deck: game.deck, discardPile: game.discardPile)
    }

    func opponentPreviewViewTapped(player: Player) {
        let opponentView = OpponentView()
        self.view.addSubview(opponentView)
        opponentView.pin(edge: .leading, to: .trailing, of: self.opponentPreviewViews.values.first!, with: 30.0)
        opponentView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 40.0)
        opponentView.pinHeight(toHeightOf: self.view, multiplier: 0.40, constant: 0.0)
        opponentView.pinWidth(toWidthOf: self.view, multiplier: 0.70, constant: 0.0)
        
        opponentView.update(player: player, game: self.gameModel.game!)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
