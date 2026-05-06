//
//  StudentManager.swift
//  AMS_System
//
//  Created by Hammad Ali on 06/05/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class StudentManager {

    static let shared = StudentManager()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Admin Adds Student
    func addStudent(name: String,
                    email: String,
                    password: String,
                    adminUID: String,
                    completion: @escaping (Result<Void, Error>) -> Void) {

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let studentUser = authResult?.user else { return }

            let data: [String: Any] = [
                "uid":       studentUser.uid,
                "name":      name,
                "email":     email,
                "role":      "student",
                "addedBy":   adminUID,
                "createdAt": Timestamp(date: Date())
            ]

            self.db.collection("students")
                   .document(studentUser.uid)
                   .setData(data) { error in
                       if let error = error {
                           completion(.failure(error))
                       } else {
                           print("✅ Student added: \(name)")
                           completion(.success(()))
                       }
                   }
        }
    }

    // MARK: - Fetch All Students
    func fetchAllStudents(completion: @escaping (Result<[Student], Error>) -> Void) {
        db.collection("students")
          .order(by: "createdAt", descending: false)
          .getDocuments { snapshot, error in
              if let error = error {
                  completion(.failure(error))
                  return
              }

              let students = snapshot?.documents.compactMap { doc -> Student? in
                  let data = doc.data()
                  guard let uid   = data["uid"]   as? String,
                        let name  = data["name"]  as? String,
                        let email = data["email"] as? String else { return nil }

                  let addedBy   = data["addedBy"] as? String
                  let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                  return Student(uid: uid, name: name, email: email,
                                 addedBy: addedBy, createdAt: createdAt)
              } ?? []

              completion(.success(students))
          }
    }
}
