//
//  GameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

enum ActionBuildTransaction {
    case drag(DragDropSite, [Card])
    case drop(DragDropSite)
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
    
    var isComplex: Bool {
        switch (self) {
            case .drawFromDeck:
                return false
            case .drawFromDiscardPileAndAddToBook:
                return false
            case .drawFromDiscardPileAndCreateBook:
                return true
            case .discardCard:
                return false
            case .layDownInitialBooks:
                return true
            case .drawFromDiscardPileAndLayDownInitialBooks:
                return true
            case .startBook:
                return true
            case .addCardFromHandToBook:
                return false
        }
    }
    
    func dragDropSources() -> Set<DragDropSite> {
        // TODO: Any complex action that has a discard pile source needs to
        //       remove the discard pile as a source after drawing from it once,
        //       probably requires passing in all of the transactions taken so
        //       far when advancing the state instead of just the latest one
        
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
                return (dragDropSource != .deck)
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
    
    func isDisqualifiedBy(dragDropDestination: DragDropSite) -> Bool {
        switch (self) {
            case .drawFromDeck:
                return (dragDropDestination != .hand)
            case .drawFromDiscardPileAndAddToBook:
                if case .book = dragDropDestination {
                    return true
                } else {
                    return false
                }
            case .drawFromDiscardPileAndCreateBook:
                if case .book = dragDropDestination {
                    return true
                } else {
                    return false
                }
            case .discardCard:
                return (dragDropDestination != .discardPile)
            case .layDownInitialBooks:
                if case .book = dragDropDestination {
                    return true
                } else {
                    return false
                }
            case .drawFromDiscardPileAndLayDownInitialBooks:
                if case .book = dragDropDestination {
                    return true
                } else {
                    return false
                }
            case .startBook:
                if case .book = dragDropDestination {
                    return true
                } else {
                    return false
                }
            case .addCardFromHandToBook:
                if case .book = dragDropDestination {
                    return true
                } else {
                    return false
                }
        }
    }
}

enum ActionBuildState {
    case idle(Set<PossibleAction>, Set<DragDropSite>)
    case simpleActionDragging(Set<PossibleAction>, Set<DragDropSite>)
    case complexActionIdle(Set<PossibleAction>, Set<DragDropSite>)
    case complexActionDragging(Set<PossibleAction>, Set<DragDropSite>)
    case finished(Set<PossibleAction>)
    
    func advanceState(given transaction: ActionBuildTransaction) -> ActionBuildState {
        switch (self) {
            case let .idle(possibleActions, dragDropSources):
                return self.advanceStateIdle(
                    transaction: transaction,
                    possibleActions: possibleActions,
                    dragDropSources: dragDropSources
                )
            case let .simpleActionDragging(possibleActions, dragDropDestinations):
                return self.advanceStateSimpleActionDragging(
                    transaction: transaction,
                    possibleActions: possibleActions,
                    dragDropDestinations: dragDropDestinations
                )
            case let .complexActionIdle(possibleActions, dragDropSources):
                return self.advanceStateComplexActionIdle(
                    transaction: transaction,
                    possibleActions: possibleActions,
                    dragDropSources: dragDropSources
                )
            case let .complexActionDragging(possibleActions, dragDropDestinations):
                return self.advanceStateComplexActionDragging(
                    transaction: transaction,
                    possibleActions: possibleActions,
                    dragDropDestinations: dragDropDestinations
                )
            case .finished:
                // Determine the next idle?
                fatalError()
        }
    }
    
    private func advanceStateIdle(transaction: ActionBuildTransaction, possibleActions: Set<PossibleAction>, dragDropSources: Set<DragDropSite>) -> ActionBuildState {
        switch (transaction) {
            case let .drag(source, cards):
                guard dragDropSources.contains(source) else {
                    fatalError()
                }
            
                let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(dragDropSource: source, cards: cards) })
                guard remainingActions.count > 0 else {
                    fatalError()
                }
                
