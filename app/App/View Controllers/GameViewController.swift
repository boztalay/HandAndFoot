//
//  GameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, OpponentPreviewViewDelegate, DeckViewDelegate, HandViewDelegate, BookViewDelegate, ActionMenuViewDelegate {
    
    private var opponentPreviewViews: [String : OpponentPreviewView]!
    private var footView: FootView!
    private var handView: HandView!
    private var booksContainerView: UIView!
    private var bookViews: [CardRank: BookView]!
    private var deckView: DeckView!
    private var actionMenuView: ActionMenuView!
    
    private var lowestOpponentPreviewView: OpponentPreviewView?
    private var dimmerView: UIView?
    private var opponentView: OpponentView?
    private var opponentPlayerName: String?

    private var gameModel: GameModel!

    private var deckSelected: Bool!
    private var discardPileSelected: Bool!
    private var handSelection: [Card]!
    private var bookSelection: CardRank?
    
    private var currentPlayer: Player {
        return self.gameModel.game!.getPlayer(named: DataManager.shared.currentUser!.email!)!
    }
    
    init(gameModel: GameModel) {
        super.init(nibName: nil, bundle: nil)
        
        self.opponentPreviewViews = [:]
        self.footView = FootView()
        self.handView = HandView()
        self.booksContainerView = UIView()
        self.bookViews = [:]
        self.deckView = DeckView()
        self.actionMenuView = ActionMenuView()

        self.gameModel = gameModel
        
        self.deckSelected = false
        self.discardPileSelected = false
        self.handSelection = []
        self.bookSelection = nil
        
        self.actionMenuView.update(
            playerName: self.currentPlayer.name,
            deckSelected: self.deckSelected,
            discardPileSelected: self.discardPileSelected,
            handSelection: self.handSelection,
            bookSelection: self.bookSelection
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = self.gameModel.title!
        
        let game = self.gameModel.game!
        var lastOpponentPreviewView: OpponentPreviewView?
        
        for player in game.players.filter({ $0.name != self.currentPlayer.name }) {
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
            if self.lowestOpponentPreviewView == nil {
                self.lowestOpponentPreviewView = opponentPreviewView
            }

            lastOpponentPreviewView = opponentPreviewView
        }
        
        self.view.insertSubview(self.footView, belowSubview: self.lowestOpponentPreviewView!)
        self.footView.pin(edge: .leading, to: .leading, of: self.view.safeAreaLayoutGuide, with: 40)
        self.footView.pin(edge: .bottom, to: .bottom, of: self.view.safeAreaLayoutGuide, with: -40)
        self.footView.pinHeight(toHeightOf: self.view, multiplier: 0.2, constant: 0.0)
        self.footView.setAspectRatio(to: CGFloat(CardView.aspectRatio))

        self.view.insertSubview(self.handView, belowSubview: self.lowestOpponentPreviewView!)
        self.handView.pin(edge: .leading, to: .trailing, of: self.footView, with: 30)
        self.handView.pin(edge: .trailing, to: .trailing, of: self.view.safeAreaLayoutGuide, with: -40)
        self.handView.pin(edge: .top, to: .top, of: self.footView)
        self.handView.pin(edge: .bottom, to: .bottom, of: self.view, with: -40)
        self.handView.delegate = self
        
        self.view.insertSubview(self.booksContainerView, belowSubview: self.lowestOpponentPreviewView!)
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
            bookView.delegate = self
            
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
            
            self.bookViews[rank] = bookView
            lastBookView = bookView
        }
        
        self.booksContainerView.pinHeight(toHeightOf: tallestBookView!)

        self.view.insertSubview(self.deckView, belowSubview: self.lowestOpponentPreviewView!)
        self.deckView.centerHorizontally(in: self.view)
        self.deckView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 100.0)
        self.deckView.pinHeight(toHeightOf: self.view, multiplier: 0.2, constant: 0.0)
        self.deckView.delegate = self
        
        self.view.insertSubview(self.actionMenuView, belowSubview: self.lowestOpponentPreviewView!)
        self.actionMenuView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 40.0)
        self.actionMenuView.pin(edge: .trailing, to: .trailing, of: self.view.safeAreaLayoutGuide, with: -40.0)
        self.actionMenuView.pin(edge: .bottom, to: .top, of: self.booksContainerView, with: -30.0)
        self.actionMenuView.pinWidth(toWidthOf: self.view, multiplier: 0.25, constant: 0.0)
        self.actionMenuView.delegate = self
        
        self.updateViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Network.shared.subscribeToSyncEvents(label: "GameViewController") {
            self.gameModel.loadGame()
            self.updateViews()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Network.shared.unsubscribeFromSyncEvents(label: "GameViewController")
    }
    
    func updateViews() {
        let game = self.gameModel.game!
        
        for (playerName, opponentPreviewView) in self.opponentPreviewViews {
            let user = DataManager.shared.fetchUser(with: playerName)!
            let player = game.players.filter({ $0.name == playerName }).first!
            opponentPreviewView.update(user: user, player: player, game: game)
        }
        
        self.footView.update(footPresent: !self.currentPlayer.isInFoot)
        self.handView.update(cards: self.currentPlayer.hand)
        
        for rank in CardRank.allCases {
            guard rank != .two && rank != .three && rank != .joker else {
                continue
            }
            
            let bookView = self.bookViews[rank]!

            if let book = self.currentPlayer.books[game.round!]![rank] {
                bookView.update(book: book)
            } else {
                bookView.update(rank: rank)
            }
        }
        
        self.deckView.update(deck: game.deck, discardPile: game.discardPile)
        
        if let opponentPlayerName = self.opponentPlayerName {
            let opponentPlayer = game.getPlayer(named: opponentPlayerName)!
            self.opponentView!.update(player: opponentPlayer, game: game)
        }
    }

    func opponentPreviewViewTapped(player: Player) {
        if self.opponentView == nil {
            self.dimmerView = UIView()
            self.view.insertSubview(self.dimmerView!, belowSubview: self.lowestOpponentPreviewView!)
            self.dimmerView!.pin(to: self.view.safeAreaLayoutGuide)
            self.dimmerView!.backgroundColor = .black
            self.dimmerView!.alpha = 0.5

            let dimmerViewTapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(GameViewController.dimmerViewTapped))
            self.dimmerView!.addGestureRecognizer(dimmerViewTapGestureRecognizer)
            
            self.opponentView = OpponentView()
            self.view.insertSubview(self.opponentView!, aboveSubview: self.dimmerView!)
            self.opponentView!.pin(edge: .leading, to: .trailing, of: self.opponentPreviewViews.values.first!, with: 30.0)
            self.opponentView!.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 40.0)
            self.opponentView!.pin(edge: .trailing, to: .trailing, of: self.view.safeAreaLayoutGuide, with: -40.0)
        }
        
        self.opponentView!.update(player: player, game: self.gameModel.game!)
        self.opponentPlayerName = player.name
    }
    
    @objc func dimmerViewTapped(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }

        self.opponentView?.removeFromSuperview()
        self.opponentView = nil
        self.opponentPlayerName = nil

        self.dimmerView?.removeFromSuperview()
        self.dimmerView = nil
    }
    
    func deckSelectionChanged(selected: Bool) {
        self.deckSelected = selected

        self.actionMenuView.update(
            playerName: self.currentPlayer.name,
            deckSelected: self.deckSelected,
            discardPileSelected: self.discardPileSelected,
            handSelection: self.handSelection,
            bookSelection: self.bookSelection
        )
    }

    func discardPileSelectionChanged(selected: Bool) {
        self.discardPileSelected = selected

        self.actionMenuView.update(
            playerName: self.currentPlayer.name,
            deckSelected: self.deckSelected,
            discardPileSelected: self.discardPileSelected,
            handSelection: self.handSelection,
            bookSelection: self.bookSelection
        )
    }
    
    func cardSelectionChanged(cards: [Card]) {
        self.handSelection = cards

        self.actionMenuView.update(
            playerName: self.currentPlayer.name,
            deckSelected: self.deckSelected,
            discardPileSelected: self.discardPileSelected,
            handSelection: self.handSelection,
            bookSelection: self.bookSelection
        )
    }
    
    func bookSelectionChanged(rank: CardRank, isSelected: Bool) {
        for (bookViewRank, bookView) in self.bookViews {
            if bookViewRank != rank {
                bookView.isSelected = false
            }
        }
        
        if isSelected {
            self.bookSelection = rank
        } else {
            self.bookSelection = nil
        }

        self.actionMenuView.update(
            playerName: self.currentPlayer.name,
            deckSelected: self.deckSelected,
            discardPileSelected: self.discardPileSelected,
            handSelection: self.handSelection,
            bookSelection: self.bookSelection
        )
    }
    
    func actionSelected(_ action: Action) {
        print("Action selected: \(action)")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
