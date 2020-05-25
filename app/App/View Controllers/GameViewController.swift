//
//  GameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {
    
    private var playerPreviewViews: [String : PlayerPreviewView]!
    private var footView: FootView!
    private var handView: HandView!
    private var booksContainerView: UIView!
    private var bookViews: [BookView]!
    private var deckView: DeckView!
    
    private var gameModel: GameModel!
    
    init(game: GameModel) {
        super.init(nibName: nil, bundle: nil)
        
        self.playerPreviewViews = [:]
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
        
        var lastPlayerPreviewView: PlayerPreviewView?
        
        for player in game.players.filter({ $0.name != currentPlayer.name }) {
            let playerPreviewView = PlayerPreviewView()
            self.view.addSubview(playerPreviewView)
            playerPreviewView.pin(edge: .leading, to: .leading, of: self.view.safeAreaLayoutGuide, with: 40)
            playerPreviewView.setAspectRatio(to: 1.0)
            playerPreviewView.pinHeight(toHeightOf: self.view, multiplier: 0.10, constant: 0.0)
            
            if let lastPlayerPreviewView = lastPlayerPreviewView {
                playerPreviewView.pin(edge: .top, to: .bottom, of: lastPlayerPreviewView, with: 20)
            } else {
                playerPreviewView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 40)
            }
            
            let user = DataManager.shared.fetchUser(with: player.name)!
            playerPreviewView.update(user: user, player: player, game: game)
            lastPlayerPreviewView = playerPreviewView
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
            
            if rank == .five {
                let book = try! Book(initialCards: [
                    Card(suit: .diamonds, rank: .two),
                    Card(suit: .spades, rank: .joker),
                    Card(suit: .spades, rank: .five),
                    Card(suit: .clubs, rank: .five),
                    Card(suit: .clubs, rank: .five)
                ])
                
                bookView.update(book: book)
            } else if rank == .eight {
                let book = try! Book(initialCards: [
                    Card(suit: .spades, rank: .eight),
                    Card(suit: .clubs, rank: .eight),
                    Card(suit: .clubs, rank: .eight)
                ])
                
                bookView.update(book: book)
            } else {
                if let book = currentPlayer.books[game.round!]![rank] {
                    bookView.update(book: book)
                } else {
                    bookView.update(rank: rank)
                }
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
