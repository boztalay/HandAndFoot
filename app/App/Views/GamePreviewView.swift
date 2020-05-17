//
//  GamePreviewView.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/28/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GamePreviewView: UIView {

    var titleLabel: UILabel!
    var turnLabel: UILabel!
    var playButton: UIButton!
    var scoreBoardStackView: UIStackView!

    init() {
        super.init(frame: CGRect.zero)
        
        self.titleLabel = UILabel()
        self.turnLabel = UILabel()
        self.scoreBoardStackView = UIStackView()
        self.playButton = UIButton(type: .system)
    }
    
    func setGameModel(_ gameModel: GameModel) {
        if gameModel.game == nil {
            gameModel.loadGame()
        }
        
        self.titleLabel.removeFromSuperview()
        self.addSubview(self.titleLabel)
        self.titleLabel.centerHorizontally(in: self)
        self.titleLabel.pin(edge: .top, to: .top, of: self, with: 10)
        self.titleLabel.text = gameModel.title
        
        self.turnLabel.removeFromSuperview()
        self.addSubview(self.turnLabel)
        self.turnLabel.centerHorizontally(in: self)
        self.turnLabel.pin(edge: .top, to: .bottom, of: self.titleLabel, with: 10)
        self.turnLabel.text = "\(gameModel.currentUser!.firstName!)'s turn"
        
        self.scoreBoardStackView.removeFromSuperview()
        self.scoreBoardStackView = self.setUpScoreBoard(with: gameModel)
        self.addSubview(self.scoreBoardStackView)
        self.scoreBoardStackView.pinX(to: self, leading: 10, trailing: 10)
        self.scoreBoardStackView.pin(edge: .top, to: .bottom, of: self.turnLabel, with: 10)
        
        self.playButton.removeFromSuperview()
        self.addSubview(self.playButton)
        self.playButton.centerHorizontally(in: self)
        self.playButton.pin(edge: .top, to: .bottom, of: self.scoreBoardStackView, with: 10)
        self.playButton.pin(edge: .bottom, to: .bottom, of: self, with: -10)
        self.playButton.setTitle("Play!", for: .normal)
    }
    
    func setUpScoreBoard(with gameModel: GameModel) -> UIStackView {
        let scoreBoardStackView = UIStackView()
        scoreBoardStackView.axis = .horizontal
        scoreBoardStackView.distribution = .fillEqually
        
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
        
        scoreBoardStackView.addArrangedSubview(headerColumnStackView)
        
        for player in gameModel.game!.players {
            let playerColumnStackView = UIStackView()
            playerColumnStackView.axis = .vertical
            playerColumnStackView.distribution = .fillEqually
            
            let nameLabel = UILabel()
            nameLabel.text = gameModel.user(with: player.name)!.firstName!
            nameLabel.font = UIFont.boldSystemFont(ofSize: nameLabel.font.pointSize)
            playerColumnStackView.addArrangedSubview(nameLabel)
            
            for round in Round.allCases {
                let points = player.points[round]!
                
                let booksLabel = UILabel()
                booksLabel.text = "\(points.inBooks)"
                
                let nonBooksPoints = points.inHand + points.inFoot + points.laidDown + points.forGoingOut
                let pointsLabel = UILabel()
                pointsLabel.text = "\(nonBooksPoints)"

                playerColumnStackView.addArrangedSubview(UIView())
                playerColumnStackView.addArrangedSubview(UIView())
                playerColumnStackView.addArrangedSubview(booksLabel)
                playerColumnStackView.addArrangedSubview(pointsLabel)
            }
            
            scoreBoardStackView.addArrangedSubview(playerColumnStackView)
        }
        
        return scoreBoardStackView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
