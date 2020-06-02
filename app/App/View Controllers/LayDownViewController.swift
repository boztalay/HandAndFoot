//
//  LayDownViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/1/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

protocol LayDownViewControllerDelegate: AnyObject {
    func layDownSelectionComplete(action: Action)
}

class LayDownViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private static let reuseIdentifier = "LayDownViewControllerTableViewCell"
    
    private var tableView: UITableView!
    
    weak var delegate: LayDownViewControllerDelegate?
    
    private var cards: [Card]!
    private var selectedCards: [Int : Card]!
    private var discardPileCardIndex: Int?
    
    private var playerName: String!
    private var books: [[Card]]!
    private var partialBook: [Card]?

    init(playerName: String, cardsFromHand: [Card], cardFromDiscardPile: Card?) {
        super.init(nibName: nil, bundle: nil)
        
        self.tableView = UITableView()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.cards = cardsFromHand
        self.selectedCards = [:]

        if let cardFromDiscardPile = cardFromDiscardPile {
            self.discardPileCardIndex = 0
            self.cards.insert(cardFromDiscardPile, at: self.discardPileCardIndex!)
        }

        self.playerName = playerName
        self.books = []
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(LayDownViewController.cancelButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next Book", style: .plain, target: self, action: #selector(LayDownViewController.nextBookButtonPressed))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = "Select Books"
        
        self.tableView.pin(to: self.view.safeAreaLayoutGuide)
        
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let reusedCell = tableView.dequeueReusableCell(withIdentifier: LayDownViewController.reuseIdentifier) {
            cell = reusedCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: LayDownViewController.reuseIdentifier)
        }
        
        let card = self.cards[indexPath.row]
        cell.textLabel!.text = "\(card.rank.rawValue) of \(card.suit.rawValue)"
        
        if self.selectedCards[indexPath.row] == nil {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        let card = self.cards[indexPath.row]
        
        if self.selectedCards[indexPath.row] == nil {
            self.selectedCards[indexPath.row] = card
        } else {
            self.selectedCards.removeValue(forKey: indexPath.row)
        }

        self.tableView.reloadData()
    }
    
    @objc func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func nextBookButtonPressed(_ sender: Any) {
        guard self.selectedCards.count >= 3 else {
            UIAlertController.presentErrorAlert(on: self, title: "Not Enough Cards Selected")
            return
        }
        
        var includesDiscardPileCard = false
        var cardsInBook: [Card] = []

        for (index, card) in self.selectedCards {
            if let discardPileCardIndex = self.discardPileCardIndex, index == discardPileCardIndex {
                includesDiscardPileCard = true
            } else {
                cardsInBook.append(card)
            }
            
            self.cards.remove(at: index)
        }
        
        if includesDiscardPileCard {
            self.discardPileCardIndex = nil
            self.partialBook = cardsInBook
        } else {
            self.books.append(cardsInBook)
        }
        
        self.selectedCards = [:]
        
        guard self.cards.count == 0 else {
            self.tableView.reloadData()
            return
        }
            
        if let partialBook = self.partialBook {
            self.delegate?.layDownSelectionComplete(
                action: .drawFromDiscardPileAndLayDownInitialBooks(playerName, partialBook, self.books)
            )
        } else {
            self.delegate?.layDownSelectionComplete(
                action: .layDownInitialBooks(playerName, self.books)
            )
        }
            
        self.dismiss(animated: true, completion: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
