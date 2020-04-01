//
//  Game.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

enum Round: String {
    case ninety
    case oneTwenty
    case oneFifty
    case oneEighty
    
    var pointsNeeded: Int {
        switch (self) {
            case .ninety:
                return 90
            case .oneTwenty:
                return 120
            case .oneFifty:
                return 150
            case .oneEighty:
                return 180
        }
    }
    
    var nextRound: Round? {
        switch (self) {
        case .ninety:
            return .oneTwenty
        case .oneTwenty:
            return .oneFifty
        case .oneFifty:
            return .oneEighty
        case .oneEighty:
            return nil
        }
    }
}

class Game: JSONEncodable {

    private var deck: Deck
    private var discardPile: [Card]
    private var players: [Player]
    private var round: Round?
    private var actions: [Action]
    private var playerIterator: PlayerIterator

    // MARK: Initialization
    
    init(playerNames: [String], deck: Deck? = nil) throws {
        guard playerNames.count >= 2 else {
            throw IllegalSetupError.tooFewPlayers
        }
        
        guard playerNames.count <= 6 else {
            throw IllegalSetupError.tooManyPlayers
        }
        
        if let deck = deck {
            self.deck = deck
        } else {
            let deckCount = playerNames.count + 1
            self.deck = Deck(standardDeckCount: deckCount)
            self.deck.shuffle()
        }
        
        self.discardPile = []
        self.players = []
        self.round = .ninety
        self.actions = []
        
        self.playerIterator = PlayerIterator()
        
        for playerName in playerNames {
            let player = try self.setUpPlayer(name: playerName)
            self.players.append(player)
        }

        self.playerIterator.setPlayers(self.players)
    }
    
    private func setUpPlayer(name: String) throws -> Player {
        var hand: [Card] = []
        var foot: [Card] = []
        
        for _ in 0 ..< 13 {
            hand.append(self.deck.draw()!)
        }
        
        for _ in 0 ..< 13 {
            foot.append(self.deck.draw()!)
        }
        
        return try Player(name: name, hand: hand, foot: foot)
    }
    
    // MARK: Applying actions
    
    func apply(action: Action) throws {
        guard let round = self.round else {
            throw IllegalActionError.gameIsOver
        }
        
        guard let player = self.getPlayer(named: action.playerName) else {
            throw IllegalActionError.unknownPlayer
        }
        
        guard self.playerIterator.isCurrentPlayer(player) else {
            throw IllegalActionError.notYourTurn
        }
        
        switch (action) {
            case .drawFromDeck:
                try self.applyDrawFromDeckAction(player: player)
            case .drawFromDiscardAndAddToBook:
                try self.applyDrawFromDiscardAndAddToBookAction(player: player)
            case let .drawFromDiscardAndCreateBook(_, cards):
                try self.applyDrawFromDiscardAndCreateBookAction(player: player, cards: cards)
            case let .discardCard(_, card):
                try self.applyDiscardCardAction(player: player, card: card)
            case let .layDownInitialBooks(_, cards):
                try self.applyLayDownInitialBooksAction(player: player, cards: cards)
            case let .drawFromDiscardAndLayDownInitialBooks(_, partialBookCards, cards):
                try self.applyDrawFromDiscardAndLayDownInitialBooksAction(player: player, partialBookCards: partialBookCards, cards: cards)
            case let .startBook(_, cards):
                try self.applyStartBookAction(player: player, cards: cards)
            case let .addCardFromHandToBook(_, card):
                try self.applyAddCardFromHandToBookAction(player: player, card: card)
        }
        
        player.calculatePoints(in: round)
    }
    
    func getPlayer(named playerName: String) -> Player? {
        for player in self.players {
            if player.name == playerName {
                return player
            }
        }
        
        return nil
    }
    
    // Drawing from the deck
    
    func applyDrawFromDeckAction(player: Player) throws {
        guard player.canDrawFromDeck else {
            throw IllegalActionError.cannotDrawFromTheDeck
        }
        
        player.addCardToHandFromDeck(self.deck.draw()!)

        if self.deck.isEmpty {
            self.deck.replenishCardsAndShuffle(cards: self.discardPile)
            self.discardPile = []
            
            if self.deck.isEmpty {
                self.endRound(withPlayerGoingOut: nil)
            }
        }
    }
    
    // Drawing from the discard pile to add to an existing book
    
    func applyDrawFromDiscardAndAddToBookAction(player: Player) throws {
        guard player.canDrawFromDiscardPile && player.hasLaidDownThisRound else {
            throw IllegalActionError.cannotDrawFromTheDiscardPile
        }
        
        guard self.discardPile.count > 0 else {
            throw IllegalActionError.discardPileIsEmpty
        }

        let card = self.discardPile.popLast()!
        try player.addCardToBookFromDiscardPile(card)
    }
    
