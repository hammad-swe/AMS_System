//
//  LoginViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 27/04/2026.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    
   
    @IBOutlet weak var nameField: UITextField!
    
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
    
    @objc func backPressed(){
        self.navigationController?.popViewController(animated: true)
    }

    @IBAction func forgetTapped(_ sender: Any) {
    }
    
    @IBAction func loginTapped(_ sender: Any) {
        guard let email = nameField.text, !email.isEmpty,
                    let password = passWordField.text, !password.isEmpty else {
                  showAlert("Please enter email & password")
                  return
              }
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
                    if let error = error {
                        self.showAlert(error.localizedDescription)
                        return
                    }

                    self.goToDashboard()
                }
        
    }
    
    
    @IBAction func appleTapped(_ sender: Any) {
    }
    

    @IBAction func googleTapped(_ sender: Any) {
    }
    
    @IBAction func signuptapped(_ sender: Any) {
        goToSignUp()
        
    }
    
    // navigate to dashboard
    func goToDashboard(){
        let vc = AdminDashboardViewController()
        self.navigationController?.setViewControllers([vc], animated: true)
    }
    // navigate to signup
    func goToSignUp(){
        let vc = SignupViewController()
        self.navigationController?.setViewControllers([vc], animated: true)
    }
    // alert
    func showAlert(_ msg: String) {
            let alert = UIAlertController(title: "Info", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
}
