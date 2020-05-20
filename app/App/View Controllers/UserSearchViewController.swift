//
//  UserSearchViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/20/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

protocol UserSearchViewControllerDelegate: AnyObject {
    func userSearchComplete(users: [User])
}

class UserSearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var searchTermTextField: UITextField!
    private var resultsTableView: UITableView!
    
    weak var delegate: UserSearchViewControllerDelegate?
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.searchTermTextField = UITextField()
        self.searchTermTextField.borderStyle = .roundedRect
        self.searchTermTextField.textContentType = .name
        self.searchTermTextField.placeholder = "Search for players"
        
        self.resultsTableView = UITableView()
        self.resultsTableView.delegate = self
        self.resultsTableView.dataSource = self
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(UserSearchViewController.doneButtonPressed))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = "Player Search"
        
        self.view.addSubview(self.searchTermTextField)
        self.searchTermTextField.pinX(to: self.view.safeAreaLayoutGuide, leading: 40, trailing: -40)
        self.searchTermTextField.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 40)
        
        self.view.addSubview(self.resultsTableView)
        self.resultsTableView.pinX(to: self.view.safeAreaLayoutGuide)
        self.resultsTableView.pin(edge: .top, to: .bottom, of: self.searchTermTextField, with: 40)
        self.resultsTableView.pin(edge: .bottom, to: .bottom, of: self.view.safeAreaLayoutGuide)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    @objc func doneButtonPressed(_ sender: Any) {

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
