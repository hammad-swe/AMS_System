//
//  StudentDashboardViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 29/04/2026.
//


import UIKit
import FirebaseAuth

class StudentDashboardViewController: UIViewController {
    
    
    var user: FirebaseAuth.User?
    private var todayRecord: AttendanceRecord?

    private enum CheckState {
            case notCheckedIn
            case checkedIn
            case checkedOut
        }

        private var checkState: CheckState = .notCheckedIn {
            didSet { updateCheckButtonUI() }
        }
    
    // MARK: - IBOutlets
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var checkLabel: UILabel!
    @IBOutlet weak var checkShowButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Stuent Dashboard"
        
        let signOutButton = UIBarButtonItem(
            title: "Sign Out",
            style: .plain,
            target: self,
            action: #selector(signOutTapped)
        )
        signOutButton.tintColor = .systemRed
        navigationItem.rightBarButtonItem = signOutButton
        
//        //checknutton design
//        
//        checkButton.layer.cornerRadius = checkButton.frame.width / 2
//
//            checkButton.layer.borderWidth = 8
//            checkButton.layer.borderColor = UIColor.white.cgColor
//
//            checkButton.clipsToBounds = true
        
//        setupUI()
//        populateUserInfo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        checkButton.layer.cornerRadius = checkButton.frame.width / 2
        checkButton.layer.borderWidth = 8
                   checkButton.layer.borderColor = UIColor.blue.cgColor
        checkButton.clipsToBounds = true
    }
    
    // MARK: - Load Today Record
        private func loadTodayRecord() {
            guard let uid = user?.uid else { return }

            AttendanceManager.shared.fetchTodayRecord(for: uid) { [weak self] record in
                DispatchQueue.main.async {
                    self?.todayRecord = record
                    self?.updateStateFromRecord(record)
                }
            }
        }

    
    // MARK: - Determine State from Record
        private func updateStateFromRecord(_ record: AttendanceRecord?) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "hh:mm a"

            guard let record = record else {
                checkState       = .notCheckedIn
               // statusLabel.text = "You haven't checked in today."
                return
            }

            if let checkOut = record.checkOut {
                // Already checked out
                checkState = .checkedOut
                var text = "Checked out at \(timeFormatter.string(from: checkOut))"
                if let duration = record.durationMinutes {
                    text += " · \(duration) min"
                }
               // statusLabel.text = text

            } else if record.checkIn != nil {
                // Checked in but not out
                checkState       = .checkedIn
               // statusLabel.text = "Checked in at \(timeFormatter.string(from: checkIn))"

            } else {
                checkState       = .notCheckedIn
               // statusLabel.text = "You haven't checked in today."
            }
        }
    
    
    // MARK: - Update Button based on State
        private func updateCheckButtonUI() {
            switch checkState {
            case .notCheckedIn:
                checkButton.setTitle("Check In", for: .normal)
                checkButton.backgroundColor = .systemGreen
                checkButton.setTitleColor(.white, for: .normal)
                checkButton.isEnabled = true
                checkLabel.text = "Last Action: Not Check In"
                checkShowButton.backgroundColor = .red
                checkShowButton.setTitle("Not Check In", for: .normal)

            case .checkedIn:
                checkButton.setTitle("Check Out", for: .normal)
                checkButton.backgroundColor = .systemOrange
                checkButton.setTitleColor(.white, for: .normal)
                checkButton.isEnabled = true
                checkLabel.text = "Last Action: Check In"
                checkShowButton.backgroundColor = .green
                checkShowButton.setTitle("Check in", for: .normal)

            case .checkedOut:
                checkButton.setTitle("Done", for: .normal)
                checkButton.backgroundColor = .systemGray4
                checkButton.setTitleColor(.secondaryLabel, for: .normal)
                checkButton.isEnabled = false
                checkLabel.text = "Last Action: Done for Today"
                checkShowButton.backgroundColor = .orange
                checkShowButton.setTitle("Check Out", for: .normal)
            }

            // Rounded button
            checkButton.layer.cornerRadius = 12
            checkButton.clipsToBounds = true
        }
    
    @IBAction func checkButtonTapped(_ sender: UIButton) {
        switch checkState {
                case .notCheckedIn:
                    performCheckIn()
                case .checkedIn:
                    performCheckOut()
                case .checkedOut:
                    break
                }
    }
    
    // MARK: - Check In
        private func performCheckIn() {
            guard let uid  = user?.uid,
                  let name = user?.displayName ?? user?.email else { return }

            checkButton.isEnabled = false

            AttendanceManager.shared.checkIn(studentUID: uid, studentName: name) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.loadTodayRecord()
                        self?.loadAttendancePercentage()
                    case .failure(let error):
                        self?.checkButton.isEnabled = true
                        self?.showAlert("Error", message: error.localizedDescription)
                    }
                }
            }
        }

        // MARK: - Check Out
        private func performCheckOut() {
            guard let uid = user?.uid else { return }

            checkButton.isEnabled = false

            AttendanceManager.shared.checkOut(studentUID: uid) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.loadTodayRecord()
                        self?.loadAttendancePercentage()
                    case .failure(let error):
                        self?.checkButton.isEnabled = true
                        self?.showAlert("Error", message: error.localizedDescription)
                    }
                }
            }
        }
    
    // MARK: - Attendance Percentage
       private func loadAttendancePercentage() {
//           guard let uid = user?.uid else { return }
//
//           AttendanceManager.shared.fetchAttendanceHistory(for: uid) { [weak self] result in
//               DispatchQueue.main.async {
//                   guard case .success(let records) = result else { return }
//
//                   let percentage = AttendanceManager.shared.calculatePercentage(records: records)
//                   //self?.percentageLabel.text = String(format: "%.1f%%", percentage)
//                  // self?.progressView.setProgress(Float(percentage / 100.0), animated: true)
//
//                   switch percentage {
//                   case 75...100:
//                       //self?.progressView.progressTintColor = .systemGreen
//                      // self?.percentageLabel.textColor      = .systemGreen
//                   case 50..<75:
//                      // self?.progressView.progressTintColor = .systemOrange
//                      // self?.percentageLabel.textColor      = .systemOrange
//                   default: break
//                      // self?.progressView.progressTintColor = .systemRed
//                     //  self?.percentageLabel.textColor      = .systemRed
//                   }
//               }
//           }
       }
    
    // signout tapped
    @objc private func signOutTapped() {
        // Show confirmation alert first
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
            self?.performSignOut()
        })

        present(alert, animated: true)
    }

    private func performSignOut() {
        AuthManager.shared.signOut { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Navigate back to login screen
                    let loginVC = LoginViewController() // replace with your login VC
                    let nav = UINavigationController(rootViewController: loginVC)
                    nav.modalPresentationStyle = .fullScreen
                    self?.view.window?.rootViewController = nav
                    
                case .failure(let error):
                    let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
    
    // MARK: - Alert
        private func showAlert(_ title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }

}
