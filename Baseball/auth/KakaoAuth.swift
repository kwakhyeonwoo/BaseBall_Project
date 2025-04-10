//
//  KakaoAuth.swift
//  Baseball
//
//  Created by 곽현우 on 12/30/24.
//

import Foundation
import KakaoSDKAuth
import KakaoSDKUser

class KakaoAuth {
    static let shared = KakaoAuth()
    
    private init() {}
    
    // MARK: 카카오 로그인 실행
    func loginWithKakao(completion: @escaping (Result<String, Error>) -> Void) {
        if UserApi.isKakaoTalkLoginAvailable() {
            // 카카오톡 앱으로 로그인
            UserApi.shared.loginWithKakaoTalk { (oauthToken, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let token = oauthToken {
                    print("카카오톡으로 로그인 성공: \(token.accessToken)")
                    completion(.success(token.accessToken))
                }
            }
        } else {
            // 카카오 계정으로 로그인 (웹뷰)
            UserApi.shared.loginWithKakaoAccount { (oauthToken, error) in
                if let error = error {
                    completion(.failure(error))
                } else if let token = oauthToken {
                    print("카카오 계정으로 로그인 성공: \(token.accessToken)")
                    completion(.success(token.accessToken))
                }
            }
        }
    }
    
    // MARK: 로그아웃
    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        UserApi.shared.logout { (error) in
            if let error = error {
                completion(.failure(error))
            } else {
                print("카카오 로그아웃 성공")
                completion(.success(()))
            }
        }
    }
    
    // MARK: 사용자 정보 가져오기
    func fetchUserInfo(completion: @escaping (Result<[String: Any], Error>) -> Void) {
        UserApi.shared.me { (user, error) in
            if let error = error {
                completion(.failure(error))
            } else if let user = user {
                var userInfo: [String: Any] = [:]
                userInfo["id"] = user.id
                userInfo["email"] = user.kakaoAccount?.email
                print("사용자 정보 가져오기 성공: \(userInfo)")
                completion(.success(userInfo))
            }
        }
    }
}
