//
//  SignInGoogleDemo.swift
//  AuthSample
//
//  Created by Codelaby on 8/11/24.
//

import SwiftUI
import GoogleSignIn

// Data model to store authenticated user information
struct AuthUserCredential: Identifiable, Codable {
    var id = UUID()
    var identityToken: Data?
    var user: String
    var fullName: PersonNameComponents?
    var email: String?
    var profilePicUrl: URL?
}

// ViewModel to handle Google authentication
class GoogleAuthViewModel: ObservableObject {
    
    @MainActor
    static let shared: GoogleAuthViewModel = {
        let instance = GoogleAuthViewModel()
        // setup code
        return instance
    }()

    @Published var authUser: AuthUserCredential? // Authenticated user data
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String = ""

    init() {
        getAuthorizationState()
    }

    // Get the current authorization state
    func getAuthorizationState() {
        print("👀 Checking authorization state")
        
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            print("🚦 hasPreviousSignIn")

            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    print("⚠️ Error in restorePreviousSignIn:", error.localizedDescription)
                }

                self.fetchCurrentUser()

            }

        } else {
            self.isAuthenticated = false
            print("✋ User not authorized")
        }
    }

    // Update the authenticated user data
    func fetchCurrentUser() {
        print("🙋 Fetching current user data")
        
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            print("ℹ️ User not authenticated")
            self.isAuthenticated = false
            self.authUser = nil
            return
        }

        // Google user profile data
        let identityToken = user.idToken?.tokenString.data(using: .utf8)
        let userID = user.userID ?? ""
        let email = user.profile?.email
        let profilePicUrl = user.profile?.imageURL(withDimension: 100)
        let fullName = PersonNameComponentsFormatter().personNameComponents(from: user.profile?.name ?? "")

        // Assigning the data to the authenticated user model
        self.authUser = AuthUserCredential(
            identityToken: identityToken,
            user: userID,
            fullName: fullName,
            email: email,
            profilePicUrl: profilePicUrl
        )
        
        self.isAuthenticated = true
        print("✅ Welcome, user:", user.profile?.email ?? "")
    }

    // Sign in with Google
    @MainActor
    func signInGoogle() {
        print("💫 Signing in with Google")
        
        guard let presentingViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else { return }
        
        if GIDSignIn.sharedInstance.hasPreviousSignIn() {
            self.fetchCurrentUser()
        } else {
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { user, error in
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    print("⚠️ Error:", error)
                    return
                }
                self.fetchCurrentUser()
            }
        }
    }

    // Sign out from Google
    func signOutGoogle() {
        print("👋 Signing out from Google")
        GIDSignIn.sharedInstance.signOut()
        self.isAuthenticated = false
        self.authUser = nil
    }
}

// Demo view to test Google authentication
struct SignInGoogleDemo: View {
    @StateObject private var authManager = GoogleAuthViewModel.shared
    @State private var showProfileView = false // State to show `ProfileView`

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                
                SampleTitleView(
                    title: "Google Sign-In with SwiftUI",
                    summary: "Explore and test the Google sign-in process in SwiftUI"
                )
                Spacer()
                
                if authManager.isAuthenticated {
                    Text("Welcome back, user").font(.largeTitle)
                    Text("See your account in profile")
                } else {
                    Button("Sign in with Google") {
                        authManager.signInGoogle()
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                if !authManager.errorMessage.isEmpty {
                    Text(authManager.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()

            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if authManager.isAuthenticated {
                        Button("Profile") {
                            showProfileView = true
                        }
                    }
                }
            }
            .navigationDestination(isPresented: $showProfileView) {
                GoogleProfileView() // Navigate to `ProfileView` and pass the ViewModel
            }
        }
        
        CreditsView()
    }
}


struct GoogleProfileView: View {
    @ObservedObject private var authManager: GoogleAuthViewModel = GoogleAuthViewModel.shared

    var body: some View {
        VStack(spacing: 20) {
            if let user = authManager.authUser {
                if let url = user.profilePicUrl {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } placeholder: {
                        ProgressView()
                    }
                }
                
                Text("Full Name: \(user.fullName?.formatted() ?? "Not available")")
                Text("Email: \(user.email ?? "Not available")")
            }

            Button("Log out", role: .destructive) {
                authManager.signOutGoogle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SignInGoogleDemo()
}
