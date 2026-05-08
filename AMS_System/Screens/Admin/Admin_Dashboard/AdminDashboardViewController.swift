//
//  AdminDashboardViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 05/05/2026.
//

import UIKit
import FirebaseAuth
import Charts
import DGCharts

class AdminDashboardViewController: UIViewController {

    @IBOutlet weak var pieChartView: PieChartView!
    @IBOutlet weak var adminName: UILabel!
    @IBOutlet weak var StudentTableView: UITableView!
    @IBOutlet weak var Card1: UIStackView!

    @IBOutlet weak var Card2: UIStackView!
    var user: FirebaseAuth.User?
    private var students: [Student] = []
    private var attendanceMap: [String: AttendanceStatus] = [:]  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Admin Dashboard"
        // Add sign out button to right side of navbar
            let signOutButton = UIBarButtonItem(
                title: "Sign Out",
                style: .plain,
                target: self,
                action: #selector(signOutTapped)
            )
            signOutButton.tintColor = .systemRed
            navigationItem.rightBarButtonItem = signOutButton
        
        
        
        adminName.text = "Welcome, \(user?.displayName ?? user?.email ?? "Admin")"
        Card1.layer.cornerRadius = 12
        Card1.clipsToBounds = true
        Card2.layer.cornerRadius = 12
        Card2.clipsToBounds = true
        setupGestures()
        
        StudentTableView.dataSource = self
        StudentTableView.delegate   = self
        StudentTableView.register(UINib(nibName: "StudentTableViewCell", bundle: nil),
                                           forCellReuseIdentifier: "StudentTableViewCell")
        StudentTableView.rowHeight = 70
        setupPieChart()
        // Do any additional setup after loading the view.
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

    // func for add, mark stack
    private func setupGestures() {
        // 1. Enable interaction for both
        Card1.isUserInteractionEnabled = true
        Card2.isUserInteractionEnabled = true

        // 2. Add gesture for Add Student
        let addTap = UITapGestureRecognizer(target: self, action: #selector(didTapAddStudent))
        Card1.addGestureRecognizer(addTap)

        // 3. Add gesture for Mark Attendance
        let attendanceTap = UITapGestureRecognizer(target: self, action: #selector(didTapMarkAttendance))
        Card2.addGestureRecognizer(attendanceTap)
    }
    
    
    
    @objc private func didTapAddStudent() {
        // Navigate to Add Student Page
        let vc = AddStudentViewController(nibName: "AddStudentViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func didTapMarkAttendance() {
        // Navigate to Attendance Page
        let vc = AdminAttendanceViewController(nibName: "AdminAttendanceViewController", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
     // func for pie chart
    func setupPieChart() {
            let entry1 = PieChartDataEntry(value: 65, label: "Present")
            let entry2 = PieChartDataEntry(value: 20, label: "Late")
        let entry3 = PieChartDataEntry(value: 15, label: "Absent")
            
            let dataSet = PieChartDataSet(entries: [entry1, entry2, entry3], label: "Platform")
            dataSet.colors = ChartColorTemplates.joyful()
            
            let data = PieChartData(dataSet: dataSet)
            pieChartView.data = data
        }
   
}

    

extension AdminDashboardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       return students.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StudentTableViewCell",
                                                  for: indexPath) as! StudentTableViewCell
        let student = students[indexPath.row]
                let status  = attendanceMap[student.uid] ?? .absent  // ✅ actual value

                cell.configure(student: student, status: status)
                cell.onToggle = { [weak self] newStatus in
                    self?.attendanceMap[student.uid] = newStatus
                }
                return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let student = students[indexPath.row]
        let vc = StudentAttendanceViewController(nibName: "StudentAttendanceViewController", bundle: nil)
  vc.studentUID  = student.uid
  vc.studentName = student.name
        navigationController?.pushViewController(vc, animated: true)
    }
}
