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
    
    func dragDropSources(transactions: [ActionBuildTransaction]) -> Set<DragDropSite> {
        var validSources = Set<DragDropSite>()
        
        switch (self) {
            case .drawFromDeck:
                // Deck is always the source, always valid if this action is possible
                validSources.insert(.deck)
            case .drawFromDiscardPileAndAddToBook:
                // Discard pile is always the source, always valid if this action is possible
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
    
    func dragDropDestinations(transactions: [ActionBuildTransaction]) -> Set<DragDropSite> {
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
    
    func isDisqualifiedBy(transactions: [ActionBuildTransaction]) -> Bool {
        // TODO: Take the cards into account for books and all that
        // TODO: Merge the destination one
        
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
    
    func advanceState(given transactions: [ActionBuildTransaction]) -> ActionBuildState {
        switch (self) {
            case let .idle(possibleActions, dragDropSources):
                return self.advanceStateIdle(
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropSources: dragDropSources
                )
            case let .simpleActionDragging(possibleActions, dragDropDestinations):
                return self.advanceStateSimpleActionDragging(
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropDestinations: dragDropDestinations
                )
            case let .complexActionIdle(possibleActions, dragDropSources):
                return self.advanceStateComplexActionIdle(
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropSources: dragDropSources
                )
            case let .complexActionDragging(possibleActions, dragDropDestinations):
                return self.advanceStateComplexActionDragging(
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropDestinations: dragDropDestinations
                )
            case .finished:
                fatalError()
        }
    }
    
    private func advanceStateIdle(transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropSources: Set<DragDropSite>) -> ActionBuildState {
        guard case let .drag(source, _) = transactions.last!, dragDropSources.contains(source) else {
            fatalError()
        }
            
        let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(transactions: transactions) })
        let validDestinations = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropDestinations(transactions: transactions)) })
        return .simpleActionDragging(remainingActions, validDestinations)
    }

    private func advanceStateSimpleActionDragging(transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropDestinations: Set<DragDropSite>) -> ActionBuildState {
        guard case let .drop(destination) = transactions.last!, dragDropDestinations.contains(destination) else {
            fatalError()
        }
    
        // One dragon drop should be able to get down to exactly one possible
        // action, with the exception of laying down vs laying down with a
        // discard, which is ambiguous if the player is still able to draw from
        // the discard pile and use the card
        let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(transactions: transactions) })
        guard (remainingActions.count == 1) || (remainingActions.count == 2 && remainingActions.contains(.layDownInitialBooks) && remainingActions.contains(.drawFromDiscardPileAndLayDownInitialBooks)) else {
            fatalError()
        }
    
        if remainingActions.first!.isComplex {
            let validSources = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources(transactions: transactions)) })
            return .complexActionIdle(remainingActions, validSources)
        } else {
            return .finished(remainingActions)
        }
    }

    private func advanceStateComplexActionIdle(transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropSources: Set<DragDropSite>) -> ActionBuildState {
        switch (transactions.last!) {
            case let .drag(source, _):
                guard dragDropSources.contains(source) else {
                    fatalError()
                }
            
                let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(transactions: transactions) })
                guard remainingActions.count > 0 else {
                    fatalError()
                }
            
                let validDestinations = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropDestinations(transactions: transactions)) })
                return .complexActionDragging(remainingActions, validDestinations)
            case .drop:
                fatalError()
            case .done:
                return .finished(possibleActions)
        }
    }

    private func advanceStateComplexActionDragging(transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropDestinations: Set<DragDropSite>) -> ActionBuildState {
        guard case let .drop(destination) = transactions.last!, dragDropDestinations.contains(destination) else {
            fatalError()
        }

        let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(transactions: transactions) })
        guard remainingActions.count > 0 else {
            fatalError()
        }
    
        let validSources = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources(transactions: transactions)) })
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

        let possibleActions = self.initialPossibleActions(game: game, player: player)
        let dragDropSources = possibleActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources(player: self.player, transactions: self.transactions)) })
        self.state = .idle(possibleActions, dragDropSources)
        
        // TODO: Should these things be part of ActionBuildState? They're
        //       required by the UI side of things just like the other parts
        //       of ActionBuildState cases
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
    
    private func initialPossibleActions(game: Game, player: Player) -> Set<PossibleAction> {
        // TODO: Should all of this logic be in PossibleAction instead?
        
        var possibleActions = Set<PossibleAction>()
        
        guard game.isCurrentPlayer(player) else {
            return possibleActions
        }
        
        if player.canDrawFromDeck {
            possibleActions.insert(.drawFromDeck)
        }

        if player.hasLaidDownThisRound, player.canDrawFromDiscardPile {
            possibleActions.insert(.drawFromDiscardPileAndAddToBook)
        }
        
        if player.hasLaidDownThisRound, player.canDrawFromDiscardPile {
            possibleActions.insert(.drawFromDiscardPileAndCreateBook)
        }
        
        if player.canEndTurn {
            possibleActions.insert(.discardCard)
        }
        
        if !player.hasLaidDownThisRound {
            possibleActions.insert(.layDownInitialBooks)
        }
        
        if !player.hasLaidDownThisRound, player.canDrawFromDiscardPile {
            possibleActions.insert(.drawFromDiscardPileAndLayDownInitialBooks)
        }
        
        if player.hasLaidDownThisRound {
            possibleActions.insert(.startBook)
        }
        
        if player.hasLaidDownThisRound {
            possibleActions.insert(.addCardFromHandToBook)
        }
        
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
