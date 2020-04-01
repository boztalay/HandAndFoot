//
//  Card.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

enum CardSuit: String, CaseIterable {
    case hearts
    case diamonds
    case clubs
    case spades
    
    var isRed: Bool {
        return ((self == .hearts) || (self == .diamonds))
    }
}

enum CardRank: String, CaseIterable {
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

struct Card: Equatable, JSONCodable {
    
    let suit: CardSuit
    let rank: CardRank
    
    // MARK: Initialization
    
    init(suit: CardSuit, rank: CardRank) {
        self.suit = suit
        self.rank = rank
    }
    
    // MARK: Computed properties
    
    var isWild: Bool {
        return (self.rank == .two) || (self.rank == .joker)
    }
    
    var canStartBook: Bool {
        return (!self.isWild) && (self.rank != .three)
    }
    
    var pointValue: Int {
        switch (self.rank) {
            case .two:
                return 20
            case .three:
                if self.suit.isRed {
                    return -100
                } else {
                    return 0
                }
            case .four, .five, .six, .seven, .eight:
                    return 5
            case .nine, .ten, .jack, .queen, .king:
                    return 10
            case .ace:
                return 20
            case .joker:
                return 50
        }
    }
    
    // MARK: - JSONCodable
    
    enum Keys: String {
        case suit
        case rank
    }
    
    init?(with json: JSONDictionary) {
        guard let suitJson = json[Keys.suit.rawValue] as? String,
            let rankJson = json[Keys.rank.rawValue] as? String
        else {
                return nil
        }
        
        guard let suit = CardSuit.init(rawValue: suitJson),
            let rank = CardRank.init(rawValue: rankJson)
        else {
            return nil
        }

        self.suit = suit
        self.rank = rank
    }
    
    func toJSON() -> JSONDictionary {
        return [
            Keys.suit.rawValue : self.suit.rawValue,
            Keys.rank.rawValue : self.rank.rawValue
        ]
    }
}