    // Drawing from the discard pile to create a new book
    
    func applyDrawFromDiscardAndCreateBookAction(player: Player, cards: [Card]) throws {
        guard player.canDrawFromDiscardPile else {
            throw IllegalActionError.cannotDrawFromTheDiscardPile
        }

        guard self.discardPile.count > 0 else {
            throw IllegalActionError.discardPileIsEmpty
        }
        
        let card = self.discardPile.popLast()!
        let cardsInBook = cards + [card]

        player.addCardToHandFromDiscardPile(card)
        try player.startBook(with: cardsInBook)
        
        if player.isHandEmpty && !player.isInFoot {
            player.pickUpFoot()
        }
    }
    
    // Discarding (and ending turn, possibly ending round)
    
    func applyDiscardCardAction(player: Player, card: Card) throws {
        guard player.canEndTurn else {
            throw IllegalActionError.cannotEndTurnYet
        }
        
        try player.removeCardFromHand(card)
        self.discardPile.append(card)
        
        if player.isHandEmpty && player.isInFoot {
            guard player.canGoOut else {
                throw IllegalActionError.cannotGoOut
            }
            
            self.endRound(withPlayerGoingOut: player)
        } else {
            if player.isHandEmpty {
                player.pickUpFoot()
            }
            
            player.turnEnded()
            self.playerIterator.goToNextPlayer()
        }
    }
    
    // Laying down an initial set of books
    
    func applyLayDownInitialBooksAction(player: Player, cards: [[Card]]) throws {
        guard !player.hasLaidDownThisRound else {
            throw IllegalActionError.alreadyLaidDownThisRound
        }
        
        let books = try cards.map({ try Book(initialCards: $0) })
        let pointsInBooks = books.reduce(0, { $0 + $1.cardsValue })
        
        guard pointsInBooks >= self.round!.pointsNeeded else {
            throw IllegalActionError.notEnoughPointsToLayDown
        }
        
        for cardsInBook in cards {
            try player.startBook(with: cardsInBook)
        }
        
        player.laidDown()
        
        if player.isHandEmpty && !player.isInFoot {
            player.pickUpFoot()
        }
    }
    
    // Laying down an initial set of books, with a card from the discard pile
    
    func applyDrawFromDiscardAndLayDownInitialBooksAction(player: Player, partialBookCards: [Card], cards: [[Card]]) throws {
        guard !player.hasLaidDownThisRound else {
            throw IllegalActionError.alreadyLaidDownThisRound
        }
        
        guard player.canDrawFromDiscardPile else {
            throw IllegalActionError.cannotDrawFromTheDiscardPile
        }

        guard self.discardPile.count > 0 else {
            throw IllegalActionError.discardPileIsEmpty
        }
        
        let card = self.discardPile.popLast()!
        let completedPartialBook = partialBookCards + [card]
        let initialBooksCards = cards + [completedPartialBook]
        
        let books = try initialBooksCards.map({ try Book(initialCards: $0) })
        let pointsInBooks = books.reduce(0, { $0 + $1.cardsValue })
        
        guard pointsInBooks >= self.round!.pointsNeeded else {
            throw IllegalActionError.notEnoughPointsToLayDown
        }
        
        for cardsInBook in cards {
            try player.startBook(with: cardsInBook)
        }
        
        player.laidDown()
        
        if player.isHandEmpty && !player.isInFoot {
            player.pickUpFoot()
        }
    }
    
    // Starting a new book
    
    func applyStartBookAction(player: Player, cards: [Card]) throws {
        try player.startBook(with: cards)
        
        if player.isHandEmpty && !player.isInFoot {
            player.pickUpFoot()
        }
    }
    
    // Adding to an existing book
    
    func applyAddCardFromHandToBookAction(player: Player, card: Card) throws {
        try player.addCardToBookFromHand(card)
        
        if player.isHandEmpty && !player.isInFoot {
            player.pickUpFoot()
        }
    }
    
    // Ending the round (and game)
    
    func endRound(withPlayerGoingOut player: Player?) {
        for player in self.players {
            player.roundEnded()
        }
        
        if let player = player {
            player.addBonusForGoingOut(in: self.round!)
        }
        
        
        self.round = self.round?.nextRound
    }
    
    // MARK: JSONEncodable
    
    enum Keys: String {
        case discardPile
        case players
    }
    
    func toJSON() -> JSONDictionary {
        return [
            Keys.discardPile.rawValue : self.discardPile.map({ $0.toJSON() }),
            Keys.players.rawValue : self.players.map({ $0.toJSON() })
        ]
    }
}
