//
//  Game.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

enum Round: Int {
    case ninety = 90
    case oneTwenty = 120
    case oneFifty = 150
    case oneEighty = 180
}

enum Action {
    case drawFromDeck(Player)
    case drawFromDiscardAndAddToBook(Player)
    case drawFromDiscardAndCreateBook(Player, [Card])
    case discardCard(Player, Card)
    case layDownInitialBooks(Player, [[Card]])
    case drawFromDiscardAndLayDownInitialBooks(Player, [Card], [[Card]])
    case startBook(Player, [Card])
    case addCardFromHandToBook(Player, Card)
    
    var player: Player {
        switch (self) {
            case let .drawFromDeck(player):
                return player
            case let .drawFromDiscardAndAddToBook(player):
                return player
            case let .drawFromDiscardAndCreateBook(player, _):
                return player
            case let .discardCard(player, _):
                return player
            case let .layDownInitialBooks(player, _):
                return player
            case let .drawFromDiscardAndLayDownInitialBooks(player, _, _):
                return player
            case let .startBook(player, _):
                return player
            case let .addCardFromHandToBook(player, _):
                return player
        }
    }
}

class Game {
    private var deck: Deck
    private var discards: [Card]
    private var players: [Player]
    private var round: Round
    private var actions: [Action]
    private(set) var playerIterator: PlayerIterator

    // Initialization
    
    init(playerNames: [String]) throws {
        guard playerNames.count >= 2 else {
            throw IllegalSetupError.tooFewPlayers
        }
        
        guard playerNames.count <= 6 else {
            throw IllegalSetupError.tooManyPlayers
        }
        
        let deckCount = playerNames.count + 1
        self.deck = Deck(standardDeckCount: deckCount)
        self.deck.shuffle()
        
        self.discards = []
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
    
    // Applying actions
    
    func apply(action: Action) throws {
        guard self.playerIterator.isCurrentPlayer(action.player) else {
            throw IllegalActionError.notYourTurn
        }
        
        switch (action) {
            case let .drawFromDeck(player):
                try self.applyDrawFromDeckAction(player: player)
            case let .drawFromDiscardAndAddToBook(player):
                try self.applyDrawFromDiscardAndAddToBookAction(player: player)
            case let .drawFromDiscardAndCreateBook(player, cards):
                try self.applyDrawFromDiscardAndCreateBookAction(player: player, cards: cards)
            case let .discardCard(player, card):
                try self.applyDiscardCardAction(player: player, card: card)
            case let .layDownInitialBooks(player, cards):
                try self.applyLayDownInitialBooksAction(player: player, cards: cards)
            case let .drawFromDiscardAndLayDownInitialBooks(player, partialBookCards, cards):
                try self.applyDrawFromDiscardAndLayDownInitialBooksAction(player: player, partialBookCards: partialBookCards, cards: cards)
            case let .startBook(player, cards):
                try self.applyStartBookAction(player: player, cards: cards)
            case let .addCardFromHandToBook(player, card):
                try self.applyAddCardFromHandToBookAction(player: player, card: card)
        }
    }
    
    // Drawing from the deck
    
    func applyDrawFromDeckAction(player: Player) throws {
        guard player.canDrawFromDeck else {
            throw IllegalActionError.cannotDrawFromTheDeck
        }
        
        player.addCardToHandFromDeck(self.deck.draw()!)

        if self.deck.isEmpty {
            self.deck.replenishCardsAndShuffle(cards: self.discards)
            self.discards = []
            
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
        
        guard self.discards.count > 0 else {
            throw IllegalActionError.discardPileIsEmpty
        }

        let card = self.discards.popLast()!
        try player.addCardToBookFromDiscardPile(card)
    }
    
    // Drawing from the discard pile to create a new book
    
    func applyDrawFromDiscardAndCreateBookAction(player: Player, cards: [Card]) throws {
        guard player.canDrawFromDiscardPile else {
            throw IllegalActionError.cannotDrawFromTheDiscardPile
        }

        guard self.discards.count > 0 else {
            throw IllegalActionError.discardPileIsEmpty
        }
        
        let card = self.discards.popLast()!
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
        self.discards.append(card)
        
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
        let pointsInBooks = books.reduce(0, { $0 + $1.pointValue })
        
        guard pointsInBooks >= self.round.rawValue else {
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

        guard self.discards.count > 0 else {
            throw IllegalActionError.discardPileIsEmpty
        }
        
        let card = self.discards.popLast()!
        let completedPartialBook = partialBookCards + [card]
        let initialBooksCards = cards + [completedPartialBook]
        
        let books = try initialBooksCards.map({ try Book(initialCards: $0) })
        let pointsInBooks = books.reduce(0, { $0 + $1.pointValue })
        
        guard pointsInBooks >= self.round.rawValue else {
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
            player.addBonusForGoingOut()
        }
    }
    
    // Diagnostics
    
    func printReport() {
        print("Game State:")
        print("    Round: \(self.round)")
        print("    Current Player: \(self.playerIterator.currentPlayer.name)")
        print("    Cards in Deck: \(self.deck.cardCount)")
        print("    Cards Discarded: \(self.discards.count)")
        print("    Actions Taken: \(self.actions.count)")
        
        for player in self.players {
            print("Player: \(player.name)")
            print("    Cards in Hand: \(player.hand.count)")
            print("    In Foot?: \(player.isInFoot)")
            
            if player.books.count > 0 {
                print("    Books:")
                let bookRanks = player.books.keys.sorted(by: { $0.rawValue > $1.rawValue })
                for bookRank in bookRanks {
                    print("        \(bookRank): \(player.books[bookRank]!.cardCount) cards")
                }
            }
        }
    }
}
