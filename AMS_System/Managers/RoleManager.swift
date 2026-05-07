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
               .getDocuments { snapshot, error in
                   if let error = error {
                       print("adminExists BLOCKED: \(error.localizedDescription)")
                       completion(false)
                       return
                   }
                   let count = snapshot?.documents.count ?? 0
                   print("Admin docs found: \(count)")
                   completion(count > 0)
               }
    }

    
    func saveUser(_ user: AppUser, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "uid":       user.uid,
            "name":      user.name,
            "email":     user.email,
            "role":      user.role.rawValue,
            "createdAt": Timestamp(date: user.createdAt)
        ]

        print("💾 Saving to collection: '\(user.collection)' | uid: \(user.uid) | role: \(user.role.rawValue)")

        db.collection(user.collection)
            .document(user.uid)
            .setData(data) { error in
                if let error = error {
                    print("SAVE FAILED: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("SAVE SUCCESS → '\(user.collection)'")
                    completion(.success(()))
                }
            }
    }

    // MARK: - Fetch Role of Signed-In User
    func fetchRole(for uid: String, completion: @escaping (Result<UserRole, Error>) -> Void) {

        print("🔍 Fetching role for uid: \(uid)")

        // Check admin collection first
        db.collection("admin").document(uid).getDocument { snapshot, error in

            if let error = error {
                print("Error checking admin collection: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let data = snapshot?.data(),
               let roleStr = data["role"] as? String,
               let role = UserRole(rawValue: roleStr) {
                print("Found in admin collection → role: \(role.rawValue)")
                completion(.success(role))
                return
            }

            print("Not found in admin, checking students collection...")

            // Check students collection
            self.db.collection("students").document(uid).getDocument { snapshot, error in
                if let error = error {
                    print("Error checking students collection: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }

                guard let data = snapshot?.data(),
                      let roleStr = data["role"] as? String,
                      let role = UserRole(rawValue: roleStr) else {
                    print("Not found in students either → new user")
                    completion(.failure(RoleError.roleNotFound))
                    return
                }

                print("Found in students collection → role: \(role.rawValue)")
                completion(.success(role))
            }
        }
    }

    // MARK: - Assign Role on First Sign-In
    func assignRole(to firebaseUser: FirebaseAuth.User,
                    completion: @escaping (Result<UserRole, Error>) -> Void) {

        let email = firebaseUser.email ?? "unknown"
        print("🚀 assignRole called for: \(email)")

        // First check if user already exists in either collection
        fetchRole(for: firebaseUser.uid) { result in
            switch result {
            case .success(let role):
                // Returning user — role already assigned
                print("Returning user → role: \(role.rawValue)")
                completion(.success(role))

            case .failure:
                // New user — check if admin slot is taken
                print("New user detected, checking adminExists...")

                self.adminExists { adminExists in
                    let role: UserRole = adminExists ? .student : .admin
                    print("Assigning role: '\(role.rawValue)' to \(email)")

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
                            print("Role '\(role.rawValue)' assigned and saved successfully")
                            completion(.success(role))
                        case .failure(let error):
                            print("Failed to save role: \(error.localizedDescription)")
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

        print("🗑️ Deleting admin (\(adminUID)) and all students...")

        // Step 1: Fetch all students
        db.collection("students").getDocuments { snapshot, error in
            if let error = error {
                print("Failed to fetch students: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            let batch = self.db.batch()
            let studentCount = snapshot?.documents.count ?? 0
            print("👥 Deleting \(studentCount) student(s)...")

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
                    print("Batch delete failed: \(error.localizedDescription)")
                    completion(.failure(error))
                } else {
                    print("Admin and \(studentCount) student(s) deleted successfully")
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Fetch All Students (Admin use)
    func fetchAllStudents(completion: @escaping (Result<[[String: Any]], Error>) -> Void) {
        print("📋 Fetching all students...")

        db.collection("students").getDocuments { snapshot, error in
            if let error = error {
                print("Failed to fetch students: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            let students = snapshot?.documents.map { $0.data() } ?? []
            print("Fetched \(students.count) student(s)")
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
