//
//  GameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

enum DragDropTransactionEndpoint: Hashable {
    case deck
    case discardPile
    case existingBook
    case newBook
    case hand
}

struct DragDropTransaction {
    let source: DragDropTransactionEndpoint
    let destination: DragDropTransactionEndpoint
    let cards: [Card]
}

struct ActiveDragDropTransaction {
    let source: DragDropTransactionEndpoint
    let cards: [Card]
}

enum PossibleAction: Hashable, CaseIterable {
    case drawFromDeck
    case drawFromDiscardPileAndAddToBook
    case drawFromDiscardPileAndCreateBook
    case discardCard
    case layDownInitialBooks
    case drawFromDiscardPileAndLayDownInitialBooks
    case startBook
    case addCardFromHandToBook
    
    var dragDropSources: [DragDropTransactionEndpoint] {
        switch (self) {
            case .drawFromDeck:
                return [.deck]
            case .drawFromDiscardPileAndAddToBook:
                return [.discardPile]
            case .drawFromDiscardPileAndCreateBook:
                return [.discardPile]
            case .discardCard:
                return [.hand]
            case .layDownInitialBooks:
                return [.hand]
            case .drawFromDiscardPileAndLayDownInitialBooks:
                return [.discardPile, .hand]
            case .startBook:
                return [.hand]
            case .addCardFromHandToBook:
                return [.hand]
        }
    }
    
    var dragDropDestinations: [DragDropTransactionEndpoint] {
        switch (self) {
            case .drawFromDeck:
                return [.hand]
            case .drawFromDiscardPileAndAddToBook:
                return [.existingBook]
            case .drawFromDiscardPileAndCreateBook:
                return [.newBook]
            case .discardCard:
                return [.discardPile]
            case .layDownInitialBooks:
                return [.newBook]
            case .drawFromDiscardPileAndLayDownInitialBooks:
                return [.newBook]
            case .startBook:
                return [.newBook]
            case .addCardFromHandToBook:
                return [.existingBook]
        }
    }
    
    func isDisqualifiedBy(dragDropSource: DragDropTransactionEndpoint) -> Bool {
        // TODO: I'm sure this is incomplete
        
        switch (self) {
            case .drawFromDeck:
                return dragDropSource != .deck
            case .drawFromDiscardPileAndAddToBook:
                return dragDropSource != .discardPile
            case .drawFromDiscardPileAndCreateBook:
                return dragDropSource != .discardPile
            case .discardCard:
                return dragDropSource != .hand
            case .layDownInitialBooks:
                return dragDropSource != .hand
            case .drawFromDiscardPileAndLayDownInitialBooks:
                return dragDropSource != .hand && dragDropSource != .discardPile
            case .startBook:
                return dragDropSource != .hand
            case .addCardFromHandToBook:
                return dragDropSource != .hand
        }
    }
}

class GameViewController: UIViewController, OpponentPreviewViewDelegate {
    
    private var opponentPreviewViews: [String : OpponentPreviewView]!
    private var footView: FootView!
    private var handView: HandView!
    private var booksView: BooksView!
    private var deckView: DeckView!
    
    private var lowestOpponentPreviewView: OpponentPreviewView?
    private var dimmerView: UIView?
    private var opponentView: OpponentView?
    private var opponentPlayerName: String?

    private var gameModel: GameModel!
    private var dragDropTransactions: [DragDropTransaction]!
    private var activeDragDropTransaction: ActiveDragDropTransaction?
    
    private var currentPlayer: Player {
        return self.gameModel.game!.getPlayer(named: DataManager.shared.currentUser!.email!)!
    }
    
