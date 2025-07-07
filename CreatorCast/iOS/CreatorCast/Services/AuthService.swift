import Foundation
import Firebase
import AuthenticationServices
import Combine

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authError: Error?
    @Published var connectedAccounts: [SocialMediaAccount] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.isAuthenticated = user != nil
                if let user = user {
                    self?.loadUserData(uid: user.uid)
                } else {
                    self?.currentUser = nil
                }
            }
        }
    }
    
    // MARK: - Email Authentication
    
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error
                    completion(false)
                } else {
                    self?.authError = nil
                    completion(true)
                }
            }
        }
    }
    
    func signUp(email: String, password: String, fullName: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.authError = error
                    completion(false)
                } else if let user = result?.user {
                    // Create user profile
                    let newUser = User(
                        id: user.uid,
                        email: email,
                        fullName: fullName
                    )
                    
                    self?.saveUserData(user: newUser) { success in
                        completion(success)
                    }
                } else {
                    completion(false)
                }
            }
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            connectedAccounts = []
        } catch {
            authError = error
        }
    }
    
    // MARK: - Apple Sign In
    
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = generateNonce() else {
                    authError = AuthError.invalidNonce
                    return
                }
                
                guard let appleIDToken = appleIDCredential.identityToken,
                      let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    authError = AuthError.invalidToken
                    return
                }
                
                let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                          idToken: idTokenString,
                                                          rawNonce: nonce)
                
                Auth.auth().signIn(with: credential) { [weak self] result, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            self?.authError = error
                        } else if let user = result?.user {
                            // Create or update user profile
                            let fullName = "\(appleIDCredential.fullName?.givenName ?? "") \(appleIDCredential.fullName?.familyName ?? "")".trimmingCharacters(in: .whitespaces)
                            
                            let newUser = User(
                                id: user.uid,
                                email: user.email ?? "",
                                fullName: fullName.isEmpty ? "Apple User" : fullName
                            )
                            
                            self?.saveUserData(user: newUser) { _ in }
                        }
                    }
                }
            }
        case .failure(let error):
            authError = error
        }
    }
    
    // MARK: - User Data Management
    
    private func loadUserData(uid: String) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                if let document = document, document.exists,
                   let data = document.data(),
                   let userData = try? JSONSerialization.data(withJSONObject: data),
                   let user = try? JSONDecoder().decode(User.self, from: userData) {
                    self?.currentUser = user
                    self?.loadConnectedAccounts()
                } else {
                    // Create new user if doesn't exist
                    if let currentUser = Auth.auth().currentUser {
                        let newUser = User(
                            id: currentUser.uid,
                            email: currentUser.email ?? "",
                            fullName: currentUser.displayName ?? "User"
                        )
                        self?.saveUserData(user: newUser) { _ in }
                    }
                }
            }
        }
    }
    
    private func saveUserData(user: User, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        
        do {
            let userData = try JSONEncoder().encode(user)
            let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any] ?? [:]
            
            db.collection("users").document(user.id).setData(userDict) { [weak self] error in
                DispatchQueue.main.async {
                    if error == nil {
                        self?.currentUser = user
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
        } catch {
            completion(false)
        }
    }
    
    // MARK: - Social Media Connections
    
    func connectSocialAccount(platform: Platform, completion: @escaping (Bool) -> Void) {
        // This will be implemented with OAuth flows for each platform
        // For now, just a placeholder
        print("Connecting to \(platform.displayName)")
        completion(true)
    }
    
    func disconnectSocialAccount(platform: Platform, completion: @escaping (Bool) -> Void) {
        connectedAccounts.removeAll { $0.platform == platform }
        completion(true)
    }
    
    private func loadConnectedAccounts() {
        guard let userId = currentUser?.id else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).collection("connected_accounts").getDocuments { [weak self] querySnapshot, error in
            DispatchQueue.main.async {
                if let documents = querySnapshot?.documents {
                    self?.connectedAccounts = documents.compactMap { document in
                        let data = document.data()
                        return try? JSONSerialization.data(withJSONObject: data).flatMap {
                            try JSONDecoder().decode(SocialMediaAccount.self, from: $0)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Utilities
    
    private func generateNonce() -> String? {
        // Generate a random nonce for Apple Sign In
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = 32
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
}

enum AuthError: Error {
    case invalidNonce
    case invalidToken
    case userNotFound
    
    var localizedDescription: String {
        switch self {
        case .invalidNonce:
            return "Invalid nonce"
        case .invalidToken:
            return "Invalid token"
        case .userNotFound:
            return "User not found"
        }
    }
}