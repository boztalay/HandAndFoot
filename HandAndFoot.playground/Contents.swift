// TODO
//  - Make sure all state-manipulating functions are reentrant if the action
//    is illegal
//    - Do they need to be reentrant if the system design is such that this
//      state management engine reads the ledger from scratch for every action?
//  - Lots of the edge cases, like restrictions on discarding, going into your
//    foot, going out, etc

enum IllegalActionError: Error {
    case cardDoesntMatchBookRank
    case notEnoughCardsToStartBook
    case cannotStartBookWithGivenCards
    case tooManyWildsInBookToAddAnother
    case initialHandOrFootNotSizedCorrectly
    case deckIsEmpty
    case discardPileIsEmpty
    case notEnoughPointsToLayDown
    case playerDoesntHaveBook
    case cardNotInHand
    case bookAlreadyExists
    case cannotDrawFromTheDeck
    case cannotDrawFromTheDiscardPile
    case notYourTurn
    case alreadyLaidDownThisRound
    case cannotGoOut
}

enum IllegalSetupError: Error {
    case tooFewPlayers
    case tooManyPlayers
}

enum CardSuit: CaseIterable {
    case hearts
    case diamonds
    case clubs
    case spades
}

enum CardRank: CaseIterable {
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case jack
    case queen
    case king
    case ace
    case joker
}

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
            case let .startBook(player, _):
                return player
            case let .addCardFromHandToBook(player, _):
                return player
        }
    }
}

struct PlayerIterator {
    private var players: [Player]
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

//
// Card
//

struct Card: Equatable {
    let suit: CardSuit
    let rank: CardRank
    
    var isWild: Bool {
        return (self.rank == .two) || (self.rank == .joker)
    }
    
    var canStartBook: Bool {
        return (!self.isWild) && (self.rank != .three)
    }
}

//
// Deck
//

class Deck {
    private var cards: [Card]
    
    init(standardDeckCount: Int) {
        self.cards = []
        
        for _ in 0 ..< standardDeckCount {
            for suit in CardSuit.allCases {
                for rank in CardRank.allCases {
                    self.cards.append(Card(suit: suit, rank: rank))
                }
            }
        }
        
        self.cards.append(Card(suit: .spades, rank: .joker))
        self.cards.append(Card(suit: .spades, rank: .joker))
    }
    
    var isEmpty: Bool {
        return (self.cards.count == 0)
    }
    
    func shuffle() {
        self.cards.shuffle()
    }
    
    func draw() -> Card? {
        return self.cards.popLast()
    }
    
    func replenishCardsAndShuffle(cards: [Card]) {
        self.cards = cards
        self.shuffle()
    }
}

//
// Book
//

class Book {
    let rank: CardRank

    private var cards: [Card]
    
    init(initialCards: [Card]) throws {
        if initialCards.count < 3 {
            throw IllegalActionError.notEnoughCardsToStartBook
        }
        
        if initialCards.filter({ $0.canStartBook }).count == 0 {
            throw IllegalActionError.cannotStartBookWithGivenCards
        }
        
        var bookRank: CardRank? = nil
        for card in initialCards {
            if card.canStartBook {
                bookRank = card.rank
            }
        }
        
        self.rank = bookRank!
        
        self.cards = []
        for card in initialCards {
            try self.addCard(card)
        }
    }
    
    var wildCount: Int {
        return self.cards.filter({ $0.isWild }).count
    }

    var naturalCount: Int {
        return self.cards.filter({ !$0.isWild }).count
    }
    
    var isNatural: Bool {
        return (self.wildCount == 0)
    }
    
    var isComplete: Bool {
        return (self.cards.count == 7)
    }
    
    var pointValue: Int {
        // TODO
        fatalError("not implemented")
    }
    
    func addCard(_ card: Card) throws {
        if card.isWild {
            try self.addWildCard(card)
        } else {
            try self.addNaturalCard(card)
        }
    }
    
    private func addWildCard(_ card: Card) throws {
        guard self.wildCount < (self.naturalCount - 1) else {
            throw IllegalActionError.tooManyWildsInBookToAddAnother
        }
        
        self.cards.append(card)
    }
    
    private func addNaturalCard(_ card: Card) throws {
        guard card.rank == self.rank else {
            throw IllegalActionError.cardDoesntMatchBookRank
        }
        
        self.cards.append(card)
    }
}

//
// Player
//

class Player {
    let name: String

    private var hand: [Card]
    private var foot: [Card]
    private var books: [CardRank : Book]
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
}

//
// Game
//

class Game {
    private var deck: Deck
    private var discards: [Card]
    private var players: [Player]
    private var round: Round
    private var actions: [Action]
    private var playerIterator: PlayerIterator

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
        
        self.playerIterator = PlayerIterator(players: self.players)
        
        for playerName in playerNames {
            let player = try self.setUpPlayer(name: playerName)
            self.players.append(player)
        }
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
        guard player.canDrawFromDiscardPile else {
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
    }
    
    // Discarding (and ending turn, possibly ending round)
    
    func applyDiscardCardAction(player: Player, card: Card) throws {
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
        
        if player.isHandEmpty {
            player.pickUpFoot()
        }
    }
    
    // Starting a new book
    
    func applyStartBookAction(player: Player, cards: [Card]) throws {
        try player.startBook(with: cards)
    }
    
    // Adding to an existing book
    
    func applyAddCardFromHandToBookAction(player: Player, card: Card) throws {
        try player.addCardToBookFromHand(card)
    }
    
    // Ending the round (and game)
    
    func endRound(withPlayerGoingOut player: Player?) {
        
        // Notify players
    }
}
