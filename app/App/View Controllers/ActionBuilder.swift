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

class ActionBuilder {
    
    private var transactions: [ActionBuildTransaction]
    
    init() {
        self.transactions = []
    }
    
    func clearTransactions() {
        self.transactions = []
    }
    
    func addTransaction(_ transaction: ActionBuildTransaction) {
        self.transactions.append(transaction)
    }
    
    func cancelLastDrag() {
        guard let lastTransaction = self.transactions.last, case .drag = lastTransaction else {
            fatalError()
        }
        
        _ = self.transactions.popLast()
    }

    // TODO: This function signature is gross
    func getState(game: Game, player: Player) -> (ActionBuildState, [DragDropSite : [Card]], [DragDropSite : [Card]], DragDropSite?) {
        let possibleActions = self.initialPossibleActions(game: game, player: player)
        let dragDropSources = possibleActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources()) })
        var state = ActionBuildState.idle(possibleActions, dragDropSources)

        var draggedCards = [DragDropSite : [Card]]()
        var droppedCards = [DragDropSite : [Card]]()
        var lastDraggedCards: [Card]?
        var activeDragSource: DragDropSite?
        
        for transaction in self.transactions {
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
        
        return (state, draggedCards, droppedCards, activeDragSource)
    }
    
    private func initialPossibleActions(game: Game, player: Player) -> Set<PossibleAction> {
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
    
    func buildAction(game: Game, player: Player) -> Action? {
        // TODO: getState gets called more than once with how this is currently
        //       used by GameViewController

        let (state, _, _, _) = self.getState(game: game, player: player)
        guard case let .finished(possibleActions) = state else {
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
