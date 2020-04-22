//
//  LoginViewController.swift
//  HandAndFoot
//
//  Created by Ben Oztalay on 4/14/20.
//  Copyright © 2020 Ben Oztalay. All rights reserved.
//

import UIKit

enum LoginViewControllerMode: String, CaseIterable {
    case logIn = "Log In"
    case signUp = "Sign Up"
}

class LoginViewController: UIViewController {
    
    var modeSegmentedControl: UISegmentedControl
    var nameTextField: UITextField
    var emailTextField: UITextField
    var passwordTextField: UITextField
    var passwordConfirmationTextField: UITextField
    var logOrSignInButton: UIButton
    
    var mode: LoginViewControllerMode
    
    init() {
        self.modeSegmentedControl = UISegmentedControl(items: LoginViewControllerMode.allCases.map({ $0.rawValue }))
        self.modeSegmentedControl.selectedSegmentIndex = 0
        
        self.emailTextField = UITextField()
        self.emailTextField.textContentType = .emailAddress
        self.emailTextField.placeholder = "Electronic Mail Address"
        
        self.passwordTextField = UITextField()
        self.passwordTextField.textContentType = .password
        self.passwordTextField.placeholder = "Password"
        self.passwordTextField.isSecureTextEntry = true
        
        self.nameTextField = UITextField()
        self.nameTextField.textContentType = .name
        self.nameTextField.placeholder = "Name"
        
        self.passwordConfirmationTextField = UITextField()
        self.passwordConfirmationTextField.textContentType = .password
        self.passwordConfirmationTextField.placeholder = "Password (Again [Sorry])"
        self.passwordConfirmationTextField.isSecureTextEntry = true
        
        self.logOrSignInButton = UIButton()

        self.mode = .logIn
        
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        self.view.addSubview(self.modeSegmentedControl)
        self.modeSegmentedControl.addTarget(self, action: #selector(LoginViewController.modeSegmentedControlChanged), for: .valueChanged)
        self.modeSegmentedControl.centerHorizontally(in: self.view)
        self.modeSegmentedControl.pin(edge: .top, to: .top, of: self.view, with: 10.0)
        
        self.view.addSubview(self.logOrSignInButton)
        self.logOrSignInButton.addTarget(self, action: #selector(LoginViewController.logInOrSignInButtonPressed), for: .touchUpInside)
        
        self.setMode(.logIn)
    }

    @objc func modeSegmentedControlChanged(_ sender: Any) {
        let mode = LoginViewControllerMode.allCases[self.modeSegmentedControl.selectedSegmentIndex]
        self.setMode(mode)
    }
    
    func setMode(_ mode: LoginViewControllerMode) {
        self.mode = mode
        
        self.nameTextField.removeFromSuperview()
        self.emailTextField.removeFromSuperview()
        self.passwordTextField.removeFromSuperview()
        self.passwordConfirmationTextField.removeFromSuperview()
        
        switch self.mode {
            case .logIn:
                self.setUpViewsForLoggingIn()
            case .signUp:
                self.setUpViewsForSigningUp()
        }
    }
    
    func setUpViewsForLoggingIn() {
        self.view.addSubview(self.emailTextField)
        self.emailTextField.centerHorizontally(in: self.view)
        self.emailTextField.pin(edge: .top, to: .bottom, of: self.modeSegmentedControl, with: 10.0)
        
        self.view.addSubview(self.passwordTextField)
        self.passwordTextField.centerHorizontally(in: self.view)
        self.passwordTextField.pin(edge: .top, to: .bottom, of: self.emailTextField, with: 10.0)
    }
    
    func setUpViewsForSigningUp() {
        self.view.addSubview(self.nameTextField)
        self.nameTextField.centerHorizontally(in: self.view)
        self.nameTextField.pin(edge: .top, to: .bottom, of: self.modeSegmentedControl, with: 10.0)
        
        self.view.addSubview(self.emailTextField)
        self.emailTextField.centerHorizontally(in: self.view)
        self.emailTextField.pin(edge: .top, to: .bottom, of: self.nameTextField, with: 10.0)
        
        self.view.addSubview(self.passwordTextField)
        self.passwordTextField.centerHorizontally(in: self.view)
        self.passwordTextField.pin(edge: .top, to: .bottom, of: self.emailTextField, with: 10.0)
        
        
        self.view.addSubview(self.passwordConfirmationTextField)
        self.passwordConfirmationTextField.centerHorizontally(in: self.view)
        self.passwordConfirmationTextField.pin(edge: .top, to: .bottom, of: self.passwordTextField, with: 10.0)
    }
    
    @objc func logInOrSignInButtonPressed(_ sender: Any) {
        // TODO: Make more generic for what mode we're in
        
        guard let email = self.emailTextField.text,
              let password = self.passwordTextField.text else {
            return
        }
        
        Network.shared.sendLoginRequest(email: email, password: password) { (success, httpStatusCode, response) in
            print("Success: \(success)")
            print("Status Code: \(String(describing: httpStatusCode))")
            print("Response: \(String(describing: response))")

            guard success else {
                return
            }

            DataManager.shared.setCurrentUser(with: email)
            DataManager.shared.sync() { (success) in
                print("Sync success: \(success)")
            }
        }
    }

    @objc func signUpButtonPressed(_ sender: Any) {
        guard let name = self.nameTextField.text,
              let email = self.emailTextField.text,
              let password = self.passwordTextField.text,
              let passwordConfirmation = self.passwordConfirmationTextField.text else {
            
            let alert = UIAlertController.init(
                title: "Missing Field",
                message: "Please fill out all fields!",
                preferredStyle: .alert
            )

            alert.show(self, sender: nil)
            return
        }
        
        guard password == passwordConfirmation else {
            let alert = UIAlertController.init(
                title: "Password Mismatch",
                message: "Passwords don't match!",
                preferredStyle: .alert
            )

            alert.show(self, sender: nil)
            return
        }
        
        Network.shared.sendSignUpRequest(name: name, email: email, password: password) { (success, httpStatusCode, response) in
            print("Success: \(success)")
            print("Status Code: \(String(describing: httpStatusCode))")
            print("Response: \(String(describing: response))")
            
            guard success else {
                return
            }

            DataManager.shared.setCurrentUser(with: email)
            DataManager.shared.sync() { (success) in
                print("Sync success: \(success)")
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}
