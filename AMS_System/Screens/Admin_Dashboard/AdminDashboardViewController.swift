//
//  AdminDashboardViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 29/04/2026.
//

//import UIKit
//
//class AdminDashboardViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
//    }
//
//
//}

import UIKit
import FirebaseAuth

class AdminDashboardViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var roleTagLabel: UILabel!
    @IBOutlet weak var studentsCountLabel: UILabel!
    @IBOutlet weak var studentsTableView: UITableView!
    @IBOutlet weak var deleteAccountButton: UIButton!
    @IBOutlet weak var signOutButton: UIButton!

    var user: FirebaseAuth.User?
    private var students: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateUserInfo()
        fetchStudents()
    }

    private func setupUI() {
        roleTagLabel.text = "ADMIN"
        roleTagLabel.backgroundColor = .systemRed
        roleTagLabel.textColor = .white
        roleTagLabel.layer.cornerRadius = 6
        roleTagLabel.clipsToBounds = true

        studentsTableView.dataSource = self
        studentsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    private func populateUserInfo() {
        nameLabel.text = user?.displayName ?? "Admin"
        emailLabel.text = user?.email ?? ""
    }

    private func fetchStudents() {
        RoleManager.shared.fetchAllStudents { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let students) = result {
                    self?.students = students
                    self?.studentsCountLabel.text = "Students: \(students.count)"
                    self?.studentsTableView.reloadData()
                }
            }
        }
    }

    // MARK: - Sign Out
    @IBAction func signOutTapped(_ sender: UIButton) {
        AuthManager.shared.signOut { [weak self] _ in
            DispatchQueue.main.async {
                self?.navigateToLogin()
            }
        }
    }

    // MARK: - Delete Account (deletes all students too)
    @IBAction func deleteAccountTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "⚠️ Delete Admin Account",
            message: "This will permanently delete your account AND all student data. This cannot be undone.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Everything", style: .destructive) { [weak self] _ in
            self?.performDeleteAccount()
        })

        present(alert, animated: true)
    }

    private func performDeleteAccount() {
        deleteAccountButton.isEnabled = false

        AuthManager.shared.deleteAdminAccount { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.navigateToLogin()
                case .failure(let error):
                    self?.deleteAccountButton.isEnabled = true
                    let alert = UIAlertController(title: "Error",
                                                  message: error.localizedDescription,
                                                  preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }

    private func navigateToLogin() {
        let loginVC = LoginViewController(nibName: "LoginViewController", bundle: nil)
        navigationController?.setViewControllers([loginVC], animated: true)
    }
}

// MARK: - UITableViewDataSource
extension AdminDashboardViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return students.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let student = students[indexPath.row]
        cell.textLabel?.text = student["name"] as? String ?? "Unknown"
        cell.detailTextLabel?.text = student["email"] as? String ?? ""
        return cell
    }
}
