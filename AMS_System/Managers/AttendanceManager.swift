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

    // MARK: - Student Check In
    func checkIn(studentUID: String,
                 studentName: String,
                 completion: @escaping (Result<Void, Error>) -> Void) {

        let today = todayString
        let ref   = db.collection("attendance")
                      .document(studentUID)
                      .collection("records")
                      .document(today)

        // Check if already checked in today
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
                    print("✅ Check-in recorded for \(studentName)")
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Student Check Out
    func checkOut(studentUID: String,
                  completion: @escaping (Result<Void, Error>) -> Void) {

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

            if data["checkIn"] == nil {
                completion(.failure(AttendanceError.notCheckedIn))
                return
            }

            if data["checkOut"] != nil {
                completion(.failure(AttendanceError.alreadyCheckedOut))
                return
            }

            ref.updateData(["checkOut": Timestamp(date: Date())]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    print("✅ Check-out recorded")
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
}

// MARK: - Attendance Errors
enum AttendanceError: LocalizedError {
    case alreadyCheckedIn
    case alreadyCheckedOut
    case notCheckedIn

    var errorDescription: String? {
        switch self {
        case .alreadyCheckedIn:  return "You have already checked in today."
        case .alreadyCheckedOut: return "You have already checked out today."
        case .notCheckedIn:      return "You haven't checked in yet today."
        }
    }
}
