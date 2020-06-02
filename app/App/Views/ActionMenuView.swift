//
//  ActionMenuView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 6/1/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

protocol ActionMenuViewDelegate: AnyObject {
    func actionSelected(_ action: Action)
    func layDownRequested()
}

class ActionMenuView: UIView, UITableViewDataSource, UITableViewDelegate {
    
    private static let reuseIdentifier = "ActionMenuViewTableViewCell"
    
    private var titleLabel: UILabel!
    private var tableView: UITableView!
    private var layDownButton: UIButton!
    
    weak var delegate: ActionMenuViewDelegate?
    
    private var possibleActions: [Action]!

    init() {
        super.init(frame: .zero)
        self.backgroundColor = .white
        
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.black.cgColor
        
        self.titleLabel = UILabel()
        self.addSubview(self.titleLabel)
        self.titleLabel.pin(edge: .top, to: .top, of: self)
        self.titleLabel.pinX(to: self)
        self.titleLabel.pinHeight(toHeightOf: self, multiplier: 0.15, constant: 0.0)
        self.titleLabel.font = UIFont.systemFont(ofSize: 20.0, weight: .medium)
        self.titleLabel.textAlignment = .center
        self.titleLabel.text = "Actions"
        
        self.tableView = UITableView()
        self.addSubview(self.tableView)
        self.tableView.pin(edge: .top, to: .bottom, of: self.titleLabel)
        self.tableView.pinX(to: self)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.layDownButton = UIButton(type: .system)
        self.addSubview(self.layDownButton)
        self.layDownButton.pin(edge: .top, to: .bottom, of: self.tableView)
        self.layDownButton.pinX(to: self)
        self.layDownButton.pin(edge: .bottom, to: .bottom, of: self)
        self.layDownButton.pinHeight(toHeightOf: self, multiplier: 0.15, constant: 0.0)
        self.layDownButton.setTitle("Lay Down...", for: .normal)
        self.layDownButton.addTarget(self, action: #selector(ActionMenuView.layDownButtonTapped), for: .touchUpInside)

        self.possibleActions = []
    }
    
    func update(player: Player, deckSelected: Bool, discardPileSelected: Bool, handSelection: [Card], bookSelection: CardRank?) {
        self.possibleActions = []
        
        if deckSelected {
            self.possibleActions.append(.drawFromDeck(player.name))
        }
        
        if discardPileSelected {
            if let bookRank = bookSelection {
                self.possibleActions.append(.drawFromDiscardPileAndAddToBook(player.name, bookRank))
            }
            
            if handSelection.count >= 2 {
                self.possibleActions.append(.drawFromDiscardPileAndCreateBook(player.name, handSelection))
            }
        }
        
        // TODO: Laying down initial books (need a way to figure out (or be told) which books are being started)
        // TODO: Also includes drawing from the discard pile to lay down initial books
        
        if handSelection.count >= 3 {
            self.possibleActions.append(.startBook(player.name, handSelection))
        }
        
        if handSelection.count == 1 {
            self.possibleActions.append(.discardCard(player.name, handSelection.first!))
            
            if let bookRank = bookSelection {
                self.possibleActions.append(.addCardFromHandToBook(player.name, handSelection.first!, bookRank))
            }
        }

        self.tableView.reloadData()
        self.layDownButton.isEnabled = !player.hasLaidDownThisRound
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.possibleActions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let reusedCell = self.tableView.dequeueReusableCell(withIdentifier: ActionMenuView.reuseIdentifier) {
            cell = reusedCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: ActionMenuView.reuseIdentifier)
        }
        
        let action = self.possibleActions[indexPath.row]
        cell.textLabel!.text = action.friendlyDescription
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.deselectRow(at: indexPath, animated: true)

        let action = self.possibleActions[indexPath.row]
        self.delegate?.actionSelected(action)
    }
    
    @objc func layDownButtonTapped(_ sender: Any) {
        self.delegate?.layDownRequested()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
