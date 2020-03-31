//
//  Book.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/26/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

class Book: JSONEncodable {
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
                break
            }
        }
        
        self.rank = bookRank!
        self.cards = []

        for card in initialCards.filter({ !$0.isWild }) {
            try self.addCard(card)
        }

        for card in initialCards.filter({ $0.isWild }) {
            try self.addCard(card)
        }
    }
    
    var cardCount: Int {
        return self.cards.count
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
    
    // MARK: - JSONEncodable
    
    enum Keys: String {
        case rank
        case cards
    }
    
    func toJSON() -> JSONDictionary {
        return [
            Keys.rank.rawValue : self.rank.rawValue,
            Keys.cards.rawValue : self.cards.map({ $0.toJSON() })
        ]
    }
}
