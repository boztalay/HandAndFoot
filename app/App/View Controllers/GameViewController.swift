//
//  GameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

enum DragDropSite: Hashable {
    case deck
    case discardPile
    case book(CardRank?)
    case hand
}

enum ActionBuildTransaction {
    case completeDragDrop(DragDropSite, DragDropSite, [Card])
    case partialDragDrop(DragDropSite, [Card])
    case done
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
    
    func dragDropSources() -> Set<DragDropSite> {
        var validSources = Set<DragDropSite>()
        
        switch (self) {
            case .drawFromDeck:
                validSources.insert(.deck)
            case .drawFromDiscardPileAndAddToBook:
                validSources.insert(.discardPile)
            case .drawFromDiscardPileAndCreateBook:
                validSources.insert(.discardPile)
            case .discardCard:
                validSources.insert(.hand)
            case .layDownInitialBooks:
                validSources.insert(.hand)
            case .drawFromDiscardPileAndLayDownInitialBooks:
                validSources.insert(.discardPile)
                validSources.insert(.hand)
            case .startBook:
                validSources.insert(.hand)
            case .addCardFromHandToBook:
                validSources.insert(.hand)
        }
        
        return validSources
    }
    
    func dragDropDestinations(cards: [Card]) -> Set<DragDropSite> {
        // TODO: Smarter book destinations?
        
        var validDestinations = Set<DragDropSite>()
        
        switch (self) {
            case .drawFromDeck:
                validDestinations.insert(.hand)
            case .drawFromDiscardPileAndAddToBook:
                guard cards.count == 1 else {
                    fatalError()
                }

                validDestinations.insert(.book(cards.first!.bookRank))
            case .drawFromDiscardPileAndCreateBook:
                guard cards.count > 0 else {
                    fatalError()
                }

                let bookRank = cards.first(where: { $0.bookRank != nil })?.bookRank
                validDestinations.insert(.book(bookRank))
            case .discardCard:
                validDestinations.insert(.discardPile)
            case .layDownInitialBooks:
                guard cards.count > 0 else {
                    fatalError()
                }

                let bookRank = cards.first(where: { $0.bookRank != nil })?.bookRank
                validDestinations.insert(.book(bookRank))
            case .drawFromDiscardPileAndLayDownInitialBooks:
                guard cards.count > 0 else {
                    fatalError()
                }

                let bookRank = cards.first(where: { $0.bookRank != nil })?.bookRank
                validDestinations.insert(.book(bookRank))
            case .startBook:
                guard cards.count > 0 else {
                    fatalError()
                }

                let bookRank = cards.first(where: { $0.bookRank != nil })?.bookRank
                validDestinations.insert(.book(bookRank))
            case .addCardFromHandToBook:
                guard cards.count == 1 else {
                    fatalError()
                }
                
                validDestinations.insert(.book(cards.first!.bookRank))
        }
        
        return validDestinations
    }
    
    func isDisqualifiedBy(dragDropSource: DragDropSite, cards: [Card]) -> Bool {
        // TODO: Take the cards into account for books and all that
        
        switch (self) {
            case .drawFromDeck:
                return (dragDropSource != .hand)
            case .drawFromDiscardPileAndAddToBook:
                return (dragDropSource != .discardPile)
            case .drawFromDiscardPileAndCreateBook:
                return (dragDropSource != .discardPile)
            case .discardCard:
                return (dragDropSource != .hand) || (cards.count != 1)
            case .layDownInitialBooks:
                return (dragDropSource != .hand)
            case .drawFromDiscardPileAndLayDownInitialBooks:
                return (dragDropSource != .hand && dragDropSource != .discardPile)
            case .startBook:
                return (dragDropSource != .hand)
            case .addCardFromHandToBook:
                return (dragDropSource != .hand) || (cards.count != 1)
        }
    }
}

enum ActionBuildState {
    case idle(Set<DragDropSite>)
    case simpleActionDragging(Set<DragDropSite>)
    case complexActionIdle(Set<PossibleAction>, Set<DragDropSite>)
    case complexActionDragging(Set<PossibleAction>, Set<DragDropSite>)
    case finished(Action)
}

class GameViewController: UIViewController, OpponentPreviewViewDelegate {
    
