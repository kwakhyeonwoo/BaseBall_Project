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
        
        authenticateAndRefreshTokenIfNeeded {
            // ✅ Firestore 접근은 여기서부터!
            self.checkFirebaseProjectID()
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
    
    // MARK: - 인증 및 토큰 갱신 후 Firestore 작업
    private func authenticateAndRefreshTokenIfNeeded(completion: @escaping () -> Void) {
        if let user = Auth.auth().currentUser {
            print("✅ 현재 사용자 존재: \(user.uid)")
            refreshFirebaseToken(user: user) { success in
                if success {
                    completion()
                } else {
                    print("❌ 토큰 갱신 실패")
                }
            }
        } else {
            print("❌ 인증된 사용자 없음 → 익명 로그인 시도")
            
            Auth.auth().signInAnonymously { authResult, error in
                if let error = error {
                    print("❌ 익명 로그인 실패: \(error.localizedDescription)")
                    return
                }
                
                if let user = authResult?.user {
                    print("✅ 익명 로그인 성공: \(user.uid)")
                    self.refreshFirebaseToken(user: user) { success in
                        if success {
                            completion()
                        } else {
                            print("❌ 익명 로그인 후 토큰 갱신 실패")
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 토큰 갱신 (완료 콜백 포함)
        private func refreshFirebaseToken(user: User, completion: @escaping (Bool) -> Void) {
            user.getIDTokenForcingRefresh(true) { token, error in
                if let error = error {
                    print("❌ 토큰 갱신 실패: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ 토큰 갱신 성공")
                    completion(true)
                }
            }
        }

        // MARK: - Firebase 프로젝트 정보 확인
        func checkFirebaseProjectID() {
            if let options = FirebaseApp.app()?.options {
                print("✅ Firebase Project ID: \(options.projectID ?? "Unknown")")
                print("✅ Storage Bucket: \(options.storageBucket ?? "Unknown")")
                print("✅ API Key: \(options.apiKey ?? "Unknown")")
            } else {
                print("❌ Firebase 설정 오류")
            }
        }
}

//490200374980-e8u3racek0o44dflciovskp3d1dgdd91.apps.googleusercontent.com"
