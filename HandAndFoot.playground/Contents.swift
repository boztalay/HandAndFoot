enum IllegalMoveError: Error {
    case cardDoesntMatchBookRank
    case notEnoughCardsToStartBook
    case cannotStartBookWithGivenCards
    case tooManyWildsInBookToAddAnother
    case initialHandOrFootNotSizedCorrectly
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

struct Card {
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
    
    func shuffle() {
        self.cards.shuffle()
    }
    
    func draw() -> Card? {
        return self.cards.popLast()
    }
}

class Book {
    private var rank: CardRank
    private var cards: [Card]
    
    init(initialCards: [Card]) throws {
        if initialCards.count < 3 {
            throw IllegalMoveError.notEnoughCardsToStartBook
        }
        
        if initialCards.filter({ $0.canStartBook }).count == 0 {
            throw IllegalMoveError.cannotStartBookWithGivenCards
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
            try self.addCard(card: card)
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
    
    func addCard(card: Card) throws {
        if card.isWild {
            try self.addWildCard(card: card)
        } else {
            try self.addNaturalCard(card: card)
        }
    }
    
    private func addWildCard(card: Card) throws {
        guard self.wildCount < (self.naturalCount - 1) else {
            throw IllegalMoveError.tooManyWildsInBookToAddAnother
        }
        
        self.cards.append(card)
    }
    
    private func addNaturalCard(card: Card) throws {
        guard card.rank == self.rank else {
            throw IllegalMoveError.cardDoesntMatchBookRank
        }
        
        self.cards.append(card)
    }
}

class Player {
    let name: String

    private var hand: [Card]
    private var foot: [Card]
    private var books: [Book]
    
    init(name: String, hand: [Card], foot: [Card]) throws {
        guard hand.count == 13 && foot.count == 13 else {
            throw IllegalMoveError.initialHandOrFootNotSizedCorrectly
        }
        
        self.name = name
        self.hand = hand
        self.foot = foot
        self.books = []
    }
}

class Game {
    private var deck: Deck
    private var players: [Player]
    
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
        
        self.players = []
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
}
