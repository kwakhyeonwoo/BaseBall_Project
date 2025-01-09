//
//  AppDelegate.swift
//  Baseball
//
//  Created by 곽현우 on 1/2/25.
//

import UIKit
import GoogleSignIn
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase 초기화
        FirebaseApp.configure()
        
        // Google Sign-In 초기화
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "490200374980-e8u3racek0o44dflciovskp3d1dgdd91.apps.googleusercontent.com")
        
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
}

//490200374980-e8u3racek0o44dflciovskp3d1dgdd91.apps.googleusercontent.com"
