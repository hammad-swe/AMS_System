//
//  StudentAttendanceViewController.swift
//  AMS_System
//
//  Created by Hammad Ali on 06/05/2026.
//

import UIKit
import FirebaseAuth

class StudentAttendanceViewController: UIViewController {
    
    var user: FirebaseAuth.User?
    //MARk: IB OULTETS
    
    @IBOutlet weak var presentLabel: UILabel!
    
    @IBOutlet weak var absentLabel: UILabel!
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var attendanceTableView: UITableView!
    
    var studentUID: String?
        var studentName: String = "Student"
    private var records: [AttendanceRecord] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "\(studentName)'s Attendance"
        
        attendanceTableView.dataSource = self
                attendanceTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
                attendanceTableView.rowHeight = 60
        // Do any additional setup after loading the view.
        loadHistory()
    }


    private func loadHistory() {
            guard let uid = studentUID else { return }

            AttendanceManager.shared.fetchAttendanceHistory(for: uid) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let records):
                        self?.records = records
                        self?.updateStats(records: records)
                        self?.attendanceTableView.reloadData()
                    case .failure(let error):
                        print("❌ \(error.localizedDescription)")
                    }
                }
            }
        }
    
    
    private func updateStats(records: [AttendanceRecord]) {
        let total      = records.count
        let present    = records.filter { $0.status == .present }.count
        let absent     = total - present
        let percentage = AttendanceManager.shared.calculatePercentage(records: records)

        percentageLabel.text   = String(format: "%.1f%%", percentage)
        presentLabel.text = "Present: \(present)"
        absentLabel.text  = "Absent: \(absent)"
//        progressView.progress  = Float(percentage / 100.0)
//
//        progressView.progressTintColor = percentage >= 75 ? .systemGreen :
//                                         percentage >= 50 ? .systemOrange : .systemRed
    }

}

extension StudentAttendanceViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell   = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let record = records[indexPath.row]

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "hh:mm a"

        var detail = record.status.rawValue.capitalized
        if let checkIn  = record.checkIn  { detail += " | In: \(timeFormatter.string(from: checkIn))" }
        if let checkOut = record.checkOut { detail += " | Out: \(timeFormatter.string(from: checkOut))" }
        if let duration = record.durationMinutes { detail += " (\(duration) min)" }

        cell.textLabel?.text       = record.date
        cell.detailTextLabel?.text = detail
        cell.detailTextLabel?.textColor = record.status == .present ? .systemGreen : .systemRed

        return cell
    }
}
