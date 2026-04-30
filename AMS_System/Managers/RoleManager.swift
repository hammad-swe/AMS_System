//
//  RoleManager.swift
//  AMS_System
//
//  Created by Hammad Ali on 30/04/2026.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

final class RoleManager {

    static let shared = RoleManager()
    private let db = Firestore.firestore()
    private init() {}

    // MARK: - Check if Admin Already Exists
    func adminExists(completion: @escaping (Bool) -> Void) {
        db.collection("admin")
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                completion(!(snapshot?.documents.isEmpty ?? true))
            }
    }

    // MARK: - Save User with Role
    func saveUser(_ user: AppUser, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "uid":       user.uid,
            "name":      user.name,
            "email":     user.email,
            "role":      user.role.rawValue,
            "createdAt": Timestamp(date: user.createdAt)
        ]

        db.collection(user.collection)
            .document(user.uid)
            .setData(data) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
    }

    // MARK: - Fetch Role of Signed-In User
    func fetchRole(for uid: String, completion: @escaping (Result<UserRole, Error>) -> Void) {
        // Check admin collection first
        db.collection("admin").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data(),
               let roleStr = data["role"] as? String,
               let role = UserRole(rawValue: roleStr) {
                completion(.success(role))
                return
            }

            // Check students collection
            self.db.collection("students").document(uid).getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = snapshot?.data(),
                      let roleStr = data["role"] as? String,
                      let role = UserRole(rawValue: roleStr) else {
                    completion(.failure(RoleError.roleNotFound))
                    return
                }

                completion(.success(role))
            }
        }
    }

    // MARK: - Assign Role on First Sign-In
    func assignRole(to firebaseUser: FirebaseAuth.User,
                    completion: @escaping (Result<UserRole, Error>) -> Void) {

        // First check if user already exists in either collection
        fetchRole(for: firebaseUser.uid) { result in
            switch result {
            case .success(let role):
                // Returning user — role already assigned
                completion(.success(role))

            case .failure:
                // New user — decide role
                self.adminExists { adminExists in
                    let role: UserRole = adminExists ? .student : .admin
                    let appUser = AppUser(
                        uid:       firebaseUser.uid,
                        name:      firebaseUser.displayName ?? "Unknown",
                        email:     firebaseUser.email ?? "",
                        role:      role,
                        createdAt: Date()
                    )

                    self.saveUser(appUser) { saveResult in
                        switch saveResult {
                        case .success:
                            completion(.success(role))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Admin Deletes Account + All Students
    func deleteAdminAndAllStudents(adminUID: String,
                                   completion: @escaping (Result<Void, Error>) -> Void) {

        // Step 1: Fetch all students
        db.collection("students").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let batch = self.db.batch()

            // Step 2: Delete all student docs in batch
            snapshot?.documents.forEach { doc in
                batch.deleteDocument(doc.reference)
            }

            // Step 3: Delete admin doc
            let adminRef = self.db.collection("admin").document(adminUID)
            batch.deleteDocument(adminRef)

            // Step 4: Commit batch
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Fetch All Students (Admin use)
    func fetchAllStudents(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        db.collection("students").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let students = snapshot?.documents.map { $0.data() } ?? []
            completion(.success(students))
        }
    }
}

// MARK: - Role Errors
enum RoleError: LocalizedError {
    case roleNotFound

    var errorDescription: String? {
        return "User role not found in database."
    }
}
