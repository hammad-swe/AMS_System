//
//  AuthManager.swift
//  AMS_System
//
//  Created by Hammad Ali on 30/04/2026.
//
import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

final class AuthManager {

    static let shared = AuthManager()
    private init() {}

    var currentUser: FirebaseAuth.User? { Auth.auth().currentUser }

    func signUpWithEmail(email: String,
                         password: String,
                         presenting viewController: UIViewController,
                         completion: @escaping (Result<(FirebaseAuth.User, UserRole), Error>) -> Void) {

        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("❌ createUser failed: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            guard let firebaseUser = authResult?.user else {
                completion(.failure(AuthError.noFirebaseUser))
                return
            }

            print("✅ Firebase user created: \(firebaseUser.email ?? "")")

            // ← Must be assignRole (not fetchRole) for new users
            RoleManager.shared.assignRole(to: firebaseUser) { roleResult in
                switch roleResult {
                case .success(let role):
                    print("✅ Role assigned: \(role.rawValue)")
                    completion(.success((firebaseUser, role)))
                case .failure(let error):
                    print("❌ Role assign failed: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            }
        }
    }
    // MARK: - Email Sign In (existing account)
    func signInWithEmail(email: String,
                         password: String,
                         presenting viewController: UIViewController,
                         completion: @escaping (Result<(FirebaseAuth.User, UserRole), Error>) -> Void) {

        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let firebaseUser = authResult?.user else {
                completion(.failure(AuthError.noFirebaseUser))
                return
            }

            // Fetch existing role (user already in Firestore)
            RoleManager.shared.fetchRole(for: firebaseUser.uid) { roleResult in
                switch roleResult {
                case .success(let role):
                    completion(.success((firebaseUser, role)))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Google Sign In / Sign Up (handles both)
    func signInWithGoogle(presenting viewController: UIViewController,
                          completion: @escaping (Result<(FirebaseAuth.User, UserRole), Error>) -> Void) {

        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(AuthError.missingClientID))
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(.failure(AuthError.missingToken))
                return
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let firebaseUser = authResult?.user else {
                    completion(.failure(AuthError.noFirebaseUser))
                    return
                }

                // assignRole handles both: new user (assigns) and returning user (fetches)
                RoleManager.shared.assignRole(to: firebaseUser) { roleResult in
                    switch roleResult {
                    case .success(let role):
                        completion(.success((firebaseUser, role)))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: - Restore Previous Sign In
    func restorePreviousSignIn(completion: @escaping (Result<(FirebaseAuth.User, UserRole), Error>) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(.failure(AuthError.noFirebaseUser))
            return
        }

        RoleManager.shared.fetchRole(for: currentUser.uid) { result in
            switch result {
            case .success(let role):
                completion(.success((currentUser, role)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Sign Out
    func signOut(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            GIDSignIn.sharedInstance.signOut()
            try Auth.auth().signOut()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Delete Admin Account + All Students
    func deleteAdminAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(AuthError.noFirebaseUser))
            return
        }

        RoleManager.shared.deleteAdminAndAllStudents(adminUID: user.uid) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success:
                user.delete { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        GIDSignIn.sharedInstance.signOut()
                        completion(.success(()))
                    }
                }
            }
        }
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case missingClientID
    case missingToken
    case noFirebaseUser

    var errorDescription: String? {
        switch self {
        case .missingClientID: return "Firebase client ID not found."
        case .missingToken:    return "Google ID token is missing."
        case .noFirebaseUser:  return "Firebase user not returned."
        }
    }
}
