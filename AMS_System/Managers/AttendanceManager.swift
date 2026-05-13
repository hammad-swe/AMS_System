//
//  AttendanceManager.swift
//  AMS_System
//
//  Created by Hammad Ali on 06/05/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class AttendanceManager {

    static let shared = AttendanceManager()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Date Helper
    var todayString: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    func dateString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    // MARK: - Time Validation
    private var currentHour: Int {
        return Calendar.current.component(.hour, from: Date())
    }

    private func isWithinAllowedTime() -> Bool {
        // Allowed between 8AM and 7PM
        return currentHour >= 8 && currentHour < 19
    }

    private func isWithinCheckOutTime(checkInTime: Date) -> Bool {
        // Cannot check out after 7PM
        guard currentHour < 19 else { return false }

        // Cannot check out if checked in after school ends (6PM)
        let checkInHour = Calendar.current.component(.hour, from: checkInTime)
        guard checkInHour < 18 else { return false }

        return true
    }

    // MARK: - Student Check In
    func checkIn(studentUID: String,
                 studentName: String,
                 completion: @escaping (Result<Void, Error>) -> Void) {

        // Time restriction check
        guard isWithinAllowedTime() else {
            if currentHour < 8 {
                completion(.failure(AttendanceError.tooEarly))
            } else {
                completion(.failure(AttendanceError.tooLate))
            }
            return
        }

        let today = todayString
        let ref   = db.collection("attendance")
                      .document(studentUID)
                      .collection("records")
                      .document(today)

        ref.getDocument { snapshot, error in
            if let data = snapshot?.data(),
               data["checkIn"] != nil {
                completion(.failure(AttendanceError.alreadyCheckedIn))
                return
            }

            let data: [String: Any] = [
                "studentUID":  studentUID,
                "studentName": studentName,
                "date":        today,
                "status":      AttendanceStatus.present.rawValue,
                "checkIn":     Timestamp(date: Date()),
                "markedAt":    Timestamp(date: Date())
            ]

            ref.setData(data, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    print("Check-in recorded for \(studentName)")
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Student Check Out
    func checkOut(studentUID: String,
                  completion: @escaping (Result<Void, Error>) -> Void) {

        // Time restriction check
        guard isWithinAllowedTime() else {
            completion(.failure(AttendanceError.tooLate))
            return
        }

        let today = todayString
        let ref   = db.collection("attendance")
                      .document(studentUID)
                      .collection("records")
                      .document(today)

        ref.getDocument { snapshot, error in
            guard let data = snapshot?.data() else {
                completion(.failure(AttendanceError.notCheckedIn))
                return
            }

            // Must have checked in first
            guard let checkInTimestamp = data["checkIn"] as? Timestamp else {
                completion(.failure(AttendanceError.notCheckedIn))
                return
            }

            // Already checked out
            if data["checkOut"] != nil {
                completion(.failure(AttendanceError.alreadyCheckedOut))
                return
            }

            // Check if checkout window is still open
            let checkInTime = checkInTimestamp.dateValue()
            guard self.isWithinCheckOutTime(checkInTime: checkInTime) else {
                completion(.failure(AttendanceError.checkOutExpired))
                return
            }

            ref.updateData(["checkOut": Timestamp(date: Date())]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    print("Check-out recorded")
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Fetch Today's Check-In Status for Student
    func fetchTodayRecord(for studentUID: String,
                          completion: @escaping (AttendanceRecord?) -> Void) {

        db.collection("attendance")
          .document(studentUID)
          .collection("records")
          .document(todayString)
          .getDocument { snapshot, _ in
              guard let data = snapshot?.data() else {
                  completion(nil)
                  return
              }
              let record = self.parseRecord(data)
              completion(record)
          }
    }

    // MARK: - Admin Marks Attendance Manually
    func markAttendance(studentUID: String,
                        studentName: String,
                        status: AttendanceStatus,
                        date: String,
                        completion: @escaping (Result<Void, Error>) -> Void) {

        let data: [String: Any] = [
            "studentUID":  studentUID,
            "studentName": studentName,
            "date":        date,
            "status":      status.rawValue,
            "markedAt":    Timestamp(date: Date())
        ]

        db.collection("attendance")
          .document(studentUID)
          .collection("records")
          .document(date)
          .setData(data, merge: true) { error in
              if let error = error {
                  completion(.failure(error))
              } else {
                  completion(.success(()))
              }
          }
    }

    // MARK: - Fetch All Students Attendance for a Date (Admin)
    func fetchAttendanceForDate(_ date: String,
                                students: [Student],
                                completion: @escaping ([String: AttendanceRecord]) -> Void) {

        var result: [String: AttendanceRecord] = [:]
        let group = DispatchGroup()

        for student in students {
            group.enter()
            db.collection("attendance")
              .document(student.uid)
              .collection("records")
              .document(date)
              .getDocument { snapshot, _ in
                  if let data = snapshot?.data(),
                     let record = self.parseRecord(data) {
                      result[student.uid] = record
                  }
                  group.leave()
              }
        }

        group.notify(queue: .main) { completion(result) }
    }

    // MARK: - Fetch Student Attendance History
    func fetchAttendanceHistory(for studentUID: String,
                                completion: @escaping (Result<[AttendanceRecord], Error>) -> Void) {

        db.collection("attendance")
          .document(studentUID)
          .collection("records")
          .order(by: "date", descending: true)
          .getDocuments { snapshot, error in
              if let error = error {
                  completion(.failure(error))
                  return
              }

              let records = snapshot?.documents.compactMap {
                  self.parseRecord($0.data())
              } ?? []

              completion(.success(records))
          }
    }

    // MARK: - Calculate Attendance Percentage
    func calculatePercentage(records: [AttendanceRecord]) -> Double {
        guard !records.isEmpty else { return 0.0 }
        let presentCount = records.filter { $0.status == .present }.count
        return (Double(presentCount) / Double(records.count)) * 100.0
    }

    // MARK: - Parse Firestore Data → AttendanceRecord
    private func parseRecord(_ data: [String: Any]) -> AttendanceRecord? {
        guard let uid    = data["studentUID"]   as? String,
              let name   = data["studentName"]  as? String,
              let date   = data["date"]         as? String,
              let stStr  = data["status"]       as? String,
              let status = AttendanceStatus(rawValue: stStr),
              let marked = data["markedAt"]     as? Timestamp else { return nil }

        let checkIn  = (data["checkIn"]  as? Timestamp)?.dateValue()
        let checkOut = (data["checkOut"] as? Timestamp)?.dateValue()

        return AttendanceRecord(studentUID:  uid,
                                studentName: name,
                                date:        date,
                                status:      status,
                                checkIn:     checkIn,
                                checkOut:    checkOut,
                                markedAt:    marked.dateValue())
    }
    
//    // MARK: - Fetch Overall Attendance Stats (Admin)
//    func fetchOverallStats(students: [Student],
//                           completion: @escaping (Int, Int, Int) -> Void) {
//        let today = todayString
//        var present   = 0
//        var absent    = 0
//        var notMarked = 0
//        let group = DispatchGroup()
//
//        for student in students {
//            group.enter()
//            db.collection("attendance")
//              .document(student.uid)
//              .collection("records")
//              .document(today)
//              .getDocument { snapshot, _ in
//                  if let data = snapshot?.data(),
//                     let statusStr = data["status"] as? String,
//                     let status = AttendanceStatus(rawValue: statusStr) {
//                      switch status {
//                      case .present: present += 1
//                      case .absent:  absent  += 1
//                      }
//                  } else {
//                      notMarked += 1
//                  }
//                  group.leave()
//              }
//        }
//
//        group.notify(queue: .main) {
//            completion(present, absent, notMarked)
//        }
//    }
}

// MARK: - Attendance Errors
enum AttendanceError: LocalizedError {
    case alreadyCheckedIn
    case alreadyCheckedOut
    case notCheckedIn
    case tooEarly
    case tooLate
    case checkOutExpired

    var errorDescription: String? {
        switch self {
        case .alreadyCheckedIn:
            return "You have already checked in today."
        case .alreadyCheckedOut:
            return "You have already checked out today."
        case .notCheckedIn:
            return "You haven't checked in yet today."
        case .tooEarly:
            return "Check-in opens at 8:00 AM."
        case .tooLate:
            return "Check-in/out is closed after 7:00 PM."
        case .checkOutExpired:
            return "Check-out window has closed. Please contact your admin."
        }
    }
}
