//
//  Player.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

struct Points: JSONEncodable {

    var inHand: Int
    var inFoot: Int
    var inBooks: Int
    var laidDown: Int
    var forGoingOut: Int
    
    init() {
        self.inHand = 0
        self.inFoot = 0
        self.inBooks = 0
        self.laidDown = 0
        self.forGoingOut = 0
    }
    
    func toJSON() -> JSONDictionary {
        return [
            "in_hand" : self.inHand,
            "in_foot" : self.inFoot,
            "in_books" : self.inBooks,
            "laid_down" : self.laidDown,
            "for_going_out" : self.forGoingOut
        ]
    }
}

class Player: JSONEncodable {

    let name: String

    private var hand: [Card]
    private var foot: [Card]
    private var books: [Round : [CardRank : Book]]
    private var points: [Round : Points]
    private var cardsDrawnFromDeck: UInt
    private var cardsDrawnFromDiscardPile: UInt
    
    private(set) var hasLaidDownThisRound: Bool
    
    // MARK: Initialization
    
    init(name: String) {
        self.name = name
        self.hand = []
        self.foot = []

        self.books = [
            .ninety : [:],
            .oneTwenty : [:],
            .oneFifty : [:],
            .oneEighty : [:]
        ]
        
        self.points = [
            .ninety : Points(),
            .oneTwenty : Points(),
            .oneFifty : Points(),
            .oneEighty : Points()
        ]
        
        self.cardsDrawnFromDeck = 0
        self.cardsDrawnFromDiscardPile = 0
        self.hasLaidDownThisRound = false
    }
    
    func setHandAndFoot(hand: [Card], foot: [Card]) throws {
        guard hand.count == 13 && foot.count == 13 else {
            throw IllegalSetupError.initialHandOrFootNotSizedCorrectly
        }
        
        self.hand = hand
        self.foot = foot
    }
    
    // MARK: Computed properties
    
    var canDrawFromDeck: Bool {
        return ((self.cardsDrawnFromDeck + self.cardsDrawnFromDiscardPile) < 2)
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
    
    // MARK: Determining status
    
    func canGoOut(in round: Round) -> Bool {
        return (self.hasNaturalBook(in: round) && self.hasUnnaturalBook(in: round) && self.isInFoot)
    }
    
    func hasNaturalBook(in round: Round) -> Bool {
        return (self.books[round]!.first(where: { $0.value.isComplete && $0.value.isNatural }) != nil)
    }
    
    func hasUnnaturalBook(in round: Round) -> Bool {
        return (self.books[round]!.first(where: { $0.value.isComplete && !$0.value.isNatural }) != nil)
    }
    
    // MARK: Picking up and playing cards
    
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
    
    func addCardToBookFromHand(_ card: Card, in round: Round) throws {
        guard let book = self.books[round]![card.rank] else {
            throw IllegalActionError.playerDoesntHaveBook
        }
        
        try self.removeCardFromHand(card)
        try book.addCard(card)
    }
    
    func addCardToBookFromDiscardPile(_ card: Card, in round: Round) throws {
        guard let book = self.books[round]![card.rank] else {
            throw IllegalActionError.playerDoesntHaveBook
        }

        try book.addCard(card)
        self.cardsDrawnFromDiscardPile += 1
    }
    
    func startBook(with cards: [Card], in round: Round) throws {
        let book = try Book(initialCards: cards)
        
        guard !self.books[round]!.contains(where: { $0.key == book.rank }) else {
            throw IllegalActionError.bookAlreadyExists
        }
        
        for card in cards {
            try self.removeCardFromHand(card)
        }
        
        self.books[round]![book.rank] = book
    }
    
    // MARK: Game state change notifications
    
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
    
    // MARK: Calculating points
    
    func calculatePoints(in round: Round) {
        self.points[round]!.inHand = self.hand.reduce(0, { $0 + ($1.pointValue > 0 ? -$1.pointValue : $1.pointValue) })
        self.points[round]!.inFoot = self.foot.reduce(0, { $0 + ($1.pointValue > 0 ? -$1.pointValue : $1.pointValue) })
        self.points[round]!.inBooks = self.books[round]!.reduce(0, { $0 + $1.value.bookValue })
        self.points[round]!.laidDown = self.books[round]!.reduce(0, { $0 + $1.value.cardsValue })
    }
    
    func addBonusForGoingOut(in round: Round) {
        self.points[round]!.forGoingOut = 100
    }
    
    // MARK: JSONEncodable
    
    func toJSON() -> JSONDictionary {
        var booksJson: JSONDictionary = [:]
        for (round, roundBooks) in self.books {
            var roundBooksJson: JSONDictionary = [:]
            roundBooks.forEach({ roundBooksJson[$0.key.rawValue] = $0.value.toJSON() })
            booksJson[round.rawValue] = roundBooksJson
        }

        var pointsJson: JSONDictionary = [:]
        self.points.forEach({ pointsJson[$0.key.rawValue] = $0.value.toJSON() })
        
        return [
            "name" : self.name,
            "hand" : self.hand.map({ $0.toJSON() }),
            "foot" : self.foot.map({ $0.toJSON() }),
            "books" : booksJson,
            "points" : pointsJson
        ]
    }
}
