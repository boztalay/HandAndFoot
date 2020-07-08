//
//  ActionBuilder.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/30/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

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
    
    func dragDropSources(player: Player, transactions: [ActionBuildTransaction]) -> Set<DragDropSite> {
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
                
                for transaction in transactions {
                    if case let .drag(source, _) = transaction, source == .discardPile {
                        validSources.remove(.discardPile)
                        break
                    }
                }
            case .startBook:
                validSources.insert(.hand)
            case .addCardFromHandToBook:
                validSources.insert(.hand)
        }
        
        return validSources
    }
    
    func dragDropDestinations(player: Player, transactions: [ActionBuildTransaction]) -> Set<DragDropSite> {
        guard case let .drag(lastDragSource, lastDragCards) = transactions.last! else {
            fatalError()
        }
        
        var validDestinations = Set<DragDropSite>()
        
        switch (self) {
            case .drawFromDeck:
                validDestinations.insert(.hand)
            case .drawFromDiscardPileAndAddToBook:
                guard lastDragCards.count == 1 else {
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
    
    func isDisqualifiedBy(player: Player, transactions: [ActionBuildTransaction]) -> Bool {
        switch (self) {
            case .drawFromDeck:
                // * Need to be able to draw from the deck
                // * All good if there aren't any transactions
                // * Drag can only start from the deck
                // * Drop can only go to the hand
                // * There can only be one drag and one drop
                
                guard player.canDrawFromDeck,
                      self.dragsOnlyStartFrom(transactions, dragSources: [.deck]),
                      self.dropsOnlyGoTo(transactions, dropDestinations: [.hand]),
                      self.atMostOneDragDropPairIn(transactions) else {
                    return true
                }
                
                return false
            case .drawFromDiscardPileAndAddToBook:
                // * Need to be able to draw from the discard pile
                // * Need to have already laid down
                // * All good if there aren't any transactions
                // * Drag can only start from the discard pile
                // * Drags must only have playable cards (no threes)
                //   - Does this mean this function needs the game state too?
                //     Could disqualify this before the drag by checking what's
                //     on top of the discard pile
                // * Drop can only go to a book
                // * There can only be one drag and one drop
                
                guard player.canDrawFromDiscardPile,
                      player.hasLaidDownThisRound,
                      self.dragsOnlyStartFrom(transactions, dragSources: [.discardPile]),
                      self.dragsOnlyContainPlayableCards(transactions),
                      self.dropsOnlyGoTo(transactions, dropDestinations: DragDropSite.allBookCases),
                      self.atMostOneDragDropPairIn(transactions) else {
                    return true
                }
                
                return false
            case .drawFromDiscardPileAndCreateBook:
                // Need to be able to draw from the discard pile
                // Need to have already laid down
                // All good if there aren't any transactions
                // Drags can only be from the discard pile or the hand
                // Drags must only have playable cards (no threes)
                //  - Same note as above with checking what's on the discard pile
                // There can only be drag from the discard pile
                // Drops can only go to books, and only one book
                
                guard player.canDrawFromDiscardPile, player.hasLaidDownThisRound else {
                    return true
                }
                
                guard transactions.count > 0 else {
                    return false
                }
                
                // TODO
                
                return (dragDropSource != .discardPile)
            case .discardCard:
                // Need to be able to end turn
                // All good if there aren't any transactions
                // Drag can only be from the hand
                // Drop can only go to the discard pile
                // There can only be one drag and one drop
                
                guard player.canEndTurn else {
                    return true
                }
                
                return (dragDropSource != .hand) || (cards.count != 1)
            case .layDownInitialBooks:
                // Need to have not laid down yet
                // All good if there aren't any transactions
                // Drags can only start from the hand
                // Drags must only have playable cards (no threes)
                // Drops can only go to books
                
                guard !player.hasLaidDownThisRound else {
                    return true
                }
                
                return (dragDropSource != .hand)
            case .drawFromDiscardPileAndLayDownInitialBooks:
                // Need to be able to draw from the discard pile
                // Need to have not laid down yet
                // All good if there aren't any transactions
                // Drags can only start from the discard pile or the hand
                // There can only be one drag from the discard pile
                // Drags must only have playable cards (no threes)
                // Drops can only go to books
                
                guard player.canDrawFromDiscardPile, !player.hasLaidDownThisRound else {
                    return true
                }
                
                return (dragDropSource != .hand && dragDropSource != .discardPile)
            case .startBook:
                // Need to have laid down already
                // All good if there aren't any transactions
                // Drags can only start from the hand
                // Drags must only have playable cards (no threes)
                // Drops can only go to books, and only one book
                
                guard player.hasLaidDownThisRound else {
                    return true
                }
                
                return (dragDropSource != .hand)
            case .addCardFromHandToBook:
                // Need to have laid down already
                // All good if there aren't any transactions
                // Drag can only start from the hand
                // Drag must only have playable cards (no threes)
                // Drop can only go to a book
                // There can only be one drag and one drop
                
                guard player.hasLaidDownThisRound else {
                    return true
                }
                
                return (dragDropSource != .hand) || (cards.count != 1)
        }
    }
    
    private func dragsOnlyStartFrom(_ transactions: [ActionBuildTransaction], dragSources: Set<DragDropSite>) -> Bool {
        for transaction in transactions {
            if case let .drag(source, _) = transaction {
                if !dragSources.contains(source) {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func dragsOnlyContainPlayableCards(_ transactions: [ActionBuildTransaction]) -> Bool {
        for transaction in transactions {
            if case let .drag(_, cards) = transaction {
                for card in cards {
                    if !card.isPlayable {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    private func dropsOnlyGoTo(_ transactions: [ActionBuildTransaction], dropDestinations: Set<DragDropSite>) -> Bool {
        for transaction in transactions {
            if case let .drop(destination) = transaction {
                if !dropDestinations.contains(destination) {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func atMostOneDragDropPairIn(_ transactions: [ActionBuildTransaction]) -> Bool {
        var dragCount = 0
        var dropCount = 0
        
        for transaction in transactions {
            if case .drag = transaction {
                dragCount += 1
            } else if case .drop = transaction {
                dropCount += 1
            }
        }
        
        return ((dragCount <= 1) && (dropCount <= 1))
    }
}

enum ActionBuildState {
    case idle(Set<PossibleAction>, Set<DragDropSite>)
    case simpleActionDragging(Set<PossibleAction>, Set<DragDropSite>)
    case complexActionIdle(Set<PossibleAction>, Set<DragDropSite>)
    case complexActionDragging(Set<PossibleAction>, Set<DragDropSite>)
    case finished(Set<PossibleAction>)
    
    func advanceState(player: Player, transactions: [ActionBuildTransaction]) -> ActionBuildState {
        switch (self) {
            case let .idle(possibleActions, dragDropSources):
                return self.advanceStateIdle(
                    player: player,
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropSources: dragDropSources
                )
            case let .simpleActionDragging(possibleActions, dragDropDestinations):
                return self.advanceStateSimpleActionDragging(
                    player: player,
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropDestinations: dragDropDestinations
                )
            case let .complexActionIdle(possibleActions, dragDropSources):
                return self.advanceStateComplexActionIdle(
                    player: player,
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropSources: dragDropSources
                )
            case let .complexActionDragging(possibleActions, dragDropDestinations):
                return self.advanceStateComplexActionDragging(
                    player: player,
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropDestinations: dragDropDestinations
                )
            case .finished:
                fatalError()
        }
    }
    
    private func advanceStateIdle(player: Player, transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropSources: Set<DragDropSite>) -> ActionBuildState {
        guard case let .drag(source, _) = transactions.last!, dragDropSources.contains(source) else {
            fatalError()
        }
            
        let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(player: player, transactions: transactions) })
        let validDestinations = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropDestinations(player: player, transactions: transactions)) })
        return .simpleActionDragging(remainingActions, validDestinations)
    }

    private func advanceStateSimpleActionDragging(player: Player, transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropDestinations: Set<DragDropSite>) -> ActionBuildState {
        guard case let .drop(destination) = transactions.last!, dragDropDestinations.contains(destination) else {
            fatalError()
        }
    
        // One dragon drop should be able to get down to exactly one possible
        // action, with the exception of laying down vs laying down with a
        // discard, which is ambiguous if the player is still able to draw from
        // the discard pile and use the card
        let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(player: player, transactions: transactions) })
        guard (remainingActions.count == 1) || (remainingActions.count == 2 && remainingActions.contains(.layDownInitialBooks) && remainingActions.contains(.drawFromDiscardPileAndLayDownInitialBooks)) else {
            fatalError()
        }
    
        if remainingActions.first!.isComplex {
            let validSources = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources(player: player, transactions: transactions)) })
            return .complexActionIdle(remainingActions, validSources)
        } else {
            return .finished(remainingActions)
        }
    }

    private func advanceStateComplexActionIdle(player: Player, transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropSources: Set<DragDropSite>) -> ActionBuildState {
        switch (transactions.last!) {
            case let .drag(source, _):
                guard dragDropSources.contains(source) else {
                    fatalError()
                }
            
                let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(player: player, transactions: transactions) })
                guard remainingActions.count > 0 else {
                    fatalError()
                }
            
                let validDestinations = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropDestinations(player: player, transactions: transactions)) })
                return .complexActionDragging(remainingActions, validDestinations)
            case .drop:
                fatalError()
            case .done:
                return .finished(possibleActions)
        }
    }

    private func advanceStateComplexActionDragging(player: Player, transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropDestinations: Set<DragDropSite>) -> ActionBuildState {
        guard case let .drop(destination) = transactions.last!, dragDropDestinations.contains(destination) else {
            fatalError()
        }

        let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(player: player, transactions: transactions) })
        guard remainingActions.count > 0 else {
            fatalError()
        }
    
        let validSources = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources(player: player, transactions: transactions)) })
        return .complexActionIdle(remainingActions, validSources)
    }
}

