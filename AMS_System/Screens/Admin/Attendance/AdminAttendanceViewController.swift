//
//  AdminAttendanceViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 06/05/2026.
//

import UIKit

class AdminAttendanceViewController: UIViewController {

        // MARK: - IBOutlets
        @IBOutlet weak var datePicker: UIDatePicker!
        @IBOutlet weak var attendanceTableView: UITableView!
        @IBOutlet weak var saveButton: UIButton!
        @IBOutlet weak var dateLabel: UILabel!
    
        var students: [Student] = []
        private var attendanceMap: [String: AttendanceStatus] = [:]
        private var selectedDate: String = ""

        override func viewDidLoad() {
            super.viewDidLoad()
            title = "Mark Attendance"
           // setupUI()
           loadAttendanceForSelectedDate()
            attendanceTableView.dataSource = self
            attendanceTableView.delegate   = self
            attendanceTableView.register(UINib(nibName: "AttendanceTableViewCell", bundle: nil),
                                         forCellReuseIdentifier: "AttendanceTableViewCell")
            attendanceTableView.rowHeight = 60
            students.forEach { attendanceMap[$0.uid] = .absent }
        }

        private func setupUI() {
            datePicker.datePickerMode = .date
            datePicker.maximumDate   = Date()
            datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

            selectedDate = AttendanceManager.shared.todayString
            dateLabel.text = "Date: \(selectedDate)"

            attendanceTableView.dataSource = self
            attendanceTableView.delegate   = self
            attendanceTableView.register(UINib(nibName: "AttendanceTableViewCell", bundle: nil),
                                         forCellReuseIdentifier: "AttendanceTableViewCell")
            attendanceTableView.rowHeight = 60

            // Default all to absent
            students.forEach { attendanceMap[$0.uid] = .absent }
        }

        @objc private func dateChanged() {
            selectedDate   = AttendanceManager.shared.dateString(from: datePicker.date)
            dateLabel.text = "Date: \(selectedDate)"
            loadAttendanceForSelectedDate()
        }

        private func loadAttendanceForSelectedDate() {
            AttendanceManager.shared.fetchAttendanceForDate(selectedDate,
                                                            students: students) { [weak self] map in
                guard let self = self else { return }
                // Merge fetched data — keep absent as default for unrecorded
                self.students.forEach { student in
                    self.attendanceMap[student.uid] = map[student.uid]?.status ?? .absent
                }
                self.attendanceTableView.reloadData()
            }
        }

        // MARK: - Save All Attendance
        @IBAction func saveTapped(_ sender: UIButton) {
            saveButton.isEnabled = false
            let group = DispatchGroup()
            var failed = false

            for student in students {
                let status = attendanceMap[student.uid] ?? .absent
                group.enter()
                AttendanceManager.shared.markAttendance(studentUID:  student.uid,
                                                        studentName: student.name,
                                                        status:      status,
                                                        date:        selectedDate) { result in
                    if case .failure = result { failed = true }
                    group.leave()
                }
            }

            group.notify(queue: .main) { [weak self] in
                self?.saveButton.isEnabled = true
                let title   = failed ? "Error"   : "Saved"
                let message = failed ? "Some records failed to save." : "Attendance saved for \(self?.selectedDate ?? "")."
                self?.showAlert(title, message: message)
            }
        }

        private func showAlert(_ title: String, message: String) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    // MARK: - TableView
extension AdminAttendanceViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return students.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell    = tableView.dequeueReusableCell(withIdentifier: "AttendanceTableViewCell",
                                                    for: indexPath) as! AttendanceTableViewCell
        let student = students[indexPath.row]
        let status  = attendanceMap[student.uid] ?? .absent
        
        cell.configure(name: student.name, email: student.email, status: status)
        cell.onToggle = { [weak self] newStatus in
            self?.attendanceMap[student.uid] = newStatus
        }
        return cell
    }
    
}
