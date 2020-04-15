//
//  LoginViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/14/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var logInEmailTextField: UITextField!
    @IBOutlet weak var logInPasswordTextField: UITextField!
    
    @IBOutlet weak var signUpNameTextField: UITextField!
    @IBOutlet weak var signUpEmailTextField: UITextField!
    @IBOutlet weak var signUpPasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func logInButtonPressed(_ sender: Any) {
        guard let email = self.logInEmailTextField.text,
              let password = self.logInPasswordTextField.text else {
            return
        }
        
        Network.shared.sendLoginRequest(email: email, password: password) { success, httpStatusCode, response in
            print("Success: \(success)")
            print("Status Code: \(String(describing: httpStatusCode))")
            print("Response: \(String(describing: response))")
        }
    }

    @IBAction func signUpButtonPressed(_ sender: Any) {
        guard let name = self.signUpNameTextField.text,
              let email = self.signUpEmailTextField.text,
              let password = self.signUpPasswordTextField.text else {
            return
        }
        
        Network.shared.sendSignUpRequest(name: name, email: email, password: password) { success, httpStatusCode, response in
            print("Success: \(success)")
            print("Status Code: \(String(describing: httpStatusCode))")
            print("Response: \(String(describing: response))")
        }
    }
}
