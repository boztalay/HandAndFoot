// TODO
//  - Make sure all state-manipulating functions are reentrant if the action is illegal

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
}

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

class Player {
    let name: String

    private var hand: [Card]
    private var foot: [Card]
    private var books: [CardRank : Book]
    
    init(name: String, hand: [Card], foot: [Card]) throws {
        guard hand.count == 13 && foot.count == 13 else {
            throw IllegalActionError.initialHandOrFootNotSizedCorrectly
        }
        
        self.name = name
        self.hand = hand
        self.foot = foot
        self.books = [:]
    }
    
    func addCardToHand(_ card: Card) {
        self.hand.append(card)
    }
    
    func removeCardFromHand(_ card: Card) throws {
        guard let cardIndex = self.hand.firstIndex(where: { $0 == card }) else {
            throw IllegalActionError.cardNotInHand
        }
        
        self.hand.remove(at: cardIndex)
    }
    
    func addCardToBook(_ card: Card) throws {
        guard let book = self.books[card.rank] else {
            throw IllegalActionError.playerDoesntHaveBook
        }
        
        try self.removeCardFromHand(card)
        try book.addCard(card)
    }
    
    func createBook(with cards: [Card]) throws {
        let book = try Book(initialCards: cards)
        
        guard !self.books.contains(where: { $0.key == book.rank }) else {
            throw IllegalActionError.bookAlreadyExists
        }
        
        for card in cards {
            try self.removeCardFromHand(card)
        }
        
        self.books[book.rank] = book
    }
}

class Game {
    private var deck: Deck
    private var discards: [Card]
    private var players: [Player]
    private var round: Round
    private var actions: [Action]
    
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
    
    func apply(action: Action) throws {
        switch (action) {
            case let .drawFromDeck(player):
                self.applyDrawFromDeckAction(player: player)
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
    
    func applyDrawFromDeckAction(player: Player) {
        player.addCardToHand(self.deck.draw()!)

        if self.deck.isEmpty {
            self.deck.replenishCardsAndShuffle(cards: self.discards)
            self.discards = []
        }
    }
    
    func applyDrawFromDiscardAndAddToBookAction(player: Player) throws {
        guard self.discards.count > 0 else {
            throw IllegalActionError.discardPileIsEmpty
        }

        let card = self.discards.popLast()!
        try player.addCardToBook(card)
    }
    
    func applyDrawFromDiscardAndCreateBookAction(player: Player, cards: [Card]) throws {
        guard self.discards.count > 0 else {
            throw IllegalActionError.discardPileIsEmpty
        }
        
        let card = self.discards.popLast()!
        let cardsInBook = cards + [card]

        player.addCardToHand(card)
        try player.createBook(with: cardsInBook)
    }
    
    func applyDiscardCardAction(player: Player, card: Card) throws {
        try player.removeCardFromHand(card)
        self.discards.append(card)
    }
    
    func applyLayDownInitialBooksAction(player: Player, cards: [[Card]]) throws {
        let books = try cards.map({ try Book(initialCards: $0) })
        let pointsInBooks = books.reduce(0, { $0 + $1.pointValue })
        
        guard pointsInBooks >= self.round.rawValue else {
            throw IllegalActionError.notEnoughPointsToLayDown
        }
        
        for cardsInBook in cards {
            try player.createBook(with: cardsInBook)
        }
    }
    
    func applyStartBookAction(player: Player, cards: [Card]) throws {
        try player.createBook(with: cards)
    }
    
    func applyAddCardFromHandToBookAction(player: Player, card: Card) throws {
        try player.addCardToBook(card)
    }
}
