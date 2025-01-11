//
//  GoogleAuth.swift
//  Baseball
//
//  Created by 곽현우 on 12/30/24.
//

import Foundation
import GoogleSignIn
import GoogleSignInSwift

class GoogleAuth: ObservableObject {
    static let shared = GoogleAuth()
    
    @Published var isSignedIn: Bool = false // 로그인 상태 확인
    @Published var userName: String? = nil // 사용자 이름
    @Published var userEmail: String? = nil // 사용자 이메일
    @Published var isLoggedIn: Bool = false // 로그인 상태 추적

    // MARK: - Google 로그인 처리
    func signIn() {
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("Error: Unable to access rootViewController")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: getRootViewController()) {[weak self] signInResult, error in
            if let error = error {
                print("Google Sign-In failed: \(error.localizedDescription)")
                return
            }
            
            guard let result = signInResult else {
                print("Google Sign-In failed: No result")
                return
            }
            
            // 로그인 성공 시 사용자 정보 가져오기
            let user = result.user
            self?.userName = user.profile?.name
            self?.userEmail = user.profile?.email
            self?.isSignedIn = true

            print("Google Sign-In successful:")
            print("Name: \(user.profile?.name ?? "N/A")")
            print("Email: \(user.profile?.email ?? "N/A")")
            
            DispatchQueue.main.async {
                self?.isLoggedIn = true
            }
        }
    }

    // MARK: - Google 로그아웃 처리
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        self.isSignedIn = false
        self.userName = nil
        self.userEmail = nil
        print("Google Sign-Out successful")
    }
    
    // 현재 최상위 뷰 컨트롤러 반환 (Google SDK에서 요구)
    private func getRootViewController() -> UIViewController {
        let rootVC = UIApplication.shared.windows.first?.rootViewController
        return rootVC ?? UIViewController()
    }
    
    func logOut() {
        GIDSignIn.sharedInstance.signOut()  // 구글 로그아웃
        DispatchQueue.main.async {
            self.isLoggedIn = false
        }
    }
    
    
}