    private static func simpleActionTable(source: DragDropSite, destination: DragDropSite) -> PossibleAction? {
        if source == .deck {
            if destination == .hand {
                return .drawFromDeck
            }
        } else if source == .discardPile {
            if case .book(_) = destination {
                return .drawFromDiscardPileAndAddToBook
            }
        } else if source == .hand {
            if destination == .discardPile {
                return .discardCard
            } else if case .book(_) = destination {
                return .addCardFromHandToBook
            }
        }
        
        return nil
    }
    
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
    private var actionBuildTransactions: [ActionBuildTransaction]!
    
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
        self.actionBuildTransactions = []
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
    
    private func getActionBuildState() -> ActionBuildState {
        guard self.actionBuildTransactions.count > 0 else {
            return .idle(self.validIdleDragDropSources())
        }
        
        guard self.actionBuildTransactions.count > 1 else {
            switch (self.actionBuildTransactions.first!) {
                case let .completeDragDrop(source, destination, cards):
                    if let action = self.finishedSimpleAction(source: source, destination: destination, cards: cards) {
                        return .finished(action)
                    } else {
                        return .complexActionIdle(self.possibleComplexActions(), self.validComplexActionDragDropSources())
                    }
                case let .partialDragDrop(source, cards):
                    return .simpleActionDragging(self.validIdleDragDropDestinations(from: source, with: cards))
                default:
                    fatalError("Invalid lone action build transaction")
            }
        }
        
        switch (self.actionBuildTransactions.last!) {
            case .completeDragDrop:
                return .complexActionIdle(self.possibleComplexActions(), self.validComplexActionDragDropSources())
            case .partialDragDrop:
                return .complexActionDragging(self.possibleComplexActions(), self.validComplexActionDragDropDestinations())
            case .done:
                return .finished(self.finishedComplexAction())
        }
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
    
    private func validIdleDragDropSources() -> Set<DragDropSite> {
        var dragDropSources = Set<DragDropSite>()

        for possibleAction in self.initialPossibleActions() {
            dragDropSources.formUnion(possibleAction.dragDropSources())
        }

        return dragDropSources
    }

    private func validIdleDragDropDestinations(from source: DragDropSite, with cards: [Card]) -> Set<DragDropSite> {
        var dragDropDestinations = Set<DragDropSite>()

        for possibleAction in self.initialPossibleActions() {
            if !possibleAction.isDisqualifiedBy(dragDropSource: source, cards: cards) {
                dragDropDestinations.formUnion(possibleAction.dragDropDestinations(cards: cards))
            }
        }

        return dragDropDestinations
    }

    private func finishedSimpleAction(source: DragDropSite, destination: DragDropSite, cards: [Card]) -> Action? {
        guard let possibleAction = GameViewController.simpleActionTable(source: source, destination: destination) else {
            return nil
        }
        
        switch (possibleAction) {
            case .drawFromDeck:
                return .drawFromDeck(self.currentPlayer.name)
            case .drawFromDiscardPileAndAddToBook:
                guard cards.count == 1 else {
                    fatalError("How did they draw anything other than one card from the discard pile?")
                }
                
                return .drawFromDiscardPileAndAddToBook(self.currentPlayer.name, cards.first!.rank)
            case .discardCard:
                guard cards.count == 1 else {
                    fatalError("You can't discard more than one card!")
                }
            
                return .discardCard(self.currentPlayer.name, cards.first!)
            case .addCardFromHandToBook:
                guard cards.count == 1 else {
                    fatalError("You can't add more than one card to a book at a time! For now...")
                }
                
                guard case let .book(bookRank) = destination else {
                    fatalError()
                }
            
                return .addCardFromHandToBook(self.currentPlayer.name, cards.first!, bookRank!)
            default:
                fatalError("Yooo this shouldn't happen, check your table bro")
        }
    }
    
    private func possibleComplexActions() -> Set<PossibleAction> {
        guard self.actionBuildTransactions.count > 0 else {
            fatalError()
        }
        
        if self.actionBuildTransactions.count == 1 {
            if case .partialDragDrop(_, _) = self.actionBuildTransactions.first! {
                fatalError()
            }
        }
        
        var initialPossibleActions = self.initialPossibleActions()
        var disqualifiedPossibleActions = Set<PossibleAction>()
        
        for actionBuildTransaction in self.actionBuildTransactions {
            // TODO
        }

        return Set<PossibleAction>()
    }
    
    private func validComplexActionDragDropSources() -> Set<DragDropSite> {
        // TODO
        return Set<DragDropSite>()
    }

    private func validComplexActionDragDropDestinations() -> Set<DragDropSite> {
        // TODO
        return Set<DragDropSite>()
    }
    
    private func finishedComplexAction() -> Action {
        // TODO
        return .drawFromDeck("TODO")
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
