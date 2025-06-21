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
        FirebaseApp.configure()

        // Google Sign-In 초기화
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")

        // 🔐 로그인 된 사용자만 토큰 갱신 및 Firestore 접근
        if let user = Auth.auth().currentUser {
            refreshFirebaseToken(user: user) { success in
                if success {
                    self.checkFirebaseProjectID()
                } else {
                    print("❌ 토큰 갱신 실패")
                }
            }
        } else {
            print("❌ 인증된 Firebase 사용자가 없습니다. 로그인 후 Firestore 접근 허용")
        }

        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Firebase 토큰 갱신
    private func refreshFirebaseToken(user: User, completion: @escaping (Bool) -> Void) {
        user.getIDTokenForcingRefresh(true) { token, error in
            if let error = error {
                print("❌ 토큰 갱신 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Firebase 토큰 갱신 성공")
                completion(true)
            }
        }
    }

    // MARK: - Firebase 프로젝트 정보 출력
    func checkFirebaseProjectID() {
        if let options = FirebaseApp.app()?.options {
            print("✅ Firebase Project ID: \(options.projectID ?? "Unknown")")
            print("✅ Storage Bucket: \(options.storageBucket ?? "Unknown")")
            print("✅ API Key: \(options.apiKey ?? "Unknown")")
        } else {
            print("❌ Firebase 설정을 찾을 수 없음")
        }
    }
}