                let validDestinations = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropDestinations(cards: cards)) })
                return .simpleActionDragging(remainingActions, validDestinations)
            case .drop:
                fatalError()
            case .done:
                fatalError()
        }
    }

    private func advanceStateSimpleActionDragging(transaction: ActionBuildTransaction, possibleActions: Set<PossibleAction>, dragDropDestinations: Set<DragDropSite>) -> ActionBuildState {
        switch (transaction) {
            case .drag:
                fatalError()
            case let .drop(destination):
                guard dragDropDestinations.contains(destination) else {
                    fatalError()
                }
                
                // One dragon drop should be able to get down to exactly one
                // possible action, with the exception of laying down vs laying
                // down with a discard
                let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(dragDropDestination: destination) })
                guard (remainingActions.count == 1) || (remainingActions.count == 2 && remainingActions.contains(.layDownInitialBooks) && remainingActions.contains(.drawFromDiscardPileAndLayDownInitialBooks)) else {
                    fatalError()
                }
            
                if remainingActions.first!.isComplex {
                    let validSources = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources()) })
                    return .complexActionIdle(remainingActions, validSources)
                } else {
                    return .finished(remainingActions)
                }
            case .done:
                fatalError()
        }
    }

    private func advanceStateComplexActionIdle(transaction: ActionBuildTransaction, possibleActions: Set<PossibleAction>, dragDropSources: Set<DragDropSite>) -> ActionBuildState {
        switch (transaction) {
            case let .drag(source, cards):
                guard dragDropSources.contains(source) else {
                    fatalError()
                }
            
                let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(dragDropSource: source, cards: cards) })
                guard remainingActions.count > 0 else {
                    fatalError()
                }
            
                let validDestinations = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropDestinations(cards: cards)) })
                return .complexActionDragging(remainingActions, validDestinations)
            case .drop:
                fatalError()
            case .done:
                return .finished(possibleActions)
        }
    }

    private func advanceStateComplexActionDragging(transaction: ActionBuildTransaction, possibleActions: Set<PossibleAction>, dragDropDestinations: Set<DragDropSite>) -> ActionBuildState {
        switch (transaction) {
            case .drag:
                fatalError()
            case let .drop(destination):
                guard dragDropDestinations.contains(destination) else {
                    fatalError()
                }
            
                let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(dragDropDestination: destination) })
                guard remainingActions.count > 0 else {
                    fatalError()
                }
            
                let validSources = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources()) })
                return .complexActionIdle(remainingActions, validSources)
            case .done:
                fatalError()
        }
    }
}

class GameViewController: UIViewController, OpponentPreviewViewDelegate, DragDelegate {
    
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
    private var draggableViews: [DragDropSite : Draggable]!
    private var droppableViews: [DragDropSite : Droppable]!
    private var dragView: UIView?
    
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
        
        self.draggableViews = [
            .deck : self.deckView,
            .discardPile : self.deckView
        ]
        
        self.droppableViews = [
            .discardPile: self.deckView
        ]
        
        for view in draggableViews.values {
            view.dragDelegate = self
        }
        
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
        
        self.updateActionBuildState()
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
    
    func dragStarted(from source: DragDropSite, with cards: [Card], at point: CGPoint, with size: CGSize) {
        self.actionBuildTransactions.append(.drag(source, cards))
        self.updateActionBuildState()
        
        if cards.count == 0 {
            self.dragView = FaceDownCardView()
        } else {
            self.dragView = CardView(card: cards.first!)
        }

        self.view.addSubview(self.dragView!)
        
        let dragSourceView = self.draggableViews[source]!
        let dragStartPoint = dragSourceView.convert(point, to: self.view)
        
        // TODO: A real size of some sort
        self.dragView!.frame = CGRect(origin: .zero, size: size)
        self.dragView!.center = dragStartPoint
    }
    
    func dragMoved(_ delta: CGPoint) {
        guard let dragView = self.dragView else {
            fatalError()
        }
        
        dragView.frame = CGRect(
            origin: CGPoint(
                x: dragView.frame.origin.x + delta.x,
                y: dragView.frame.origin.y + delta.y),
            size: dragView.frame.size)
    }
    
    func dragEnded() {
        self.dragView!.removeFromSuperview()
        self.dragView = nil
        
        _ = self.actionBuildTransactions.popLast()
        self.updateActionBuildState()
        
        // Determine the view that it was dropped on (if any)
        // If it was dropped on a valid destination, add the drop action build transaction
        // Otherwise, remove the last action build transaction (the drag)
        
//        self.actionBuildTransactions.append(.drop(destination))
//        self.updateActionBuildState()
    }
    
    @objc func doneButtonTapped(_ sender: Any) {
        self.actionBuildTransactions.append(.done)
        self.updateActionBuildState()
    }
    
    private func updateActionBuildState() {
        let possibleActions = self.initialPossibleActions()
        let dragDropSources = possibleActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources()) })

        var state = ActionBuildState.idle(possibleActions, dragDropSources)
        for transaction in self.actionBuildTransactions {
            state = state.advanceState(given: transaction)
        }

        for source in DragDropSite.allCases {
            self.draggableViews[source]?.deactivateDragging(for: source)
        }
        
        for destination in DragDropSite.allCases {
            self.droppableViews[destination]?.deactivateDropping(for: destination)
        }
        
        switch (state) {
            case let .idle(_, dragDropSources):
                for source in dragDropSources {
                    self.draggableViews[source]?.activateDragging(for: source)
                }
            case let .simpleActionDragging(_, dragDropDestinations):
                for destination in dragDropDestinations {
                    self.droppableViews[destination]?.activateDropping(for: destination)
                }
            case let .complexActionIdle(possibleActions, dragDropSources):
                // TODO: Something with the actions, go into mid-action state, etc
                for source in dragDropSources {
                    self.draggableViews[source]?.activateDragging(for: source)
                }
            case let .complexActionDragging(possibleActions, dragDropDestinations):
                // TODO: Something with the actions, go into mid-action state, etc
                for destination in dragDropDestinations {
                    self.droppableViews[destination]?.activateDropping(for: destination)
                }
            case let .finished(possibleActions):
                // TODO: Build and commit the action
                break
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
