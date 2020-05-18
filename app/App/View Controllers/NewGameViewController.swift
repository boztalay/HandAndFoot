//
//  NewGameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/18/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class NewGameViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchControllerDelegate, UISearchResultsUpdating {
    
    var gameContentTableView: UITableView!
    var dividerView: UIView!
    var playerSearchResultsTableViewController: UITableViewController!
    var playerSearchController: UISearchController!

    var players: [User]!

    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.gameContentTableView = UITableView(frame: CGRect.zero, style: .grouped)
        self.dividerView = UIView()
        self.playerSearchResultsTableViewController = UITableViewController()
        self.playerSearchController = UISearchController(searchResultsController: self.playerSearchResultsTableViewController)
        self.players = []
        
        self.gameContentTableView.delegate = self
        self.gameContentTableView.dataSource = self
        
        self.playerSearchController.delegate = self
        self.playerSearchController.searchResultsUpdater = self
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(NewGameViewController.cancelButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(NewGameViewController.doneButtonPressed))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = "New Game"
        
        self.view.addSubview(self.gameContentTableView)
        self.gameContentTableView.pinY(to: self.view)
        self.gameContentTableView.pin(edge: .leading, to: .leading, of: self.view)
        self.gameContentTableView.pinWidth(toWidthOf: self.view, multiplier: 0.5, constant: 0)
        
        self.view.addSubview(self.dividerView)
        self.dividerView.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide)
        self.dividerView.pin(edge: .bottom, to: .bottom, of: self.view.safeAreaLayoutGuide)
        self.dividerView.pin(edge: .leading, to: .trailing, of: self.gameContentTableView)
        self.dividerView.setWidth(to: 0.5)
        self.dividerView.backgroundColor = .lightGray
        
        self.view.addSubview(self.playerSearchResultsTableViewController.view)
        self.playerSearchResultsTableViewController.view.pinY(to: self.view)
        self.playerSearchResultsTableViewController.view.pin(edge: .leading, to: .trailing, of: self.dividerView)
        self.playerSearchResultsTableViewController.view.pin(edge: .trailing, to: .trailing, of: self.view)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch (section) {
            case 0:
                return 1
            case 1:
                return players.count
            default:
                return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel!.text = "Game Title"
            return cell
        } else {
            let player = self.players[indexPath.row]
            let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
            cell.textLabel!.text = player.email
            return cell
        }
    }

    func updateSearchResults(for searchController: UISearchController) {

    }
    
    @objc func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func doneButtonPressed(_ sender: Any) {
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
