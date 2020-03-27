//
//  Player.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

struct PlayerIterator {
    private var players: [Player]
    private var index: Int
    
    var currentPlayer: Player {
        return self.players[self.index]
    }
    
    init() {
        self.players = []
        self.index = 0
    }
    
    mutating func setPlayers(_ players: [Player]) {
        self.players = players
        self.index = self.players.startIndex
    }
    
    mutating func goToNextPlayer() {
        self.index = self.players.index(after: self.index)
        if self.index == self.players.endIndex {
            self.index = self.players.startIndex
        }
    }
    
    func isCurrentPlayer(_ player: Player) -> Bool {
        return (player === self.currentPlayer)
    }
}

class Player {
    let name: String

    private(set) var hand: [Card]
    private(set) var foot: [Card]
    private(set) var books: [CardRank : Book]
    private var cardsDrawnFromDeck: UInt
    private var cardsDrawnFromDiscardPile: UInt
    
    private(set) var hasLaidDownThisRound: Bool
    
    var canDrawFromDeck: Bool {
        return ((self.cardsDrawnFromDeck + cardsDrawnFromDiscardPile) < 2)
    }
    
    var canDrawFromDiscardPile: Bool {
        return ((self.cardsDrawnFromDeck < 2) && (self.cardsDrawnFromDiscardPile < 1))
    }
    
    var isHandEmpty: Bool {
        return self.hand.isEmpty
    }
    
    var isInFoot: Bool {
        return self.foot.isEmpty
    }
    
    var canEndTurn: Bool {
        return ((self.cardsDrawnFromDeck + self.cardsDrawnFromDiscardPile) == 2)
    }
    
    var canGoOut: Bool {
        return (self.hasNaturalBook && self.hasUnnaturalBook && self.isInFoot)
    }
    
    var hasNaturalBook: Bool {
        return (self.books.first(where: { $0.value.isComplete && $0.value.isNatural }) != nil)
    }
    
    var hasUnnaturalBook: Bool {
        return (self.books.first(where: { $0.value.isComplete && !$0.value.isNatural }) != nil)
    }
    
    init(name: String, hand: [Card], foot: [Card]) throws {
        guard hand.count == 13 && foot.count == 13 else {
            throw IllegalActionError.initialHandOrFootNotSizedCorrectly
        }
        
        self.name = name
        self.hand = hand
        self.foot = foot
        self.books = [:]
        
        self.cardsDrawnFromDeck = 0
        self.cardsDrawnFromDiscardPile = 0
        self.hasLaidDownThisRound = false
    }
    
    func addCardToHandFromDeck(_ card: Card) {
        self.hand.append(card)
        self.cardsDrawnFromDeck += 1
    }
    
    func addCardToHandFromDiscardPile(_ card: Card) {
        self.hand.append(card)
        self.cardsDrawnFromDiscardPile += 1
    }
    
    func removeCardFromHand(_ card: Card) throws {
        guard let cardIndex = self.hand.firstIndex(where: { $0 == card }) else {
            throw IllegalActionError.cardNotInHand
        }
        
        self.hand.remove(at: cardIndex)
    }
    
    func addCardToBookFromHand(_ card: Card) throws {
        guard let book = self.books[card.rank] else {
            throw IllegalActionError.playerDoesntHaveBook
        }
        
        try self.removeCardFromHand(card)
        try book.addCard(card)
    }
    
    func addCardToBookFromDiscardPile(_ card: Card) throws {
        guard let book = self.books[card.rank] else {
            throw IllegalActionError.playerDoesntHaveBook
        }

        try book.addCard(card)
        self.cardsDrawnFromDiscardPile += 1
    }
    
    func startBook(with cards: [Card]) throws {
        let book = try Book(initialCards: cards)
        
        guard !self.books.contains(where: { $0.key == book.rank }) else {
            throw IllegalActionError.bookAlreadyExists
        }
        
        for card in cards {
            try self.removeCardFromHand(card)
        }
        
        self.books[book.rank] = book
    }
    
    func laidDown() {
        self.hasLaidDownThisRound = true
    }
    
    func pickUpFoot() {
        self.hand = self.foot
        self.foot = []
    }
    
    func turnEnded() {
        self.cardsDrawnFromDeck = 0
        self.cardsDrawnFromDiscardPile = 0
    }
    
    func roundEnded() {
        self.turnEnded()
        self.hasLaidDownThisRound = false
    }
    
    func addBonusForGoingOut() {
        fatalError("not implemented")
    }
}
