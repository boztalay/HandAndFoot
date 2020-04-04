//
//  Deck.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

class Deck {

    private var cards: [Card]
    
    // MARK: Initialization
    
    init(standardDeckCount: Int) {
        self.cards = []
        
        for _ in 0 ..< standardDeckCount {
            for suit in CardSuit.allCases {
                for rank in CardRank.allCases {
                    if rank != .joker {
                        self.cards.append(Card(suit: suit, rank: rank))
                    }
                }
            }

            self.cards.append(Card(suit: .spades, rank: .joker))
            self.cards.append(Card(suit: .spades, rank: .joker))
        }
    }
    
    // MARK: Computed properties
    
    var isEmpty: Bool {
        return (self.cardCount == 0)
    }
    
    var cardCount: Int {
        return self.cards.count
    }
    
    // MARK: Modifying the deck

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
    
    // MARK: JSONCodable
    
    init?(with json: JSONDictionary) {
        guard let cardsJson = json["cards"] as? [JSONDictionary] else {
            return nil
        }
        
        self.cards = []
        
        for cardJson in cardsJson {
            guard let card = Card(with: cardJson) else {
                return nil
            }
            
            self.cards.append(card)
        }
    }
    
    func toJSON() -> JSONDictionary {
        return [
            "cards" : self.cards.map({ $0.toJSON() })
        ]
    }
}
