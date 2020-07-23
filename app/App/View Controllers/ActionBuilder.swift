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
    case drawFromDiscardPileAndStartBook
    case discardCard
    case layDownInitialBooks
    case drawFromDiscardPileAndLayDownInitialBooks
    case startBook
    case addCardsFromHandToBook
    
    var isComplex: Bool {
        switch (self) {
            case .drawFromDeck:
                return false
            case .drawFromDiscardPileAndAddToBook:
                return false
            case .drawFromDiscardPileAndStartBook:
                return true
            case .discardCard:
                return false
            case .layDownInitialBooks:
                return true
            case .drawFromDiscardPileAndLayDownInitialBooks:
                return true
            case .startBook:
                return true
            case .addCardsFromHandToBook:
                return false
        }
    }
    
    func dragDropSources(game: Game, player: Player, transactions: [ActionBuildTransaction]) -> Set<DragDropSite> {
        var validSources = Set<DragDropSite>()
        
        switch (self) {
            case .drawFromDeck:
                validSources.insert(.deck)
            case .drawFromDiscardPileAndAddToBook:
                validSources.insert(.discardPile)
            case .drawFromDiscardPileAndStartBook:
                validSources.insert(.discardPile)
                validSources.insert(.hand)
                
                for transaction in transactions {
                    if case let .drag(source, _) = transaction, source == .discardPile {
                        validSources.remove(.discardPile)
                        break
                    }
                }
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
            case .addCardsFromHandToBook:
                validSources.insert(.hand)
        }
        
        return validSources
    }
    
    func dragDropDestinations(game: Game, player: Player, transactions: [ActionBuildTransaction]) -> Set<DragDropSite> {
        guard case let .drag(_, lastDragCards) = transactions.last! else {
            fatalError()
        }
        
        var validDestinations = Set<DragDropSite>()
        
        switch (self) {
            case .drawFromDeck:
                validDestinations.insert(.hand)
            case .drawFromDiscardPileAndAddToBook:
                // TODO: Fancy logic to prevent building invalid books (too many wild cards)

                guard lastDragCards.count == 1 else {
                    break
                }
                
                let card = lastDragCards.first!

                if let cardRank = card.bookRank {
                    let existingBookRanks = player.books[game.round!]!.keys
                    if existingBookRanks.contains(cardRank) {
                        validDestinations.insert(.book(cardRank))
                    }
                } else if card.isWild {
                    validDestinations.formUnion(self.existingBookDestinations(game: game, player: player))
                }
            case .drawFromDiscardPileAndStartBook:
                // Need to be dragging at least one card
                // If the cards aren't playable together, skip
                // If there's already been a drop on a book destination and the
                //   book rank of the dragged cards matches, insert that destination
                // If the book rank of the dragged cards is one that the player
                //   doesn't already have, insert that destination
                // TODO: Fancy logic to prevent building invalid books (too many wild cards)
                
                guard lastDragCards.count > 0 else {
                    break
                }
                
                guard self.cardsArePlayableTogether(lastDragCards) else {
                    break
                }
                
                var partialBookRank: CardRank?
                for transaction in transactions {
                    if case let .drop(destination) = transaction, case let .book(bookRank) = destination {
                        partialBookRank = bookRank
                        break
                    }
                }
                
                let lastDragCardsBookRank = self.bookRankOf(lastDragCards)
                let newBookDestinations = self.newBookDestinations(game: game, player: player)
                
                if let partialBookRank = partialBookRank {
                    if let lastDragCardsBookRank = lastDragCardsBookRank, lastDragCardsBookRank == partialBookRank {
                        validDestinations.insert(.book(partialBookRank))
                    } else if self.cardsAreWild(lastDragCards) {
                        validDestinations.insert(.book(partialBookRank))
                    }
                } else if let lastDragCardsBookRank = lastDragCardsBookRank, newBookDestinations.contains(.book(lastDragCardsBookRank)) {
                    validDestinations.insert(.book(lastDragCardsBookRank))
                } else if self.cardsAreWild(lastDragCards) {
                    validDestinations.formUnion(newBookDestinations)
                }
            case .discardCard:
                guard lastDragCards.count == 1 else {
                    break
                }
                
                validDestinations.insert(.discardPile)
            case .layDownInitialBooks:
                // Need to be dragging at least one card
                // If the cards being dragged aren't playable together, skip
                // If the cards being dragged are wild, insert all book destinations
                // Otherwise, insert the book rank of the cards being dragged
                // TODO: Fancy logic to prevent building invalid books (too many wild cards)
                
                guard lastDragCards.count > 0 else {
                    break
                }
                
                guard self.cardsArePlayableTogether(lastDragCards) else {
                    break
                }
                
                if self.cardsAreWild(lastDragCards) {
                    validDestinations.formUnion(DragDropSite.allBookCases)
                } else {
                    validDestinations.insert(.book(self.bookRankOf(lastDragCards)!))
                }
            case .drawFromDiscardPileAndLayDownInitialBooks:
                // Need to be dragging at least one card
                // If the cards being dragged aren't playable together, skip
                // If the cards being dragged are wild, insert all book destinations
                // Otherwise, insert the book rank of the cards being dragged
                // TODO: Fancy logic to prevent building invalid books (too many wild cards)
                
                guard lastDragCards.count > 0 else {
                    break
                }
                
                guard self.cardsArePlayableTogether(lastDragCards) else {
                    break
                }

                if self.cardsAreWild(lastDragCards) {
                    validDestinations.formUnion(DragDropSite.allBookCases)
                } else {
                    validDestinations.insert(.book(self.bookRankOf(lastDragCards)!))
                }
            case .startBook:
                // Need to be dragging at least one card
                // If the cards aren't playable together, skip
                // If there's already been a drop on a book destination and the
                //   book rank of the dragged cards matches, insert that destination
                // If the book rank of the dragged cards is one that the player
                //   doesn't already have, insert that destination
                // TODO: If the cards being dragged are only wild, insert all
                //   book destiations that player doesn't already have
                // TODO: Fancy logic to prevent building invalid books (too many wild cards)
                
                guard lastDragCards.count > 0 else {
                    break
                }
                
                guard self.cardsArePlayableTogether(lastDragCards) else {
                    break
                }

                var partialBookRank: CardRank?
                for transaction in transactions {
                    if case let .drop(destination) = transaction, case let .book(bookRank) = destination {
                        partialBookRank = bookRank
                        break
                    }
                }
                
                let lastDragCardsBookRank = self.bookRankOf(lastDragCards)
                let newBookDestinations = self.newBookDestinations(game: game, player: player)
                
                if let partialBookRank = partialBookRank {
                    if let lastDragCardsBookRank = lastDragCardsBookRank, lastDragCardsBookRank == partialBookRank {
                        validDestinations.insert(.book(partialBookRank))
                    } else if self.cardsAreWild(lastDragCards) {
                        validDestinations.insert(.book(partialBookRank))
                    }
                } else if let lastDragCardsBookRank = lastDragCardsBookRank, newBookDestinations.contains(.book(lastDragCardsBookRank)) {
                    validDestinations.insert(.book(lastDragCardsBookRank))
                } else if self.cardsAreWild(lastDragCards) {
                    validDestinations.formUnion(newBookDestinations)
                }
            case .addCardsFromHandToBook:
                // Need to be dragging at least one card
                // If the cards aren't playable together, skip
                // If the cards are wild, insert all existing books
                // Otherwise, insert the cards' book rank if the book exists
                // TODO: Fancy logic to prevent building invalid books (too many wild cards)
                
                guard lastDragCards.count > 0 else {
                    break
                }
                
                guard self.cardsArePlayableTogether(lastDragCards) else {
                    break
                }
                
                let existingBookRanks = player.books[game.round!]!.keys
                
                if self.cardsAreWild(lastDragCards) {
                    for bookRank in existingBookRanks {
                        validDestinations.insert(.book(bookRank))
                    }
                } else {
                    let lastDragCardsBookRank = self.bookRankOf(lastDragCards)!
                    if existingBookRanks.contains(lastDragCardsBookRank) {
                        validDestinations.insert(.book(lastDragCardsBookRank))
                    }
                }
        }
        
        return validDestinations
    }
    
    func isDisqualifiedBy(game: Game, player: Player, transactions: [ActionBuildTransaction]) -> Bool {
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
                // * Drop can only go to an existing book
                // * There can only be one drag and one drop
                
                guard player.canDrawFromDiscardPile,
                      player.hasLaidDownThisRound,
                      self.dragsOnlyStartFrom(transactions, dragSources: [.discardPile]),
                      self.dragsOnlyContainPlayableCards(transactions),
                      self.dropsOnlyGoToExistingBooks(transactions, game: game, player: player),
                      self.atMostOneDragDropPairIn(transactions) else {
                    return true
                }
                
                return false
            case .drawFromDiscardPileAndStartBook:
                // * Need to be able to draw from the discard pile
                // * Need to have already laid down
                // * All good if there aren't any transactions
                // * Drags can only be from the discard pile or the hand
                // * Drags must only have playable cards (no threes)
                //  - Same note as above with checking what's on the discard pile
                // * There can only be drag from the discard pile
                //  - Might enforce this in the dragDropSources/Destinations
                // * Drops can only go to books, and only one book, and it must
                //   be a book that doesn't already exist
                
                guard player.canDrawFromDiscardPile,
                      player.hasLaidDownThisRound,
                      self.dragsOnlyStartFrom(transactions, dragSources: [.discardPile, .hand]),
                      self.dragsOnlyContainPlayableCards(transactions),
                      self.dropsOnlyGoToNewBooks(transactions, game: game, player: player),
                      self.dropsOnlyGoToOneBook(transactions) else {
                    return true
                }
                
                return false
            case .discardCard:
                // * Need to be able to end turn
                // * All good if there aren't any transactions
                // * Drag can only be from the hand
                // * Drop can only go to the discard pile
                // * There can only be one drag and one drop
                
                guard player.canEndTurn,
                      self.dragsOnlyStartFrom(transactions, dragSources: [.hand]),
                      self.dropsOnlyGoTo(transactions, dropDestinations: [.discardPile]),
                      self.atMostOneDragDropPairIn(transactions) else {
                    return true
                }
                
                return false
            case .layDownInitialBooks:
                // * Need to have not laid down yet
                // * All good if there aren't any transactions
                // * Drags can only start from the hand
                // * Drags must only have playable cards (no threes)
                // * Drops can only go to books
                
                guard !player.hasLaidDownThisRound,
                      self.dragsOnlyStartFrom(transactions, dragSources: [.hand]),
                      self.dragsOnlyContainPlayableCards(transactions),
                      self.dropsOnlyGoTo(transactions, dropDestinations: DragDropSite.allBookCases) else {
                    return true
                }
                
                return false
            case .drawFromDiscardPileAndLayDownInitialBooks:
                // * Need to be able to draw from the discard pile
                // * Need to have not laid down yet
                // * All good if there aren't any transactions
                // * Drags can only start from the discard pile or the hand
                // * There can only be one drag from the discard pile
                //   - Might enforce this in dragDropSources/Destinations
                // * Drags must only have playable cards (no threes)
                // * Drops can only go to books
                
                guard player.canDrawFromDiscardPile,
                      !player.hasLaidDownThisRound,
                      self.dragsOnlyStartFrom(transactions, dragSources: [.discardPile, .hand]),
                      self.dragsOnlyContainPlayableCards(transactions),
                      self.dropsOnlyGoTo(transactions, dropDestinations: DragDropSite.allBookCases) else {
                    return true
                }
                
                return false
            case .startBook:
                // * Need to have laid down already
                // * All good if there aren't any transactions
                // * Drags can only start from the hand
                // * Drags must only have playable cards (no threes)
                // * Drops can only go to books, and only one book, and that book
                //   must not already exist
                
                guard player.hasLaidDownThisRound,
                      self.dragsOnlyStartFrom(transactions, dragSources: [.hand]),
                      self.dragsOnlyContainPlayableCards(transactions),
                      self.dropsOnlyGoToNewBooks(transactions, game: game, player: player),
                      self.dropsOnlyGoToOneBook(transactions) else {
                    return true
                }
                
                return false
            case .addCardsFromHandToBook:
                // * Need to have laid down already
                // * All good if there aren't any transactions
                // * Drag can only start from the hand
                // * Drag must only have playable cards (no threes)
                // * Drop can only go to an existing book
                // * There can only be one drag and one drop
                
                guard player.hasLaidDownThisRound,
                      self.dragsOnlyStartFrom(transactions, dragSources: [.hand]),
                      self.dragsOnlyContainPlayableCards(transactions),
                      self.dropsOnlyGoToExistingBooks(transactions, game: game, player: player),
                      self.atMostOneDragDropPairIn(transactions) else {
                    return true
                }
                
                return false
        }
    }
    
    private func cardsArePlayableTogether(_ cards: [Card]) -> Bool {
        for card in cards {
            if !card.isPlayable {
                return false
            }
        }
        
        var firstBookRank: CardRank?
    
        for card in cards {
            if !card.isWild {
                if let firstBookRank = firstBookRank {
                    if card.rank != firstBookRank {
                        return false
                    }
                } else {
                    firstBookRank = card.rank
                }
            }
        }
        
        return true
    }
    
    private func bookRankOf(_ cards: [Card]) -> CardRank? {
        for card in cards {
            if !card.isPlayable {
                return nil
            }
        }
        
        var bookRank: CardRank?
    
        for card in cards {
            if !card.isWild {
                if let bookRank = bookRank {
                    if card.rank != bookRank {
                        return nil
                    }
                } else {
                    bookRank = card.rank
                }
            }
        }
        
        return bookRank
    }
    
    private func cardsAreWild(_ cards: [Card]) -> Bool {
        return (cards.filter({ !$0.isWild }).count == 0)
    }
    
    private func existingBookDestinations(game: Game, player: Player) -> Set<DragDropSite> {
        let existingBooks = player.books[game.round!]!.keys
        let destinations = Set<DragDropSite>(existingBooks.map( { DragDropSite.book($0) } ))
        
        return destinations
    }
    
    private func newBookDestinations(game: Game, player: Player) -> Set<DragDropSite> {
        let existingBooks = player.books[game.round!]!.keys
        let newBooks = CardRank.bookableCases.filter({ !existingBooks.contains($0 )})
        let destinations = Set<DragDropSite>(newBooks.map( { DragDropSite.book($0) } ))
        
        return destinations
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
    
    private func dropsOnlyGoToExistingBooks(_ transactions: [ActionBuildTransaction], game: Game, player: Player) -> Bool {
        return self.dropsOnlyGoTo(transactions, dropDestinations: self.existingBookDestinations(game: game, player: player))
    }
    
    private func dropsOnlyGoToNewBooks(_ transactions: [ActionBuildTransaction], game: Game, player: Player) -> Bool {
        return self.dropsOnlyGoTo(transactions, dropDestinations: self.newBookDestinations(game: game, player: player))
    }
    
    private func dropsOnlyGoToOneBook(_ transactions: [ActionBuildTransaction]) -> Bool {
        var firstBookSeen: DragDropSite?
        
        for transaction in transactions {
            if case let .drop(destination) = transaction, case .book = destination {
                if firstBookSeen == nil {
                    firstBookSeen = destination
                } else {
                    if destination != firstBookSeen {
                        return false
                    }
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
    
    func advanceState(game: Game, player: Player, transactions: [ActionBuildTransaction]) -> ActionBuildState {
        switch (self) {
            case let .idle(possibleActions, dragDropSources):
                return self.advanceStateIdle(
                    game: game,
                    player: player,
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropSources: dragDropSources
                )
            case let .simpleActionDragging(possibleActions, dragDropDestinations):
                return self.advanceStateSimpleActionDragging(
                    game: game,
                    player: player,
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropDestinations: dragDropDestinations
                )
            case let .complexActionIdle(possibleActions, dragDropSources):
                return self.advanceStateComplexActionIdle(
                    game: game,
                    player: player,
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropSources: dragDropSources
                )
            case let .complexActionDragging(possibleActions, dragDropDestinations):
                return self.advanceStateComplexActionDragging(
                    game: game,
                    player: player,
                    transactions: transactions,
                    possibleActions: possibleActions,
                    dragDropDestinations: dragDropDestinations
                )
            case .finished:
                fatalError()
        }
    }
    
    private func advanceStateIdle(game: Game, player: Player, transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropSources: Set<DragDropSite>) -> ActionBuildState {
        guard case let .drag(source, _) = transactions.last!, dragDropSources.contains(source) else {
            fatalError()
        }
            
        let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(game: game, player: player, transactions: transactions) })
        let validDestinations = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropDestinations(game: game, player: player, transactions: transactions)) })
        return .simpleActionDragging(remainingActions, validDestinations)
    }

    private func advanceStateSimpleActionDragging(game: Game, player: Player, transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropDestinations: Set<DragDropSite>) -> ActionBuildState {
        guard case let .drop(destination) = transactions.last!, dragDropDestinations.contains(destination) else {
            fatalError()
        }
    
        // One dragon drop should be able to get down to exactly one possible
        // action, with the exception of complex actions that have a
        // draw-from-discard-pile counterpart (laying down, starting a book)
        let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(game: game, player: player, transactions: transactions) })
        guard (remainingActions.count == 1) ||
              (remainingActions.count == 2 && remainingActions.contains(.layDownInitialBooks) && remainingActions.contains(.drawFromDiscardPileAndLayDownInitialBooks)) ||
              (remainingActions.count == 2 && remainingActions.contains(.startBook) && remainingActions.contains(.drawFromDiscardPileAndStartBook)) else {
            fatalError()
        }
    
        if remainingActions.first!.isComplex {
            let validSources = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources(game: game, player: player, transactions: transactions)) })
            return .complexActionIdle(remainingActions, validSources)
        } else {
            return .finished(remainingActions)
        }
    }

    private func advanceStateComplexActionIdle(game: Game, player: Player, transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropSources: Set<DragDropSite>) -> ActionBuildState {
        switch (transactions.last!) {
            case let .drag(source, _):
                guard dragDropSources.contains(source) else {
                    fatalError()
                }
            
                let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(game: game, player: player, transactions: transactions) })
                guard remainingActions.count > 0 else {
                    fatalError()
                }
            
                let validDestinations = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropDestinations(game: game, player: player, transactions: transactions)) })
                return .complexActionDragging(remainingActions, validDestinations)
            case .drop:
                fatalError()
            case .done:
                return .finished(possibleActions)
        }
    }

    private func advanceStateComplexActionDragging(game: Game, player: Player, transactions: [ActionBuildTransaction], possibleActions: Set<PossibleAction>, dragDropDestinations: Set<DragDropSite>) -> ActionBuildState {
        guard case let .drop(destination) = transactions.last!, dragDropDestinations.contains(destination) else {
            fatalError()
        }

        let remainingActions = possibleActions.filter({ !$0.isDisqualifiedBy(game: game, player: player, transactions: transactions) })
        guard remainingActions.count > 0 else {
            fatalError()
        }
    
        let validSources = remainingActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources(game: game, player: player, transactions: transactions)) })
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
        let dragDropSources = possibleActions.reduce(Set<DragDropSite>(), { $0.union($1.dragDropSources(game: self.game, player: self.player, transactions: self.transactions)) })
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
        self.state = self.state.advanceState(game: self.game, player: self.player, transactions: self.transactions)
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
        possibleActions = possibleActions.filter({ !$0.isDisqualifiedBy(game: self.game, player: self.player, transactions: self.transactions) })
        
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
            var discardPileBookRank: CardRank?
            var lastDragWasFromDiscardPile = false
            
            for transaction in self.transactions {
                if case let .drag(source, cards) = transaction {
                    dragCards = cards
                    lastDragWasFromDiscardPile = (source == .discardPile)
                } else if case let .drop(destination) = transaction {
                    if case let .book(rank) = destination {
                        if !lastDragWasFromDiscardPile {
                            if booksCards[rank] == nil {
                                booksCards[rank] = []
                            }
                            
                            booksCards[rank]?.append(contentsOf: dragCards!)
                        } else {
                            discardPileBookRank = rank
                        }
                    }

                    dragCards = nil
                    lastDragWasFromDiscardPile = false
                }
            }
            
            var discardPileBook: [Card]?
            if let discardPileBookRank = discardPileBookRank {
                discardPileBook = booksCards[discardPileBookRank]!
                booksCards.removeValue(forKey: discardPileBookRank)
            }
            
            let books = Array(booksCards.values)
            
            if let discardPileBook = discardPileBook {
                action = .drawFromDiscardPileAndLayDownInitialBooks(player.name, discardPileBook, books)
            } else {
                action = .layDownInitialBooks(player.name, books)
            }
        } else if possibleActions.contains(.startBook) || possibleActions.contains(.drawFromDiscardPileAndStartBook) {
            var cards = [Card]()
            
            var dragCards: [Card]?
            var didUseDiscardPile = false
            var lastDragWasFromDiscardPile = false

            for transaction in self.transactions {
                if case let .drag(source, cards) = transaction {
                    dragCards = cards
                    
                    lastDragWasFromDiscardPile = (source == .discardPile)
                    if lastDragWasFromDiscardPile {
                        didUseDiscardPile = true
                    }
                } else if case let .drop(destination) = transaction {
                    if !lastDragWasFromDiscardPile, case .book = destination {
                        cards.append(contentsOf: dragCards!)
                    }

                    dragCards = nil
                    lastDragWasFromDiscardPile = false
                }
            }

            if didUseDiscardPile {
                action = .drawFromDiscardPileAndStartBook(player.name, cards)
            } else {
                action = .startBook(player.name, cards)
            }
        } else if possibleActions.contains(.addCardsFromHandToBook) {
            var dragCards: [Card]?
            var bookRank: CardRank?
            
            for transaction in self.transactions {
                if case let .drag(_, cards) = transaction, cards.count > 0 {
                    dragCards = cards
                } else if case let .drop(destination) = transaction {
                    if case let .book(rank) = destination {
                        bookRank = rank
                    }
                }
            }
            
            action = .addCardsFromHandToBook(player.name, dragCards!, bookRank!)
        }
        
        return action
    }
}
