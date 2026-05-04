//
//  LoginViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 27/04/2026.
//

import UIKit
import GoogleSignIn
import FirebaseAuth

class LoginViewController: UIViewController {
    
    
   
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var passWordField: UITextField!
    
    @IBOutlet weak var googleSignInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
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
                   showError("Please enter email and password.")
                   return
               }

               AuthManager.shared.signInWithEmail(email: email,
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
    
    
    @IBAction func appleTapped(_ sender: Any) {
        
    }
    

    @IBAction func googleTapped(_ sender: Any) {
       // errorLabel.isHidden = true

                AuthManager.shared.signInWithGoogle(presenting: self) { [weak self] result in
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
    // MARK: - Restore Previous Session
       private func checkPreviousSignIn() {
           AuthManager.shared.restorePreviousSignIn { [weak self] result in
               DispatchQueue.main.async {
                   if case .success(let (user, role)) = result {
                       self?.navigate(user: user, role: role)
                   }
               }
           }
       }
    
    
    @IBAction func signuptapped(_ sender: Any) {
        goToSignUp()
        
    }
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
    
    // navigate to signup
    func goToSignUp(){
        let vc = SignupViewController()
        self.navigationController?.setViewControllers([vc], animated: true)
    }
    
    func goToDashboard(){
        let vc = AdminDashboardViewController()
        self.navigationController?.setViewControllers([vc], animated: true)
    }
    // alert
    func showAlert(_ msg: String) {
            let alert = UIAlertController(title: "Info", message: msg, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    // MARK: - Error
        private func showError(_ message: String) {
           // errorLabel.text = message
           // errorLabel.isHidden = false
        }
    

}
