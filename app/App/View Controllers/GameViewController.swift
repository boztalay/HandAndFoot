//
//  GameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

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
    private var actionBuilder: ActionBuilder!
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
        self.actionBuilder = ActionBuilder(game: self.gameModel.game!, player: self.currentPlayer)
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
            self.actionBuilder.reset(game: self.gameModel.game!, player: self.currentPlayer)
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
        
        self.actionBuilder.addTransaction(.drag(source, []))
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
        
        self.actionBuilder.addTransaction(.drag(source, cards.map({ $0.0 })))
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
            self.actionBuilder.addTransaction(.drop(destination))
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
                self.actionBuilder.cancelLastDrag()
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
        self.resetComplexActionInterface()
        
        var enabledDragDropSources: Set<DragDropSite>?
        var enabledDragDropDestinations: Set<DragDropSite>?
        
        switch (self.actionBuilder.state) {
            case let .idle(_, dragDropSources):
                enabledDragDropSources = dragDropSources
            case let .simpleActionDragging(_, dragDropDestinations):
                enabledDragDropDestinations = dragDropDestinations
            case let .complexActionIdle(possibleActions, dragDropSources):
                enabledDragDropSources = dragDropSources
                self.setUpComplexActionInterface(possibleActions: possibleActions)
            case let .complexActionDragging(possibleActions, dragDropDestinations):
                enabledDragDropDestinations = dragDropDestinations
                self.setUpComplexActionInterface(possibleActions: possibleActions)
            case let .finished(possibleActions):
                // TODO: Something about resetting the ActionBuilder here and
                //       then doing UI things with it below feels weird, but its
                //       state needs to be reset to avoid double committing
                //       actions (it can't hang out in the finished state)
                self.buildAndCommitFinalAction(possibleActions)
                self.actionBuilder.reset(game: self.gameModel.game!, player: self.currentPlayer)
        }
        
        for (source, view) in self.draggableViews {
            if let enabledDragDropSources = enabledDragDropSources, enabledDragDropSources.contains(source) {
                view.setDragState(.enabled, with: self.actionBuilder.draggedCardsBySource[source])
            } else if let activeDragSource = self.actionBuilder.activeDragSource, source == activeDragSource {
                view.setDragState(.dragging, with: self.actionBuilder.draggedCardsBySource[source])
            } else {
                view.setDragState(.disabled, with: self.actionBuilder.draggedCardsBySource[source])
            }
        }
        
        self.activeDropDestinations = enabledDragDropDestinations
        for (destination, view) in self.droppableViews {
            if let enabledDragDropDestinations = enabledDragDropDestinations, enabledDragDropDestinations.contains(destination) {
                view.setDropState(.enabled, with: self.actionBuilder.droppedCardsByDestination[destination])
            } else {
                view.setDropState(.disabled, with: self.actionBuilder.droppedCardsByDestination[destination])
            }
        }
    }
    
    private func resetComplexActionInterface() {
        self.navigationItem.rightBarButtonItem = nil
        self.navigationItem.leftBarButtonItem = nil
        self.title = self.gameModel.title
    }
    
    private func setUpComplexActionInterface(possibleActions: Set<PossibleAction>) {
        if possibleActions.contains(.layDownInitialBooks) || possibleActions.contains(.drawFromDiscardPileAndLayDownInitialBooks) {
            self.title = "Laying Down"
        } else if possibleActions.contains(.drawFromDiscardPileAndStartBook) || possibleActions.contains(.startBook) {
            self.title = "Starting Book"
        }
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(GameViewController.complexActionDoneButtonTapped))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(GameViewController.complexActionCancelButtonTapped))
    }
    
    @objc private func complexActionDoneButtonTapped(_ sender: Any) {
        self.actionBuilder.addTransaction(.done)
        self.updateViews()
    }
    
    @objc private func complexActionCancelButtonTapped(_ sender: Any) {
        self.actionBuilder.reset(game: self.gameModel.game!, player: self.currentPlayer)
        self.updateViews()
    }

    private func buildAndCommitFinalAction(_ possibleActions: Set<PossibleAction>) {
        guard let action = self.actionBuilder.buildAction() else {
            fatalError()
        }

        self.commitAction(action)
    }
    
    private func commitAction(_ action: Action) {
        Network.shared.sendAddActionRequest(game: self.gameModel, action: action) { (success, httpStatusCode, response) in
            guard success else {
                if let errorMessage = response?["message"] as? String {
                    UIAlertController.presentErrorAlert(on: self, title: "Couldn't Add Action", message: errorMessage, okAction: nil)
                } else {
                    UIAlertController.presentErrorAlert(on: self, title: "Couldn't Add Action")
                }
                
                // TODO: Is this reset necessary?
                self.actionBuilder.reset(game: self.gameModel.game!, player: self.currentPlayer)
                self.updateViews()
                
                return
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
