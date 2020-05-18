//
//  GameListTableViewCell.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/5/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GameListTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "GameListTableViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    func setGameModel(_ game: GameModel) {
        self.textLabel!.text = "\(game.title!)"
        self.detailTextLabel!.text = "\(game.currentUser!.firstName!)'s turn"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
