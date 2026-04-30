//
//  SignupViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 27/04/2026.
//

import UIKit
import FirebaseAuth

class SignupViewController: UIViewController {

    
    @IBOutlet weak var nameLabel: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passWordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let backButton = UIBarButtonItem(
                image: UIImage(systemName: "chevron.backward"),
                style: .plain,
                target: self,
                action: #selector(backPressed)
            )
            navigationItem.leftBarButtonItem = backButton
        
    }

    @objc func backPressed() {
        navigationController?.popViewController(animated: true)
    }

    @IBAction func signUpTapped(_ sender: Any) {
        guard let name = nameLabel.text, !name.isEmpty,
                let email = emailField.text, !email.isEmpty,
                    let password = passWordField.text, !password.isEmpty else {
                  showAlert("Please enter email & password")
                  return
              }
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                  if let error = error {
                      self.showAlert(error.localizedDescription)
                      return
                  }

                  self.showAlert("Account Created!")
            
            self.goToLogin()
              }
        
        
    }
    
    
    @IBAction func googleTapped(_ sender: Any) {
    }
    
    
    @IBAction func appleTapped(_ sender: Any) {
    }
    
    
    @IBAction func loginTapped(_ sender: Any) {
        self.goToLogin()
    }
    
    
    //  helper functions
    
    func goToLogin(){
        let vc = LoginViewController()
        self.navigationController?.setViewControllers([vc], animated: true)
    }
    
    func showAlert(_ msg: String) {
            let alert = UIAlertController(title: "Info", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
}
