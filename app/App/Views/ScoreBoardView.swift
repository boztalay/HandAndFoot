//
//  ScoreBoardView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/18/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class ScoreBoardView: UIView {
    
    var stackView: UIStackView!

    func update(with gameModel: GameModel) {
        if let stackView = self.stackView {
            stackView.removeFromSuperview()
        }
        
        self.stackView = UIStackView()
        self.addSubview(self.stackView)
        self.stackView.pin(to: self)
        self.stackView.axis = .horizontal
        self.stackView.distribution = .fillEqually
        
        let headerColumnStackView = UIStackView()
        headerColumnStackView.axis = .vertical
        headerColumnStackView.distribution = .fillEqually
        headerColumnStackView.addArrangedSubview(UIView())
        
        for round in Round.allCases {
            let roundLabel = UILabel()
            roundLabel.text = round.niceName
            roundLabel.font = UIFont.boldSystemFont(ofSize: roundLabel.font.pointSize)
            
            let booksLabel = UILabel()
            booksLabel.text = "    Books"
            
            let pointsLabel = UILabel()
            pointsLabel.text = "    Points"

            headerColumnStackView.addArrangedSubview(UIView())
            headerColumnStackView.addArrangedSubview(roundLabel)
            headerColumnStackView.addArrangedSubview(booksLabel)
            headerColumnStackView.addArrangedSubview(pointsLabel)
        }
        
        self.stackView.addArrangedSubview(headerColumnStackView)
        
        for player in gameModel.game!.players {
            let playerColumnStackView = UIStackView()
            playerColumnStackView.axis = .vertical
            playerColumnStackView.distribution = .fillEqually
            
            let nameLabel = UILabel()
            nameLabel.text = gameModel.user(with: player.name)!.firstName!
            nameLabel.font = UIFont.boldSystemFont(ofSize: nameLabel.font.pointSize)
            nameLabel.textAlignment = .center
            playerColumnStackView.addArrangedSubview(nameLabel)
            
            for round in Round.allCases {
                let points = player.points[round]!
                
                let booksLabel = UILabel()
                booksLabel.text = "\(points.inBooks)"
                booksLabel.textAlignment = .right
                
                let nonBooksPoints = points.inHand + points.inFoot + points.laidDown + points.forGoingOut
                let pointsLabel = UILabel()
                pointsLabel.text = "\(nonBooksPoints)"
                pointsLabel.textAlignment = .right

                playerColumnStackView.addArrangedSubview(UIView())
                playerColumnStackView.addArrangedSubview(UIView())
                playerColumnStackView.addArrangedSubview(booksLabel)
                playerColumnStackView.addArrangedSubview(pointsLabel)
            }
            
            self.stackView.addArrangedSubview(playerColumnStackView)
        }
    }
}
