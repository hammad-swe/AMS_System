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
        guard let email =  emailField.text, !email.isEmpty,
                     let password = passWordField.text, !password.isEmpty else {
                   showError("Please enter email and password.")
                   return
               }

               AuthManager.shared.signUpWithEmail(email: email,
                                                  password: password,
                                                  presenting: self) { [weak self] result in
                   DispatchQueue.main.async {
                       switch result {
                       case .success(let (user, role)):
                           self?.navigate(user: user, role: role)
                       case .failure(let error):
                           self?.showError(error.localizedDescription)
                       }
                   }
               }
        
    }
    
    // MARK: - Add this navigate function
        private func navigate(user: FirebaseAuth.User, role: UserRole) {
            let vc: UIViewController

            switch role {
            case .admin:
                let adminVC = AdminDashboardViewController(nibName: "AdminDashboardViewController", bundle: nil)
                adminVC.user = user
                vc = adminVC

            case .student:
                let studentVC = StudentDashboardViewController(nibName: "StudentDashboardViewController", bundle: nil)
                studentVC.user = user
                vc = studentVC
            }

            navigationController?.setViewControllers([vc], animated: true)
        }

        // MARK: - Add this error function if missing
        private func showError(_ message: String) {
            //errorLabel.text = message
            //errorLabel.isHidden = false
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
