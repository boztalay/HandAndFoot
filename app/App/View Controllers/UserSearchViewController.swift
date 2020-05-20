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

class UserSearchViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    
    private static let reuseIdentifier = "UserSearchViewControllerTableViewCell"

    private var searchTermTextField: UITextField!
    private var resultsTableView: UITableView!
    
    weak var delegate: UserSearchViewControllerDelegate?

    private var isSearchInFlight: Bool!
    private var results: [JSONDictionary]!
    private var selectedResults: [Int : JSONDictionary]!
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.searchTermTextField = UITextField()
        self.searchTermTextField.delegate = self
        self.searchTermTextField.borderStyle = .roundedRect
        self.searchTermTextField.textContentType = .name
        self.searchTermTextField.placeholder = "Search for players"
        
        self.resultsTableView = UITableView()
        self.resultsTableView.delegate = self
        self.resultsTableView.dataSource = self
        
        self.isSearchInFlight = false
        self.results = []
        self.selectedResults = [:]
        
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
        self.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if let reusedCell = tableView.dequeueReusableCell(withIdentifier: UserSearchViewController.reuseIdentifier) {
            cell = reusedCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: UserSearchViewController.reuseIdentifier)
        }
        
        let result = self.results[indexPath.row]
        guard let userId = result["id"] as? Int,
              let firstName = result["first_name"] as? String,
              let lastName = result["last_name"] as? String else {
            fatalError()
        }

        cell.textLabel!.text = "\(firstName) \(lastName)"
        
        if self.selectedResults[userId] == nil {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.resultsTableView.deselectRow(at: indexPath, animated: true)
        
        let result = self.results[indexPath.row]
        guard let userId = result["id"] as? Int else {
            fatalError()
        }
        
        if self.selectedResults[userId] == nil {
            self.selectedResults[userId] = result
        } else {
            self.selectedResults.removeValue(forKey: userId)
        }

        self.resultsTableView.reloadData()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard !self.isSearchInFlight else {
            return true
        }
        
        guard let searchTerm = textField.text, searchTerm.count > 0 else {
            return true
        }
        
        self.isSearchInFlight = true
        
        Network.shared.sendUserSearchRequest(searchTerm: searchTerm) { (success, httpStatusCode, response) in
            self.isSearchInFlight = false
            
            guard success else {
                UIAlertController.presentErrorAlert(on: self, title: "Couldn't Search")
                return
            }
            
            guard let userJsons = response?["users"] as? [JSONDictionary] else {
                UIAlertController.presentErrorAlert(on: self, title: "Bad Search Response")
                return
            }
            
            self.results = userJsons
            self.resultsTableView.reloadData()
        }
        
        return true
    }
    
    @objc func doneButtonPressed(_ sender: Any) {
        let users: [User] = self.selectedResults.values.map() { try! User.updateOrCreate(from: $0) }
        self.delegate?.userSearchComplete(users: users)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
