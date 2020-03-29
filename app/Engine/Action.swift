//
//  Action.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 3/28/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import Foundation

enum Action: JSONDecodable {
    case drawFromDeck(String)
    case drawFromDiscardAndAddToBook(String)
    case drawFromDiscardAndCreateBook(String, [Card])
    case discardCard(String, Card)
    case layDownInitialBooks(String, [[Card]])
    case drawFromDiscardAndLayDownInitialBooks(String, [Card], [[Card]])
    case startBook(String, [Card])
    case addCardFromHandToBook(String, Card)
    
    var playerName: String {
        switch (self) {
            case let .drawFromDeck(playerName):
                return playerName
            case let .drawFromDiscardAndAddToBook(playerName):
                return playerName
            case let .drawFromDiscardAndCreateBook(playerName, _):
                return playerName
            case let .discardCard(playerName, _):
                return playerName
            case let .layDownInitialBooks(playerName, _):
                return playerName
            case let .drawFromDiscardAndLayDownInitialBooks(playerName, _, _):
                return playerName
            case let .startBook(playerName, _):
                return playerName
            case let .addCardFromHandToBook(playerName, _):
                return playerName
        }
    }
    
    // MARK: - JSONDecodable
    
    enum Keys: String {
        case type
        case player
        case card
        case cards
        case books
        case partialBook
    }
    
    enum ActionType: String {
        case drawFromDeck
        case drawFromDiscardAndAddToBook
        case drawFromDiscardAndCreateBook
        case discardCard
        case layDownInitialBooks
        case drawFromDiscardAndLayDownInitialBooks
        case startBook
        case addCardFromHandToBook
    }
    
    init?(with json: JSONDictionary) {
        guard let type = json[Keys.type.rawValue] as? String else {
            return nil
        }
        
        guard let playerName = json[Keys.player.rawValue] as? String else {
            return nil
        }
        
        let card = Action.getCardFromJsonIfPresent(json: json)
        let cards = Action.getCardsFromJsonIfPresent(json: json)
        let books = Action.getBooksFromJsonIfPresent(json: json)
        let partialBook = Action.getPartialBookFromJsonIfPresent(json: json)
        
        switch (type) {
            case ActionType.drawFromDeck.rawValue:
                self = .drawFromDeck(playerName)

            case ActionType.drawFromDiscardAndAddToBook.rawValue:
                self = .drawFromDiscardAndAddToBook(playerName)

            case ActionType.drawFromDiscardAndCreateBook.rawValue:
                guard let cards = cards else {
                    return nil
                }
                self = .drawFromDiscardAndCreateBook(playerName, cards)

            case ActionType.discardCard.rawValue:
                guard let card = card else {
                    return nil
                }
                self = .discardCard(playerName, card)

            case ActionType.layDownInitialBooks.rawValue:
                guard let books = books else {
                    return nil
                }
                self = .layDownInitialBooks(playerName, books)
            
            case ActionType.drawFromDiscardAndLayDownInitialBooks.rawValue:
                guard let partialBook = partialBook, let books = books else {
                    return nil
                }
                self = .drawFromDiscardAndLayDownInitialBooks(playerName, partialBook, books)

            case ActionType.startBook.rawValue:
                guard let cards = cards else {
                    return nil
                }
                self = .startBook(playerName, cards)
            
            case ActionType.addCardFromHandToBook.rawValue:
                guard let card = card else {
                    return nil
                }
                self = .addCardFromHandToBook(playerName, card)
            
            default:
                return nil
        }
    }
    
    static func getCardFromJsonIfPresent(json: JSONDictionary) -> Card? {
        guard let cardJson = json[Keys.card.rawValue] as? JSONDictionary else {
            return nil
        }
        
        return Card(with: cardJson)
    }
    
    static func getCardsFromJsonIfPresent(json: JSONDictionary) -> [Card]? {
        guard let cardsJson = json[Keys.cards.rawValue] as? [JSONDictionary] else {
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
        guard let booksJson = json[Keys.books.rawValue] as? [[JSONDictionary]] else {
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
        guard let partialBookJson = json[Keys.partialBook.rawValue] as? [JSONDictionary] else {
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
}
