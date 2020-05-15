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

    var titleLabel: UILabel!
    var turnLabel: UILabel!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.titleLabel = UILabel()
        self.addSubview(self.titleLabel)
        self.titleLabel.pin(edge: .top, to: .top, of: self, with: 3.0)
        self.titleLabel.pinX(to: self, leading: self.separatorInset.left)

        self.turnLabel = UILabel()
        self.addSubview(self.turnLabel)
        self.turnLabel.pin(edge: .top, to: .bottom, of: self.titleLabel)
        self.turnLabel.pin(edge: .bottom, to: .bottom, of: self, with: -3.0)
        self.turnLabel.pinX(to: self, leading: self.separatorInset.left)
        self.turnLabel.font = UIFont.systemFont(ofSize: 16.0)
        self.turnLabel.textColor = .lightGray
    }

    func setGame(_ game: GameModel) {
        self.titleLabel.text = "\(game.title!)"
        self.turnLabel.text = "\(game.currentUser!.firstName!)'s turn"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
