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
    
    // MARK: Computed properties
    
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
    
    // MARK: JSONDecodable
    
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
        
        switch (type) {
            case "draw_from_deck":
                self = .drawFromDeck(playerName)

            case "draw_from_discard_and_add_to_book":
                self = .drawFromDiscardAndAddToBook(playerName)

            case "draw_from_discard_and_create_book":
                guard let cards = cards else {
                    return nil
                }
                self = .drawFromDiscardAndCreateBook(playerName, cards)

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
            
            case "draw_from_discard_and_lay_down_initial_books":
                guard let partialBook = partialBook, let books = books else {
                    return nil
                }
                self = .drawFromDiscardAndLayDownInitialBooks(playerName, partialBook, books)

            case "start_book":
                guard let cards = cards else {
                    return nil
                }
                self = .startBook(playerName, cards)
            
            case "add_card_from_hand_to_book":
                guard let card = card else {
                    return nil
                }
                self = .addCardFromHandToBook(playerName, card)
            
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
}
