//
//  AdminProfileViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 14/05/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore


class AdminProfileViewController: UIViewController {
    
    var user: FirebaseAuth.User?
    private let db = Firestore.firestore()
    
    
    @IBOutlet weak var ProfileImage: UIImageView!
    @IBOutlet weak var ProfileName: UILabel!
    @IBOutlet weak var ProfileEmail: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchProfile()
        // Do any additional setup after loading the view.
    }
    
    private func fetchProfile() {
        AuthManager.shared.fetchUserProfile { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                                self.ProfileName.text  = data["name"]  as? String ?? "No Name"
                                self.ProfileEmail.text = data["email"] as? String ?? "No Email"
                            }

            case .failure(let error):
                print("Profile fetch error: \(error.localizedDescription)")
            }
        }
    }
    
    
    @IBAction func LogoutButton(_ sender: Any) {
            // Ask user first
            let confirm = UIAlertController(
                title: "Logout",
                message: "Are you sure you want to logout?",
                preferredStyle: .alert
            )
            
            confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            confirm.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
                self.performLogout()
            })
            
            present(confirm, animated: true)
        }

        // MARK: - Perform Logout
        private func performLogout() {
            AuthManager.shared.signOut { result in
                switch result {
                case .success():
                    DispatchQueue.main.async {
                        let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
                        
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController = loginVC
                            window.makeKeyAndVisible()
                        }
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        let alert = UIAlertController(
                            title: "Logout Failed",
                            message: error.localizedDescription,
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true)
                    }
                }
            }
        }
    }
    

