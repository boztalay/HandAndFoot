//
//  NewGameViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 5/18/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class NewGameViewController: UIViewController, UserSearchViewControllerDelegate {

    var titleTextField: UITextField!
    
    init() {
        super.init(nibName: nil, bundle: nil)

        self.titleTextField = UITextField()
        self.titleTextField.borderStyle = .roundedRect
        self.titleTextField.textContentType = .name
        self.titleTextField.placeholder = "Game Title"
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(NewGameViewController.cancelButtonPressed))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(NewGameViewController.nextButtonPressed))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.title = "New Game"
        
        self.view.addSubview(self.titleTextField)
        self.titleTextField.pinX(to: self.view.safeAreaLayoutGuide, leading: 40, trailing: -40)
        self.titleTextField.pin(edge: .top, to: .top, of: self.view.safeAreaLayoutGuide, with: 40)
    }
    
    @objc func cancelButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func nextButtonPressed(_ sender: Any) {
        guard let title = self.titleTextField.text, title.count > 0 else {
            UIAlertController.presentErrorAlert(on: self, title: "Game Title Required")
            return
        }
        
        let userSearchViewController = UserSearchViewController()
        userSearchViewController.delegate = self
        self.navigationController!.pushViewController(userSearchViewController, animated: true)
    }
    
    func userSearchComplete(users: [User]) {
        guard let title = self.titleTextField.text, title.count > 0 else {
            fatalError()
        }
        
        let userEmails = users.map() { $0.email! }
        
        Network.shared.sendCreateGameRequest(title: title, userEmails: userEmails) { (success, httpStatusCode, response) in
            guard success else {
                UIAlertController.presentErrorAlert(on: self, title: "Couldn't Create Game") {
                    self.dismiss(animated: true, completion: nil)
                }

                return
            }
            
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