class ActionBuilder {
    
    private var game: Game
    private var player: Player
    private var transactions: [ActionBuildTransaction]

    private(set) var state: ActionBuildState
    private(set) var draggedCardsBySource: [DragDropSite : [Card]]
    private(set) var droppedCardsByDestination: [DragDropSite : [Card]]
    private(set) var activeDragSource: DragDropSite?
    
    init(game: Game, player: Player) {
        self.game = game
        self.player = player
        self.transactions = []
        self.state = .idle(Set<PossibleAction>(), Set<DragDropSite>())
        self.draggedCardsBySource = [DragDropSite : [Card]]()
        self.droppedCardsByDestination = [DragDropSite : [Card]]()
        
        self.reset(game: self.game, player: self.player)
    }
    
    func reset(game: Game, player: Player) {
        self.game = game
        self.player = player
        self.transactions = []

        let possibleActions = self.initialPossibleActions()
        let dragDropSources = possibleActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources(player: self.player, transactions: self.transactions)) })
        self.state = .idle(possibleActions, dragDropSources)
        
        // TODO: Should these things be part of ActionBuildState? They're
        //       required by the UI side of things just like the other parts
        //       of ActionBuildState cases
        //       Or maybe remove the associated values from ActionBuildState and
        //       move them into ActionBuilder if the state is getting more complex
        self.draggedCardsBySource = [DragDropSite : [Card]]()
        self.droppedCardsByDestination = [DragDropSite : [Card]]()
        self.activeDragSource = nil
    }
    
    func addTransaction(_ transaction: ActionBuildTransaction) {
        switch (transaction) {
            case let .drag(source, cards):
                if self.draggedCardsBySource[source] == nil {
                    self.draggedCardsBySource[source] = []
                }
                
                self.draggedCardsBySource[source]!.append(contentsOf: cards)
                self.activeDragSource = source
            case let .drop(destination):
                guard case let .drag(_, cards) = self.transactions.last! else {
                    fatalError()
                }
                
                if self.droppedCardsByDestination[destination] == nil {
                    self.droppedCardsByDestination[destination] = []
                }
                
                self.droppedCardsByDestination[destination]!.append(contentsOf: cards)
                self.activeDragSource = nil
            default:
                self.activeDragSource = nil
        }
        
        self.transactions.append(transaction)
        self.state = self.state.advanceState(player: self.player, transactions: self.transactions)
    }
    
    func cancelLastDrag() {
        guard let lastTransaction = self.transactions.last, case .drag = lastTransaction else {
            fatalError()
        }
        
        // TODO: Kinda weird to reset and replay, not sure how else to do this
        _ = self.transactions.popLast()
        let transactions = self.transactions
        self.reset(game: self.game, player: self.player)
        
        for transaction in transactions {
            self.addTransaction(transaction)
        }
    }
    
    private func initialPossibleActions() -> Set<PossibleAction> {
        guard self.game.isCurrentPlayer(player) else {
            return Set<PossibleAction>()
        }

        var possibleActions = Set<PossibleAction>(PossibleAction.allCases)
        possibleActions = possibleActions.filter({ !$0.isDisqualifiedBy(player: self.player, transactions: self.transactions) })
        
        return possibleActions
    }
    
    func buildAction() -> Action? {
        guard case let .finished(possibleActions) = self.state else {
            return nil
        }
        
        var action: Action?
        
        if possibleActions.contains(.drawFromDeck) {
            action = .drawFromDeck(player.name)
        } else if possibleActions.contains(.drawFromDiscardPileAndAddToBook) {
            var bookRank: CardRank?
            
            for transaction in self.transactions {
                if case let .drop(destination) = transaction {
                    if case let .book(rank) = destination {
                        bookRank = rank
                    }
                }
            }
            
            action = .drawFromDiscardPileAndAddToBook(player.name, bookRank!)
        } else if possibleActions.contains(.drawFromDiscardPileAndCreateBook) {
            var cards = [Card]()
            
            var dragCards: [Card]?
            for transaction in self.transactions {
                if case let .drag(_, cards) = transaction {
                    dragCards = cards
                } else if case let .drop(destination) = transaction {
                    if case .book = destination {
                        cards.append(contentsOf: dragCards!)
                    }

                    dragCards = nil
                }
            }

            action = .drawFromDiscardPileAndCreateBook(player.name, cards)
        } else if possibleActions.contains(.discardCard) {
            var card: Card?
            
            for transaction in self.transactions {
                if case let .drag(_, cards) = transaction, cards.count == 1 {
                    card = cards.first!
                }
            }
            
            action = .discardCard(player.name, card!)
        } else if possibleActions.contains(.layDownInitialBooks) || possibleActions.contains(.drawFromDiscardPileAndLayDownInitialBooks) {
            var booksCards = [CardRank : [Card]]()
            
            var dragCards: [Card]?
            for transaction in self.transactions {
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
            action = .layDownInitialBooks(player.name, books)
        } else if possibleActions.contains(.startBook) {
            var cards = [Card]()
            
            var dragCards: [Card]?
            for transaction in self.transactions {
                if case let .drag(_, cards) = transaction {
                    dragCards = cards
                } else if case let .drop(destination) = transaction {
                    if case .book = destination {
                        cards.append(contentsOf: dragCards!)
                    }

                    dragCards = nil
                }
            }

            action = .startBook(player.name, cards)
        } else if possibleActions.contains(.addCardFromHandToBook) {
            var card: Card?
            var bookRank: CardRank?
            
            for transaction in self.transactions {
                if case let .drag(_, cards) = transaction, cards.count == 1 {
                    card = cards.first!
                } else if case let .drop(destination) = transaction {
                    if case let .book(rank) = destination {
                        bookRank = rank
                    }
                }
            }
            
            action = .addCardFromHandToBook(player.name, card!, bookRank!)
        }
        
        return action
    }
}
