//
//  AppDelegate.swift
//  Baseball
//
//  Created by 곽현우 on 1/2/25.
//

import UIKit
import GoogleSignIn
import Firebase
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Google Sign-In 초기화
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "490200374980-e8u3racek0o44dflciovskp3d1dgdd91.apps.googleusercontent.com")
        
        do {
            try checkAndAuthenticateUser()
            checkFirebaseProjectID()
        } catch let error {
            print("❌ [ERROR] Authentication failed: \(error.localizedDescription)")
        }
        
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        // Google Sign-In URL 처리
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    private func checkAndAuthenticateUser() throws {
        if let user = Auth.auth().currentUser {
            print("✅ [DEBUG] Firebase User Authenticated: \(user.uid), Email: \(user.email ?? "No Email")")
            try refreshFirebaseToken(user: user)
        } else {
            print("❌ [ERROR] No authenticated Firebase user. Attempting to sign in...")
            
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("❌ [ERROR] Failed to sign in: \(error.localizedDescription)")
                } else if let user = authResult?.user {
                    print("✅ [SUCCESS] Re-authenticated: \(user.uid), Email: \(user.email ?? "No Email")")
                    do {
                        try self.refreshFirebaseToken(user: user)
                    } catch let tokenError {
                        print("❌ [ERROR] Token refresh failed: \(tokenError.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - 🔄 Token Refresh Handling
    private func refreshFirebaseToken(user: User) throws {
        user.getIDTokenForcingRefresh(true) { token, error in
            if let error = error {
                print("❌ [ERROR] Failed to refresh token: \(error.localizedDescription)")
            } else {
                print("✅ [DEBUG] Firebase Token Refreshed Successfully")
            }
        }
    }
    
    func checkFirebaseProjectID() {
        if let options = FirebaseApp.app()?.options {
            print("✅ [DEBUG] Firebase Project ID: \(options.projectID ?? "Unknown")")
            print("✅ [DEBUG] Firebase Storage Bucket: \(options.storageBucket ?? "Unknown")")
            print("✅ [DEBUG] Firebase API Key: \(options.apiKey ?? "Unknown")")
        } else {
            print("❌ [ERROR] Firebase App is not configured correctly.")
        }
    }

}

//490200374980-e8u3racek0o44dflciovskp3d1dgdd91.apps.googleusercontent.com"
