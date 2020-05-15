//
//  GamesViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/28/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GamesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    var gameListTableView: UITableView!
    var dividerView: UIView!
    var gamePreviewView: GamePreviewView!
    
    var gameModels: [GameModel]!

    init() {
        super.init(nibName: nil, bundle: nil)

        self.gameListTableView = UITableView()
        self.dividerView = UIView()
        self.gamePreviewView = GamePreviewView()
        self.gameModels = []

        self.gameListTableView.delegate = self
        self.gameListTableView.dataSource = self
        self.gameListTableView.register(GameListTableViewCell.self, forCellReuseIdentifier: GameListTableViewCell.reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = "Games"
        
        self.view.addSubview(self.gameListTableView)
        self.gameListTableView.pin(edge: .leading, to: .leading, of: self.view.safeAreaLayoutGuide)
        self.gameListTableView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide)
        self.gameListTableView.pin(edge: .bottom, to: .bottom, of: self.view.safeAreaLayoutGuide)
        self.gameListTableView.pinWidth(toWidthOf: self.view, multiplier: 0.3)
        
        self.view.addSubview(self.dividerView)
        self.dividerView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide)
        self.dividerView.pin(edge: .bottom, to: .bottom, of: self.view.safeAreaLayoutGuide)
        self.dividerView.pin(edge: .leading, to: .trailing, of: self.gameListTableView)
        self.dividerView.setWidth(to: 0.5)
        self.dividerView.backgroundColor = .lightGray
        
        self.view.addSubview(self.gamePreviewView)
        self.gamePreviewView.pin(edge: .leading, to: .trailing, of: self.dividerView)
        self.gamePreviewView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide)
        self.gamePreviewView.pin(edge: .bottom, to: .bottom, of: self.view.safeAreaLayoutGuide)
        self.gamePreviewView.pin(edge: .trailing, to: .trailing, of: self.view.safeAreaLayoutGuide)
        
        self.gameModels = DataManager.shared.fetchEntities(sortedBy: "lastUpdated", ascending: false)!
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gameModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.gameListTableView.dequeueReusableCell(withIdentifier: GameListTableViewCell.reuseIdentifier, for: indexPath) as! GameListTableViewCell
        cell.setGame(self.gameModels[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.gamePreviewView.setGame(self.gameModels[indexPath.row])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
