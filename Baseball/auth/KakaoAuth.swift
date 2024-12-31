//
//  KakaoAuth.swift
//  Baseball
//
//  Created by 곽현우 on 12/30/24.
//

import Foundation

// iOS SDK
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser
import UIKit
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.handleOpenUrl(url: url)
        }

        return false
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }
}

func kakaoLogninWithApp(){
    UserApi.shared.loginWithKakaoTalk {(OAuthToken, error) in
        if let error = error{
            print (error)
        }
        else {
            print("loginWithKakaotalk() success")
            _ = OAuthToken
        }
    }
}

func kakaoLoginWithAccount(){
    UserApi.shared.loginWithKakaoAccount {(OAuthToken, error) in
        if let error = error{
            print (error)
        }
        else {
            print("loginWithKakaotalk() success")
            _ = OAuthToken
        }
    }
}

func KakaoLogin() {
    // 카카오톡 실행 가능 여부 확인
    if (UserApi.isKakaoTalkLoginAvailable()) {
        // 카카오톡 앱으로 로그인 인증
        kakaoLogninWithApp()
    } else { // 카톡이 설치가 안 되어 있을 때
        // 카카오 계정으로 로그인
        kakaoLoginWithAccount()
    }
}

func kakaoLogout() {
    UserApi.shared.logout {(error) in
        if let error = error {
            print(error)
        }
        else {
            print("logout() success.")
        }
    }
}

func kakaoUnlink() {
    UserApi.shared.unlink {(error) in
        if let error = error {
            print(error)
        }
        else {
            print("unlink() success.")
        }
    }
}

func getUserInfo() {
    UserApi.shared.me() {(user, error) in
        if let error = error {
            print(error)
        }
        else {
            print("me() success.")
            
            //do something
            let userName = user?.kakaoAccount?.name
            let userEmail = user?.kakaoAccount?.email
            let userProfile = user?.kakaoAccount?.profile?.profileImageUrl
            
            print("이름: \(String(describing: userName))")
            print("이메일: \(String(describing: userEmail))")
            print("프로필: \(String(describing: userProfile))")
        }
    }
}