    init(gameModel: GameModel) {
        super.init(nibName: nil, bundle: nil)
        
        self.opponentPreviewViews = [:]
        self.footView = FootView()
        self.handView = HandView()
        self.booksView = BooksView()
        self.deckView = DeckView()

        self.gameModel = gameModel
        self.dragDropTransactions = []
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
        
        self.view.insertSubview(self.booksView, belowSubview: self.lowestOpponentPreviewView!)
        self.booksView.pinX(to: self.handView)
        self.booksView.pin(edge: .bottom, to: .top, of: self.handView, with: -30)

        self.view.insertSubview(self.deckView, belowSubview: self.lowestOpponentPreviewView!)
        self.deckView.centerHorizontally(in: self.view)
        self.deckView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 100.0)
        self.deckView.pinHeight(toHeightOf: self.view, multiplier: 0.2, constant: 0.0)
        
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
        self.booksView.update(books: self.currentPlayer.books[game.round!]!)
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
    
    private func possibleActions() -> Set<PossibleAction> {
        var possibleActions = self.initialPossibleActions()
        
        for dragDropTransaction in self.dragDropTransactions {
            var disqualifiedActions = Set<PossibleAction>()
            
            for possibleAction in possibleActions {
                if possibleAction.isDisqualifiedBy(dragDropSource: dragDropTransaction.source) {
                    disqualifiedActions.insert(possibleAction)
                }
            }
            
            possibleActions = possibleActions.subtracting(disqualifiedActions)
        }
        
        return possibleActions
    }
    
    private func initialPossibleActions() -> Set<PossibleAction> {
        var possibleActions = Set<PossibleAction>()
        
        guard self.gameModel.game!.isCurrentPlayer(self.currentPlayer) else {
            return possibleActions
        }
        
        if self.currentPlayer.canDrawFromDeck {
            possibleActions.insert(.drawFromDeck)
        }

        if self.currentPlayer.canDrawFromDiscardPile {
            possibleActions.insert(.drawFromDiscardPileAndAddToBook)
        }
        
        if self.currentPlayer.hasLaidDownThisRound, self.currentPlayer.canDrawFromDiscardPile {
            possibleActions.insert(.drawFromDiscardPileAndCreateBook)
        }
        
        if self.currentPlayer.canEndTurn {
            possibleActions.insert(.discardCard)
        }
        
        if self.currentPlayer.hasLaidDownThisRound {
            possibleActions.insert(.layDownInitialBooks)
        }
        
        if !self.currentPlayer.hasLaidDownThisRound, self.currentPlayer.canDrawFromDiscardPile {
            possibleActions.insert(.drawFromDiscardPileAndLayDownInitialBooks)
        }
        
        if self.currentPlayer.hasLaidDownThisRound {
            possibleActions.insert(.startBook)
        }
        
        if self.currentPlayer.hasLaidDownThisRound {
            possibleActions.insert(.addCardFromHandToBook)
        }
        
        return possibleActions
    }
    
    private func validDragDropSources() -> Set<DragDropTransactionEndpoint> {
        var validDragDropSources = Set<DragDropTransactionEndpoint>()
        
        for possibleAction in self.possibleActions() {
            for possibleActionSource in possibleAction.dragDropSources {
                validDragDropSources.insert(possibleActionSource)
            }
        }
        
        return validDragDropSources
    }
    
    private func validDragDropDestinations() -> Set<DragDropTransactionEndpoint> {
        var validDragDropDestinations = Set<DragDropTransactionEndpoint>()

        for possibleAction in self.possibleActions() {
            guard !possibleAction.isDisqualifiedBy(dragDropSource: self.activeDragDropTransaction!.source) else {
                continue
            }
            
            for dragDropDestination in possibleAction.dragDropDestinations {
                validDragDropDestinations.insert(dragDropDestination)
            }
        }
        
        return validDragDropDestinations
    }
    
    private func commitAction(_ action: Action) {
        Network.shared.sendAddActionRequest(game: self.gameModel, action: action) { (success, httpStatusCode, response) in
            guard success else {
                if let errorMessage = response?["message"] as? String {
                    UIAlertController.presentErrorAlert(on: self, title: "Couldn't Add Action", message: errorMessage, okAction: nil)
                } else {
                    UIAlertController.presentErrorAlert(on: self, title: "Couldn't Add Action")
                }
                
                return
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
