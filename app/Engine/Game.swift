//
//  Game.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

enum Round: String, CaseIterable {
    case ninety = "ninety"
    case oneTwenty = "one_twenty"
    case oneFifty = "one_fifty"
    case oneEighty = "one_eighty"
    
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
    
    var niceName: String {
        switch (self) {
            case .ninety:
                return "Ninety"
            case .oneTwenty:
                return "One Twenty"
            case .oneFifty:
                return "One Fifty"
            case .oneEighty:
                return "One Eighty"
        }
    }
}

struct PlayerIterator {

    private let players: [Player]
    private var index: Int
    
    var currentPlayer: Player {
        return self.players[self.index]
    }
    
    init(players: [Player]) {
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

class Game: JSONEncodable {
    
    private var decks: [Round : Deck]
    private(set) var discardPile: [Card]
    private(set) var players: [Player]
    private(set) var round: Round?
    private var playerIterator: PlayerIterator
    
    var deck: Deck {
        return self.decks[self.round!]!
    }

    // MARK: Initialization
    
    init(playerNames: [String], decks: [Round : Deck]) throws {
        guard playerNames.count >= 2 else {
            throw IllegalSetupError.tooFewPlayers
        }
        
        guard playerNames.count <= 6 else {
            throw IllegalSetupError.tooManyPlayers
        }
        
        self.decks = decks
        self.discardPile = []
        self.round = .ninety
        
        self.players = []
        for playerName in playerNames {
            self.players.append(Player(name: playerName))
        }

        self.playerIterator = PlayerIterator(players: self.players)
        
        for player in self.players {
            try self.dealCards(to: player)
        }
        
        for player in self.players {
            player.calculatePoints(in: self.round!)
        }
    }
    
    private func dealCards(to player: Player) throws {
        var hand: [Card] = []
        var foot: [Card] = []
        
        for _ in 0 ..< 13 {
            hand.append(self.deck.draw()!)
        }
        
        for _ in 0 ..< 13 {
            foot.append(self.deck.draw()!)
        }
        
        try player.setHandAndFoot(hand: hand, foot: foot)
    }
    
    // MARK: Applying actions
    
    func apply(action: Action) throws {
        guard self.round != nil else {
            throw IllegalActionError.gameIsOver
        }
        
        guard let player = self.getPlayer(named: action.playerName) else {
            throw IllegalActionError.unknownPlayer
        }
        
        guard self.isCurrentPlayer(player) else {
            throw IllegalActionError.notYourTurn
        }
        
        switch (action) {
            case .drawFromDeck:
                try self.applyDrawFromDeckAction(player: player)
            case let .drawFromDiscardPileAndAddToBook(_, bookRank):
                try self.applyDrawFromDiscardPileAndAddToBookAction(player: player, bookRank: bookRank)
            case let .drawFromDiscardPileAndStartBook(_, cards):
                try self.applyDrawFromDiscardPileAndStartBookAction(player: player, cards: cards)
            case let .discardCard(_, card):
                try self.applyDiscardCardAction(player: player, card: card)
            case let .layDownInitialBooks(_, cards):
                try self.applyLayDownInitialBooksAction(player: player, cards: cards)
            case let .drawFromDiscardPileAndLayDownInitialBooks(_, partialBookCards, cards):
                try self.applyDrawFromDiscardPileAndLayDownInitialBooksAction(player: player, partialBookCards: partialBookCards, cards: cards)
            case let .startBook(_, cards):
                try self.applyStartBookAction(player: player, cards: cards)
            case let .addCardsFromHandToBook(_, cards, bookRank):
                try self.applyAddCardsFromHandToBookAction(player: player, cards: cards, bookRank: bookRank)
        }
        
        player.calculatePoints(in: self.round!)
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
                try self.endRound(withPlayerGoingOut: nil)
            }
        }
    }
    
    // Drawing from the discard pile to add to an existing book
    
    func applyDrawFromDiscardPileAndAddToBookAction(player: Player, bookRank: CardRank) throws {
        guard player.canDrawFromDiscardPile && player.hasLaidDownThisRound else {
            throw IllegalActionError.cannotDrawFromTheDiscardPile
        }
        
        guard self.discardPile.count > 0 else {
            throw IllegalActionError.discardPileIsEmpty
        }

        let card = self.discardPile.popLast()!
        try player.addCardFromDiscardPileToBook(card, bookRank: bookRank, in: self.round!)
    }
    
    // Drawing from the discard pile to create a new book
    
    func applyDrawFromDiscardPileAndStartBookAction(player: Player, cards: [Card]) throws {
        guard player.canDrawFromDiscardPile else {
            throw IllegalActionError.cannotDrawFromTheDiscardPile
        }

        guard self.discardPile.count > 0 else {
            throw IllegalActionError.discardPileIsEmpty
        }
        
        let card = self.discardPile.popLast()!
        let cardsInBook = cards + [card]

        player.addCardToHandFromDiscardPile(card)
        try player.startBook(with: cardsInBook, in: self.round!)
        
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
            guard player.canGoOut(in: self.round!) else {
                throw IllegalActionError.cannotGoOut
            }
            
            try self.endRound(withPlayerGoingOut: player)
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
            try player.startBook(with: cardsInBook, in: self.round!)
        }
        
        player.laidDown()
        
        if player.isHandEmpty && !player.isInFoot {
            player.pickUpFoot()
        }
    }
    
    // Laying down an initial set of books, with a card from the discard pile
    
    func applyDrawFromDiscardPileAndLayDownInitialBooksAction(player: Player, partialBookCards: [Card], cards: [[Card]]) throws {
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
        
        player.addCardToHandFromDiscardPile(card)
        for cardsInBook in initialBooksCards {
            try player.startBook(with: cardsInBook, in: self.round!)
        }
        
        player.laidDown()
        
        if player.isHandEmpty && !player.isInFoot {
            player.pickUpFoot()
        }
    }
    
    // Starting a new book
    
    func applyStartBookAction(player: Player, cards: [Card]) throws {
        try player.startBook(with: cards, in: self.round!)
        
        if player.isHandEmpty && !player.isInFoot {
            player.pickUpFoot()
        }
    }
    
    // Adding to an existing book
    
    func applyAddCardsFromHandToBookAction(player: Player, cards: [Card], bookRank: CardRank) throws {
        try player.addCardsFromHandToBook(cards, bookRank: bookRank, in: self.round!)
        
        if player.isHandEmpty && !player.isInFoot {
            player.pickUpFoot()
        }
    }
    
    // Ending the round (and game)
    
    func endRound(withPlayerGoingOut player: Player?) throws {
        if let player = player {
            player.addBonusForGoingOut(in: self.round!)
        }

        for player in self.players {
            player.calculatePoints(in: self.round!)
            player.roundEnded()
        }
        
        self.discardPile = []
        
        if let nextRound = self.round?.nextRound {
            self.round = nextRound

            for player in self.players {
                try self.dealCards(to: player)
                player.calculatePoints(in: self.round!)
            }
        }
    }
    
    // MARK: Helpers
    
    func isCurrentPlayer(_ player: Player) -> Bool {
        return self.playerIterator.isCurrentPlayer(player)
    }
    
    // MARK: JSONEncodable
    
    func toJSON() -> JSONDictionary {
        return [
            "discard_pile" : self.discardPile.map({ $0.toJSON() }),
            "players" : self.players.map({ $0.toJSON() })
        ]
    }
}
