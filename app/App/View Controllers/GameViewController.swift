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
                    return false
                } else {
                    return true
                }
            case .drawFromDiscardPileAndCreateBook:
                if case .book = dragDropDestination {
                    return false
                } else {
                    return true
                }
            case .discardCard:
                return (dragDropDestination != .discardPile)
            case .layDownInitialBooks:
                if case .book = dragDropDestination {
                    return false
                } else {
                    return true
                }
            case .drawFromDiscardPileAndLayDownInitialBooks:
                if case .book = dragDropDestination {
                    return false
                } else {
                    return true
                }
            case .startBook:
                if case .book = dragDropDestination {
                    return false
                } else {
                    return true
                }
            case .addCardFromHandToBook:
                if case .book = dragDropDestination {
                    return false
                } else {
                    return true
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

    // TODO: A case for "committing" and another for "committed" to handle
    //       loading states?
    
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
    private var discardPileView: DiscardPileView!
    
    private var lowestOpponentPreviewView: OpponentPreviewView?
    private var rightmostOpponentPreviewView: OpponentPreviewView?
    private var leftmostOpponentPreviewView: OpponentPreviewView?
    private var dimmerView: UIView?
    private var opponentView: OpponentView?
    private var opponentPlayerName: String?

    private var gameModel: GameModel!
    private var actionBuildTransactions: [ActionBuildTransaction]!
    private var draggableViews: [DragDropSite : Draggable]!
    private var droppableViews: [DragDropSite : Droppable]!
    private var dragViews: [UIView]?
    private var originalDragViewPoints: [CGPoint]?
    private var activeDropDestinations: Set<DragDropSite>?
    
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
        self.discardPileView = DiscardPileView()

        self.gameModel = gameModel
        self.actionBuildTransactions = []
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = self.gameModel.title!
        
        self.createOpponentPreviewViews()
        
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
        self.booksView.pin(edge: .leading, to: .leading, of: self.view.safeAreaLayoutGuide, with: 40)
        self.booksView.pin(edge: .trailing, to: .trailing, of: self.view.safeAreaLayoutGuide, with: -40)
        self.booksView.pin(edge: .bottom, to: .top, of: self.handView, with: -30)

        self.view.insertSubview(self.deckView, belowSubview: self.lowestOpponentPreviewView!)
        self.deckView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 100.0)
        self.deckView.pinHeight(toHeightOf: self.view, multiplier: 0.18, constant: 0.0)
        self.deckView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        
        self.view.insertSubview(self.discardPileView, belowSubview: self.lowestOpponentPreviewView!)
        self.discardPileView.pin(edge: .top, to: .top, of: self.deckView)
        self.discardPileView.pin(edge: .leading, to: .trailing, of: self.deckView, with: 10.0)
        self.discardPileView.pinHeight(toHeightOf: self.deckView)
        self.discardPileView.setAspectRatio(to: CGFloat(CardView.aspectRatio))
        
        let deckAndDiscardLeading = self.view.leadingAnchor.anchorWithOffset(to: self.deckView.leadingAnchor)
        let deckAndDiscardTrailing = self.discardPileView.trailingAnchor.anchorWithOffset(to: self.view.trailingAnchor)
        deckAndDiscardLeading.constraint(equalTo: deckAndDiscardTrailing, multiplier: 1.0).isActive = true
        
        self.draggableViews = [
            .deck : self.deckView,
            .discardPile : self.discardPileView,
            .hand : self.handView
        ]
        
        self.droppableViews = [
            .discardPile : self.discardPileView,
            .hand : self.handView
        ]
        
        for view in draggableViews.values {
            view.dragDelegate = self
        }
        
        for (rank, bookView) in self.booksView.bookViews {
            self.droppableViews[.book(rank)] = bookView
        }
        
        self.updateViews()
    }
    
    private func createOpponentPreviewViews() {
        let game = self.gameModel.game!
        var lastOpponentPreviewView: OpponentPreviewView?
        
        let currentPlayerIndex = game.players.firstIndex(where: { $0.name == self.currentPlayer.name })!
        let numberOfOpponentsBefore = game.players.count / 2
        let numberOfOpponentsAfter = game.players.count - numberOfOpponentsBefore - 1

        for i in 0 ..< numberOfOpponentsBefore {
            let opponentIndex = (((currentPlayerIndex - 1) - i) + game.players.count) % game.players.count
            let opponent = game.players[opponentIndex]
            
            lastOpponentPreviewView = self.createOpponentPreviewView(
                opponent: opponent,
                isOpponentBeforeCurrentPlayer: true,
                lastOpponentPreviewView: lastOpponentPreviewView
            )
            
            if self.leftmostOpponentPreviewView == nil {
                self.leftmostOpponentPreviewView = lastOpponentPreviewView
            }
        }
        
        lastOpponentPreviewView = nil
        for i in 0 ..< numberOfOpponentsAfter {
            let opponentIndex = ((currentPlayerIndex + 1) + i) % game.players.count
            let opponent = game.players[opponentIndex]
            
            lastOpponentPreviewView = self.createOpponentPreviewView(
                opponent: opponent,
                isOpponentBeforeCurrentPlayer: false,
                lastOpponentPreviewView: lastOpponentPreviewView
            )

            if self.rightmostOpponentPreviewView == nil {
                self.rightmostOpponentPreviewView = lastOpponentPreviewView
            }
        }
    }
    
    private func createOpponentPreviewView(opponent: Player, isOpponentBeforeCurrentPlayer: Bool, lastOpponentPreviewView: OpponentPreviewView?) -> OpponentPreviewView {
        let opponentPreviewView = OpponentPreviewView()
        self.view.addSubview(opponentPreviewView)
        opponentPreviewView.setAspectRatio(to: 1.0)
        opponentPreviewView.pinHeight(toHeightOf: self.view, multiplier: 0.10, constant: 0.0)
        opponentPreviewView.delegate = self

        if isOpponentBeforeCurrentPlayer {
            opponentPreviewView.pin(edge: .leading, to: .leading, of: self.view.safeAreaLayoutGuide, with: 40)
        } else {
            opponentPreviewView.pin(edge: .trailing, to: .trailing, of: self.view.safeAreaLayoutGuide, with: -40)
        }
        
        if let lastOpponentPreviewView = lastOpponentPreviewView {
            opponentPreviewView.pin(edge: .top, to: .bottom, of: lastOpponentPreviewView, with: 20)
        } else {
            opponentPreviewView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 40)
        }
        
        self.opponentPreviewViews[opponent.name] = opponentPreviewView
        if self.lowestOpponentPreviewView == nil {
            self.lowestOpponentPreviewView = opponentPreviewView
        }

        return opponentPreviewView
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
        self.deckView.update(deck: game.deck)
        self.discardPileView.update(discardPile: game.discardPile)
        
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
            self.opponentView!.pin(edge: .leading, to: .trailing, of: self.leftmostOpponentPreviewView!, with: 30.0)
            self.opponentView!.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 40.0)
            
            if let rightmostOpponentPreviewView = self.rightmostOpponentPreviewView {
                self.opponentView!.pin(edge: .trailing, to: .leading, of: rightmostOpponentPreviewView, with: -30.0)
            } else {
                self.opponentView!.pin(edge: .trailing, to: .trailing, of: self.view.safeAreaLayoutGuide, with: -40.0)
            }
        }
        
        for (name, opponentPreviewView) in self.opponentPreviewViews {
            opponentPreviewView.isSelected = (name == player.name)
        }
        
        self.opponentView!.update(player: player, game: self.gameModel.game!)
        self.opponentPlayerName = player.name
    }
    
    @objc func dimmerViewTapped(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else {
            return
        }
        
        for opponentPreviewView in self.opponentPreviewViews.values {
            opponentPreviewView.isSelected = false
        }

        self.opponentView?.removeFromSuperview()
        self.opponentView = nil
        self.opponentPlayerName = nil

        self.dimmerView?.removeFromSuperview()
        self.dimmerView = nil
    }
    
    func dragStartedFaceDown(_ source: DragDropSite, with point: CGPoint, and cardSize: CGSize) {
        let dragSourceView = self.draggableViews[source]!

        let faceDownCardView = FaceDownCardView()
        self.view.addSubview(faceDownCardView)
        faceDownCardView.isUserInteractionEnabled = false
        faceDownCardView.frame = CGRect(origin: .zero, size: cardSize)
        faceDownCardView.center = dragSourceView.convert(point, to: self.view)

        self.dragViews = [faceDownCardView]
        self.originalDragViewPoints = [faceDownCardView.center]
        
        self.actionBuildTransactions.append(.drag(source, []))
        self.updateViews()
    }
    
    func dragStarted(_ source: DragDropSite, with cards: [(Card, CGPoint)], and cardSize: CGSize) {
        self.dragViews = []
        self.originalDragViewPoints = []
        let dragSourceView = self.draggableViews[source]!
        var lastCardView: CardView?

        for (card, point) in cards {
            let cardView = CardView(card: card)
            self.dragViews!.append(cardView)
            
            if let lastCardView = lastCardView {
                self.view.insertSubview(cardView, belowSubview: lastCardView)
            } else {
                self.view.addSubview(cardView)
            }

            cardView.isUserInteractionEnabled = false
            cardView.frame = CGRect(origin: .zero, size: cardSize)
            cardView.center = dragSourceView.convert(point, to: self.view)
            
            self.originalDragViewPoints!.append(cardView.center)
            lastCardView = cardView
        }
        
        self.actionBuildTransactions.append(.drag(source, cards.map({ $0.0 })))
        self.updateViews()
    }
    
    func dragMoved(_ source: DragDropSite, to point: CGPoint) {
        guard let dragViews = self.dragViews, dragViews.count > 0 else {
            fatalError()
        }

        let dragSourceView = self.draggableViews[source]!
        let animationOptions = UIView.AnimationOptions(arrayLiteral: .curveEaseInOut)

        for (i, dragView) in dragViews.enumerated() {
            let delay = Double(i) * 0.025
            UIView.animate(withDuration: 0.2, delay: delay, options: animationOptions, animations: {
                dragView.center = dragSourceView.convert(point, to: self.view)
            }, completion: nil)
        }
    }
    
    func dragEnded(_ source: DragDropSite, at point: CGPoint) {
        let dragSourceView = self.draggableViews[source]!
        let dropPoint = dragSourceView.convert(point, to: self.view)

        var destination: DragDropSite?
        var subview = self.view.hitTest(dropPoint, with: nil)

        while subview != self.view {
            if subview == nil {
                break
            }
            
            for (potentialDestination, droppableView) in self.droppableViews {
                if subview! === droppableView {
                    destination = potentialDestination
                    break
                }
            }
            
            if destination != nil {
                break
            }
            
            subview = subview!.superview
        }
        
        if let destination = destination, self.activeDropDestinations!.contains(destination) {
            self.actionBuildTransactions.append(.drop(destination))
            self.cleanUpFinishedDrag()
        } else {
            for dragView in self.dragViews! {
                dragView.layer.removeAllAnimations()
            }
            
            let animationOptions = UIView.AnimationOptions(arrayLiteral: .curveEaseOut)
            UIView.animate(withDuration: 0.15, delay: 0.0, options: animationOptions, animations: {
                for (dragView, originalPoint) in zip(self.dragViews!, self.originalDragViewPoints!) {
                    dragView.center = originalPoint
                }
            }) { completed in
                _ = self.actionBuildTransactions.popLast()
                self.cleanUpFinishedDrag()
            }
        }
    }
    
    private func cleanUpFinishedDrag() {
        for dragView in self.dragViews! {
            dragView.removeFromSuperview()
        }
        
        self.dragViews = nil
        self.originalDragViewPoints = nil
        
        self.updateViews()
    }
    
    private func updateActionBuildState() {
        let possibleActions = self.initialPossibleActions()
        let dragDropSources = possibleActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources()) })
        var state = ActionBuildState.idle(possibleActions, dragDropSources)

        var draggedCards = [DragDropSite : [Card]]()
        var droppedCards = [DragDropSite : [Card]]()
        var lastDraggedCards: [Card]?
        var activeDragSource: DragDropSite?
        
        for transaction in self.actionBuildTransactions {
            state = state.advanceState(given: transaction)
            
            if case let .drag(source, cards) = transaction {
                if draggedCards[source] == nil {
                    draggedCards[source] = []
                }

                draggedCards[source]!.append(contentsOf: cards)
                lastDraggedCards = cards
                activeDragSource = source
            } else {
                if case let .drop(destination) = transaction {
                    if droppedCards[destination] == nil {
                        droppedCards[destination] = []
                    }

                    droppedCards[destination]!.append(contentsOf: lastDraggedCards!)
                }
                
                lastDraggedCards = nil
                activeDragSource = nil
            }
        }

        self.navigationItem.rightBarButtonItem = nil
        self.title = self.gameModel.title
        
        var enabledDragDropSources: Set<DragDropSite>?
        var enabledDragDropDestinations: Set<DragDropSite>?
        
        switch (state) {
            case let .idle(_, dragDropSources):
                enabledDragDropSources = dragDropSources
            case let .simpleActionDragging(_, dragDropDestinations):
                enabledDragDropDestinations = dragDropDestinations
            case let .complexActionIdle(possibleActions, dragDropSources):
                enabledDragDropSources = dragDropSources
                
                if possibleActions.contains(.layDownInitialBooks) || possibleActions.contains(.drawFromDiscardPileAndLayDownInitialBooks) {
                    self.title = "Laying Down"
                } else if possibleActions.contains(.drawFromDiscardPileAndCreateBook) || possibleActions.contains(.startBook) {
                    self.title = "Starting Book"
                } else if possibleActions.contains(.drawFromDiscardPileAndAddToBook) || possibleActions.contains(.addCardFromHandToBook) {
                    self.title = "Adding to Book"
                }
                
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(GameViewController.complexActionDoneButtonTapped))
            case let .complexActionDragging(possibleActions, dragDropDestinations):
                enabledDragDropDestinations = dragDropDestinations
                
                if possibleActions.contains(.layDownInitialBooks) || possibleActions.contains(.drawFromDiscardPileAndLayDownInitialBooks) {
                    self.title = "Laying Down"
                } else if possibleActions.contains(.drawFromDiscardPileAndCreateBook) || possibleActions.contains(.startBook) {
                    self.title = "Starting Book"
                } else if possibleActions.contains(.drawFromDiscardPileAndAddToBook) || possibleActions.contains(.addCardFromHandToBook) {
                    self.title = "Adding to Book"
                }
                
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(GameViewController.complexActionDoneButtonTapped))
            case let .finished(possibleActions):
                self.buildAndCommitFinalAction(possibleActions)
                self.actionBuildTransactions = []
        }
        
        for (source, view) in self.draggableViews {
            if let enabledDragDropSources = enabledDragDropSources {
                if enabledDragDropSources.contains(source) {
                    view.setDragState(.enabled, with: draggedCards[source])
                } else if let activeDragSource = activeDragSource, source == activeDragSource {
                    view.setDragState(.dragging, with: draggedCards[source])
                }
            } else {
                view.setDragState(.disabled, with: draggedCards[source])
            }
        }
        
        self.activeDropDestinations = enabledDragDropDestinations
        for (destination, view) in self.droppableViews {
            if let enabledDragDropDestinations = enabledDragDropDestinations, enabledDragDropDestinations.contains(destination) {
                view.setDropState(.enabled, with: droppedCards[destination])
            } else {
                view.setDropState(.disabled, with: droppedCards[destination])
            }
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

        if self.currentPlayer.hasLaidDownThisRound, self.currentPlayer.canDrawFromDiscardPile {
            possibleActions.insert(.drawFromDiscardPileAndAddToBook)
        }
        
        if self.currentPlayer.hasLaidDownThisRound, self.currentPlayer.canDrawFromDiscardPile {
            possibleActions.insert(.drawFromDiscardPileAndCreateBook)
        }
        
        if self.currentPlayer.canEndTurn {
            possibleActions.insert(.discardCard)
        }
        
        if !self.currentPlayer.hasLaidDownThisRound {
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
    
    @objc private func complexActionDoneButtonTapped(_ sender: Any) {
        self.actionBuildTransactions.append(.done)
        self.updateViews()
    }

    private func buildAndCommitFinalAction(_ possibleActions: Set<PossibleAction>) {
        var action: Action?
        
        if possibleActions.contains(.drawFromDeck) {
            action = .drawFromDeck(self.currentPlayer.name)
        } else if possibleActions.contains(.drawFromDiscardPileAndAddToBook) {
            var bookRank: CardRank?
            
            for transaction in self.actionBuildTransactions {
                if case let .drop(destination) = transaction {
                    if case let .book(rank) = destination {
                        bookRank = rank
                    }
                }
            }
            
            action = .drawFromDiscardPileAndAddToBook(self.currentPlayer.name, bookRank!)
        } else if possibleActions.contains(.drawFromDiscardPileAndCreateBook) {
            var cards = [Card]()
            
            var dragCards: [Card]?
            for transaction in self.actionBuildTransactions {
                if case let .drag(_, cards) = transaction {
                    dragCards = cards
                } else if case let .drop(destination) = transaction {
                    if case .book = destination {
                        cards.append(contentsOf: dragCards!)
                    }

                    dragCards = nil
                }
            }

            action = .drawFromDiscardPileAndCreateBook(self.currentPlayer.name, cards)
        } else if possibleActions.contains(.discardCard) {
            var card: Card?
            
            for transaction in self.actionBuildTransactions {
                if case let .drag(_, cards) = transaction, cards.count == 1 {
                    card = cards.first!
                }
            }
            
            action = .discardCard(self.currentPlayer.name, card!)
        } else if possibleActions.contains(.layDownInitialBooks) || possibleActions.contains(.drawFromDiscardPileAndLayDownInitialBooks) {
            var booksCards = [CardRank : [Card]]()
            
            var dragCards: [Card]?
            for transaction in self.actionBuildTransactions {
                if case let .drag(_, cards) = transaction {
                    dragCards = cards
                } else if case let .drop(destination) = transaction {
                    if case let .book(rank) = destination {
                        if booksCards[rank!] == nil {
                            booksCards[rank!] = []
                        }
                        
                        booksCards[rank!]?.append(contentsOf: dragCards!)
                    }

                    dragCards = nil
                }
            }
            
            let books = Array(booksCards.values)
            action = .layDownInitialBooks(self.currentPlayer.name, books)
        } else if possibleActions.contains(.startBook) {
            var cards = [Card]()
            
            var dragCards: [Card]?
            for transaction in self.actionBuildTransactions {
                if case let .drag(_, cards) = transaction {
                    dragCards = cards
                } else if case let .drop(destination) = transaction {
                    if case .book = destination {
                        cards.append(contentsOf: dragCards!)
                    }

                    dragCards = nil
                }
            }

            action = .startBook(self.currentPlayer.name, cards)
        } else if possibleActions.contains(.addCardFromHandToBook) {
            var card: Card?
            var bookRank: CardRank?
            
            for transaction in self.actionBuildTransactions {
                if case let .drag(_, cards) = transaction, cards.count == 1 {
                    card = cards.first!
                } else if case let .drop(destination) = transaction {
                    if case let .book(rank) = destination {
                        bookRank = rank
                    }
                }
            }
            
            action = .addCardFromHandToBook(self.currentPlayer.name, card!, bookRank!)
        } else {
            fatalError()
        }

        if let action = action {
            self.commitAction(action)
        } else {
            fatalError()
        }
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
