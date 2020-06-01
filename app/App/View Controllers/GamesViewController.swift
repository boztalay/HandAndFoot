//
//  GamesViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/28/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class GamesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, LogOutDelegate, PlayButtonDelegate {

    var gameListTableView: UITableView!
    var dividerView: UIView!
    var gamePreviewView: GamePreviewView!
    
    var gameModels: [GameModel]!
    weak var logOutDelegate: LogOutDelegate?
    
    private var selectedGame: GameModel?

    init() {
        super.init(nibName: nil, bundle: nil)

        self.gameListTableView = UITableView()
        self.dividerView = UIView()
        self.gamePreviewView = GamePreviewView()
        self.gameModels = []

        self.gameListTableView.delegate = self
        self.gameListTableView.dataSource = self
        self.gameListTableView.register(GameListTableViewCell.self, forCellReuseIdentifier: GameListTableViewCell.reuseIdentifier)
        
        self.gamePreviewView.delegate = self
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "New Game", style: .plain, target: self, action: #selector(GamesViewController.newGameButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Profile", style: .plain, target: self, action: #selector(GamesViewController.profileButtonPressed))
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.reloadGameModels()
        
        Network.shared.subscribeToSyncEvents(label: "GamesViewController") {
            self.reloadGameModels()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        Network.shared.unsubscribeFromSyncEvents(label: "GamesViewController")
    }
    
    func reloadGameModels() {
        let selectedGameId = self.selectedGame?.id
        
        self.gameModels = DataManager.shared.fetchEntities(sortedBy: "lastUpdated", ascending: false)!
        self.gameListTableView.reloadData()
        
        if self.gameModels.count > 0 {
            let rowToSelect: Int
            if let selectedGameId = selectedGameId {
                rowToSelect = self.gameModels.firstIndex(where: { $0.id == selectedGameId })!
            } else {
                rowToSelect = 0
            }
        
            let indexPath = IndexPath(item: rowToSelect, section: 0)
            self.gameListTableView.selectRow(at: indexPath, animated: false, scrollPosition: .top)
            self.tableView(self.gameListTableView, didSelectRowAt: indexPath)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.gameModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.gameListTableView.dequeueReusableCell(withIdentifier: GameListTableViewCell.reuseIdentifier, for: indexPath) as! GameListTableViewCell
        cell.setGameModel(self.gameModels[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedGame = self.gameModels[indexPath.row]
        self.gamePreviewView.setGameModel(self.selectedGame!)
    }
    
    @objc func newGameButtonPressed(_ sender: Any) {
        let newGameViewController = NewGameViewController()
        let navigationController = UINavigationController(rootViewController: newGameViewController)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    @objc func profileButtonPressed(_ sender: Any) {
        let profileViewController = ProfileViewController()
        profileViewController.logOutDelegate = self
        let navigationController = UINavigationController(rootViewController: profileViewController)
        self.present(navigationController, animated: true, completion: nil)
    }
    
    func playButtonPressed() {
        let gameViewController = GameViewController(gameModel: self.selectedGame!)
        self.navigationController?.pushViewController(gameViewController, animated: true)
    }

    func userLoggedOut() {
        self.logOutDelegate?.userLoggedOut()
        self.dismiss(animated: true, completion: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
