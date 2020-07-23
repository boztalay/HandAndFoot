//
//  Action.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/28/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

enum Action: JSONCodable {

    case drawFromDeck(String)
    case drawFromDiscardPileAndAddToBook(String, CardRank)
    case drawFromDiscardPileAndCreateBook(String, [Card])
    case discardCard(String, Card)
    case layDownInitialBooks(String, [[Card]])
    case drawFromDiscardPileAndLayDownInitialBooks(String, [Card], [[Card]])
    case startBook(String, [Card])
    case addCardsFromHandToBook(String, [Card], CardRank)
    
    // MARK: Computed properties
    
    var playerName: String {
        switch (self) {
            case let .drawFromDeck(playerName):
                return playerName
            case let .drawFromDiscardPileAndAddToBook(playerName, _):
                return playerName
            case let .drawFromDiscardPileAndCreateBook(playerName, _):
                return playerName
            case let .discardCard(playerName, _):
                return playerName
            case let .layDownInitialBooks(playerName, _):
                return playerName
            case let .drawFromDiscardPileAndLayDownInitialBooks(playerName, _, _):
                return playerName
            case let .startBook(playerName, _):
                return playerName
            case let .addCardsFromHandToBook(playerName, _, _):
                return playerName
        }
    }
    
    var friendlyDescription: String {
        switch (self) {
            case .drawFromDeck:
                return "Draw from deck"
            case .drawFromDiscardPileAndAddToBook:
                return "Add discard to book"
            case .drawFromDiscardPileAndCreateBook:
                return "Start book with discard"
            case .discardCard:
                return "Discard"
            case .layDownInitialBooks:
                return "Lay down"
            case .drawFromDiscardPileAndLayDownInitialBooks:
                return "Lay down with discard"
            case .startBook:
                return "Start book"
            case .addCardsFromHandToBook:
                return "Add cards to book"
        }
    }
    
    // MARK: JSONCodable
    
    init?(with json: JSONDictionary) {
        guard let type = json["type"] as? String else {
            return nil
        }
        
        guard let playerName = json["player"] as? String else {
            return nil
        }
        
        let card = Action.getCardFromJsonIfPresent(json: json)
        let cards = Action.getCardsFromJsonIfPresent(json: json)
        let books = Action.getBooksFromJsonIfPresent(json: json)
        let partialBook = Action.getPartialBookFromJsonIfPresent(json: json)
        let bookRank = Action.getBookRankFromJsonIfPresent(json: json)
        
        switch (type) {
            case "draw_from_deck":
                self = .drawFromDeck(playerName)

            case "draw_from_discard_pile_and_add_to_book":
                guard let bookRank = bookRank else {
                    return nil
                }
                self = .drawFromDiscardPileAndAddToBook(playerName, bookRank)

            case "draw_from_discard_pile_and_create_book":
                guard let cards = cards else {
                    return nil
                }
                self = .drawFromDiscardPileAndCreateBook(playerName, cards)

            case "discard_card":
                guard let card = card else {
                    return nil
                }
                self = .discardCard(playerName, card)

            case "lay_down_initial_books":
                guard let books = books else {
                    return nil
                }
                self = .layDownInitialBooks(playerName, books)
            
            case "draw_from_discard_pile_and_lay_down_initial_books":
                guard let partialBook = partialBook, let books = books else {
                    return nil
                }
                self = .drawFromDiscardPileAndLayDownInitialBooks(playerName, partialBook, books)

            case "start_book":
                guard let cards = cards else {
                    return nil
                }
                self = .startBook(playerName, cards)
            
            case "add_cards_from_hand_to_book":
                guard let cards = cards, let bookRank = bookRank else {
                    return nil
                }
                self = .addCardsFromHandToBook(playerName, cards, bookRank)
            
            default:
                return nil
        }
    }
    
    static func getCardFromJsonIfPresent(json: JSONDictionary) -> Card? {
        guard let cardJson = json["card"] as? JSONDictionary else {
            return nil
        }
        
        return Card(with: cardJson)
    }
    
    static func getCardsFromJsonIfPresent(json: JSONDictionary) -> [Card]? {
        guard let cardsJson = json["cards"] as? [JSONDictionary] else {
            return nil
        }
        
        var cards: [Card] = []

        for cardJson in cardsJson {
            guard let card = Card(with: cardJson) else {
                return nil
            }
            
            cards.append(card)
        }
        
        return cards
    }
    
    static func getBooksFromJsonIfPresent(json: JSONDictionary) -> [[Card]]? {
        guard let booksJson = json["books"] as? [[JSONDictionary]] else {
            return nil
        }
        
        var books: [[Card]] = []
        
        for bookJson in booksJson {
            var cards: [Card] = []
            
            for cardJson in bookJson {
                guard let card = Card(with: cardJson) else {
                    return nil
                }
                
                cards.append(card)
            }
            
            books.append(cards)
        }
        
        return books
    }
    
    static func getPartialBookFromJsonIfPresent(json: JSONDictionary) -> [Card]? {
        guard let partialBookJson = json["partial_book"] as? [JSONDictionary] else {
            return nil
        }
        
        var cards: [Card] = []

        for cardJson in partialBookJson {
            guard let card = Card(with: cardJson) else {
                return nil
            }
            
            cards.append(card)
        }
        
        return cards
    }
    
    static func getBookRankFromJsonIfPresent(json: JSONDictionary) -> CardRank? {
        guard let bookRankJson = json["book_rank"] as? String else {
            return nil
        }
        
        return CardRank.init(rawValue: bookRankJson)
    }
    
    func toJSON() -> JSONDictionary {
        switch (self) {
            case let .drawFromDeck(playerName):
                return [
                    "type": "draw_from_deck",
                    "player": playerName
                ]
            case let .drawFromDiscardPileAndAddToBook(playerName, bookRank):
                return [
                    "type": "draw_from_discard_pile_and_add_to_book",
                    "player": playerName,
                    "book_rank": bookRank.rawValue
                ]
            case let .drawFromDiscardPileAndCreateBook(playerName, cards):
                return [
                    "type": "draw_from_discard_pile_and_create_book",
                    "player": playerName,
                    "cards" : cards.map({ $0.toJSON() })
                ]
            case let .discardCard(playerName, card):
                return [
                    "type": "discard_card",
                    "player": playerName,
                    "card": card.toJSON()
                ]
            case let .layDownInitialBooks(playerName, books):
                return [
                    "type": "lay_down_initial_books",
                    "player": playerName,
                    "books": books.map({ $0.map({ $0.toJSON() }) })
                ]
            case let .drawFromDiscardPileAndLayDownInitialBooks(playerName, partialBook, books):
                return [
                    "type": "draw_from_discard_pile_and_lay_down_initial_books",
                    "player": playerName,
                    "partial_book" : partialBook.map({ $0.toJSON() }),
                    "books": books.map({ $0.map({ $0.toJSON() }) })
                ]
            case let .startBook(playerName, cards):
                return [
                    "type": "start_book",
                    "player": playerName,
                    "cards" : cards.map({ $0.toJSON() })
                ]
            case let .addCardsFromHandToBook(playerName, cards, bookRank):
                return [
                    "type": "add_card_from_hand_to_book",
                    "player": playerName,
                    "cards": cards.map({ $0.toJSON() }),
                    "book_rank": bookRank.rawValue
                ]
        }
    }
}
