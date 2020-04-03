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
    
    enum Keys: String {
        case inHand
        case inFoot
        case inBooks
        case laidDown
        case forGoingOut
    }
    
    func toJSON() -> JSONDictionary {
        return [
            Keys.inHand.rawValue : self.inHand,
            Keys.inFoot.rawValue : self.inFoot,
            Keys.inBooks.rawValue : self.inBooks,
            Keys.laidDown.rawValue : self.laidDown,
            Keys.forGoingOut.rawValue : self.forGoingOut
        ]
    }
}

class Player: JSONEncodable {

    let name: String

    private var hand: [Card]
    private var foot: [Card]
    private var books: [CardRank : Book]
    private var points: [Round : Points]
    private var cardsDrawnFromDeck: UInt
    private var cardsDrawnFromDiscardPile: UInt
    
    private(set) var hasLaidDownThisRound: Bool
    
    // MARK: Initialization
    
    init(name: String, hand: [Card], foot: [Card]) throws {
        guard hand.count == 13 && foot.count == 13 else {
            throw IllegalSetupError.initialHandOrFootNotSizedCorrectly
        }
        
        self.name = name
        self.hand = hand
        self.foot = foot
        self.books = [:]
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
    
    var canGoOut: Bool {
        return (self.hasNaturalBook && self.hasUnnaturalBook && self.isInFoot)
    }
    
    var hasNaturalBook: Bool {
        return (self.books.first(where: { $0.value.isComplete && $0.value.isNatural }) != nil)
    }
    
    var hasUnnaturalBook: Bool {
        return (self.books.first(where: { $0.value.isComplete && !$0.value.isNatural }) != nil)
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
        self.points[round]!.inBooks = self.books.reduce(0, { $0 + $1.value.bookValue })
        self.points[round]!.laidDown = self.books.reduce(0, { $0 + $1.value.cardsValue })
    }
    
    func addBonusForGoingOut(in round: Round) {
        self.points[round]!.forGoingOut = 100
    }
    
    // MARK: JSONEncodable
    
    enum Keys: String {
        case name
        case hand
        case foot
        case books
        case points
    }
    
    func toJSON() -> JSONDictionary {
        var booksJson: JSONDictionary = [:]
        self.books.forEach({ booksJson[$0.key.rawValue] = $0.value.toJSON() })

        var pointsJson: JSONDictionary = [:]
        self.points.forEach({ pointsJson[$0.key.rawValue] = $0.value.toJSON() })
        
        return [
            Keys.name.rawValue : self.name,
            Keys.hand.rawValue : self.hand.map({ $0.toJSON() }),
            Keys.foot.rawValue : self.foot.map({ $0.toJSON() }),
            Keys.books.rawValue : booksJson,
            Keys.points.rawValue : pointsJson
        ]
    }
}
