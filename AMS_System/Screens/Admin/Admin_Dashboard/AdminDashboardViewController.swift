//
//  AdminDashboardViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 05/05/2026.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
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
   private var attendanceListener: ListenerRegistration?
    
    
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
//        loadStudents()
//        setupPieChart()
        setupEmptyPieChart()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadStudents()
        attendanceListener?.remove()
        
    }
    
    private func setupEmptyPieChart() {
            pieChartView.noDataText       = "Loading attendance..."
            pieChartView.noDataTextColor  = .secondaryLabel
            pieChartView.noDataFont       = .systemFont(ofSize: 14)
            pieChartView.data             = nil
        }
    
    
    // MARK: - Load Students
        private func loadStudents() {
            StudentManager.shared.fetchAllStudents { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let students):
                        self?.students = students  // ✅ stored here
                        self?.loadAttendanceMap(for: students) 
//                        self?.StudentTableView.reloadData()
                        print("✅ Students loaded: \(students.count)")
                        
                        self?.startAttendanceListener()

                    case .failure(let error):
                        print("❌ Failed to load students: \(error.localizedDescription)")
                        self?.showAlert("Error", message: error.localizedDescription)
                    }
                }
            }
        }
    
    private func loadAttendanceMap(for students: [Student]) {
        let today = AttendanceManager.shared.todayString  // ✅ reuse existing helper

        AttendanceManager.shared.fetchAttendanceForDate(today, students: students) { [weak self] recordMap in
            self?.attendanceMap = recordMap.mapValues { $0.status }  // ⚠️ adjust .status to your field name
            self?.StudentTableView.reloadData()
        }
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
        
        guard !students.isEmpty else {
               showAlert("Error", message: "No students found. Please wait.")
               return
           }

           let vc = AdminAttendanceViewController(nibName: "AdminAttendanceViewController", bundle: nil)
           vc.students = students  // ✅ must be set before push
           navigationController?.pushViewController(vc, animated: true)
//        // Navigate to Attendance Page
//        let vc = AdminAttendanceViewController(nibName: "AdminAttendanceViewController", bundle: nil)
//        self.navigationController?.pushViewController(vc, animated: true)
    }
    
//     // func for pie chart
//    func setupPieChart() {
//            let entry1 = PieChartDataEntry(value: 65, label: "Present")
//            let entry2 = PieChartDataEntry(value: 20, label: "Late")
//        let entry3 = PieChartDataEntry(value: 15, label: "Absent")
//            
//            let dataSet = PieChartDataSet(entries: [entry1, entry2, entry3], label: "Platform")
//            dataSet.colors = ChartColorTemplates.joyful()
//            
//            let data = PieChartData(dataSet: dataSet)
//            pieChartView.data = data
//        }
    
    
    // MARK: - Real-Time Attendance Listener
        private func startAttendanceListener() {
            guard !students.isEmpty else { return }

            let db    = Firestore.firestore()
            _ = AttendanceManager.shared.todayString

            // Listen to first student to trigger refresh
            // Re-fetch all stats whenever any attendance changes
            attendanceListener = db.collection("attendance")
                .addSnapshotListener { [weak self] _, _ in
                    guard let self = self else { return }
                    self.updatePieChart()
                }
        }
    
    private func updatePieChart() {
        guard !students.isEmpty else { return }

        AttendanceManager.shared.fetchOverallStats(students: students) { [weak self] present, absent, notMarked in
            guard let self = self else { return }

            let total = self.students.count

            // ✅ Use existing calculatePercentage logic
            let presentRecords  = Array(repeating: AttendanceRecord.mock(status: .present), count: present)
            let absentRecords   = Array(repeating: AttendanceRecord.mock(status: .absent),  count: absent)
            let allRecords      = presentRecords + absentRecords

            let presentPct  = AttendanceManager.shared.calculatePercentage(records: allRecords)
            let absentPct   = total > 0 ? (Double(absent)    / Double(total)) * 100.0 : 0.0
            let notMarkedPct = total > 0 ? (Double(notMarked) / Double(total)) * 100.0 : 0.0

            print("📊 Present: \(present) (\(String(format: "%.1f", presentPct))%)")
            print("📊 Absent: \(absent) (\(String(format: "%.1f", absentPct))%)")
            print("📊 Not Marked: \(notMarked) (\(String(format: "%.1f", notMarkedPct))%)")

            var entries: [PieChartDataEntry] = []
            if present   > 0 { entries.append(PieChartDataEntry(value: presentPct,   label: "Present")) }
            if absent    > 0 { entries.append(PieChartDataEntry(value: absentPct,    label: "Absent")) }
            if notMarked > 0 { entries.append(PieChartDataEntry(value: notMarkedPct, label: "Not Marked")) }

            guard !entries.isEmpty else {
                self.pieChartView.data       = nil
                self.pieChartView.noDataText = "No attendance data for today."
                return
            }

            let dataSet = PieChartDataSet(entries: entries, label: "")
            dataSet.colors = [
                UIColor.systemGreen,
                UIColor.systemRed,
                UIColor.systemGray3
            ]
            dataSet.sliceSpace     = 2
            dataSet.selectionShift = 8

            // ✅ Show percentage in slices
            let data = PieChartData(dataSet: dataSet)
            data.setValueFormatter(PercentageValueFormatter())
            data.setValueFont(.systemFont(ofSize: 12, weight: .semibold))
            data.setValueTextColor(.white)

            self.pieChartView.data                           = data
            self.pieChartView.holeRadiusPercent              = 0.45
            self.pieChartView.holeColor                      = .systemBackground
            self.pieChartView.transparentCircleRadiusPercent = 0.5
            self.pieChartView.drawEntryLabelsEnabled         = false
            self.pieChartView.legend.enabled                 = true
            self.pieChartView.legend.horizontalAlignment     = .center
            self.pieChartView.centerText                     = "\(total)\nStudents"
            self.pieChartView.animate(xAxisDuration: 0.8, easingOption: .easeInOutQuart)
            self.pieChartView.notifyDataSetChanged()
        }
    }
    
    private func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
   
}

  
extension AdminDashboardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return students.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell    = tableView.dequeueReusableCell(withIdentifier: "StudentTableViewCell",
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

