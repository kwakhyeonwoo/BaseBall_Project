//
//  SignInViewModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/2/25.
//

import SwiftUI
import Combine

class SignInViewModel: ObservableObject {
    @Published var ID: String = ""
    @Published var PW: String = ""
    @Published var isTeamSelectActive: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isLoggedIn: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    let googleAuth: GoogleAuth
    
    init(googleAuth: GoogleAuth = GoogleAuth()) {
        self.googleAuth = googleAuth
        
        googleAuth.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoggedIn in
                if isLoggedIn {
                    self?.isTeamSelectActive = true
                }
            }
            .store(in: &cancellables)
    }
    
    func signIn() {
        // ID와 PW로 로그인 처리
        if ID.isEmpty || PW.isEmpty {
            alertMessage = "아이디와 비밀번호를 입력해주세요."
            showAlert = true
            return
        }
        
        // 예시 로직: 로그인 성공 시 화면 전환
        isTeamSelectActive = true
    }
    
    func kakaoLogin() {
        KakaoAuth.shared.loginWithKakao { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let token):
//                    self.alertMessage = "카카오 로그인 성공! 토큰: \(token)"
                    self.isTeamSelectActive = true
                case .failure(let error):
                    self.alertMessage = "카카오 로그인 실패: \(error.localizedDescription)"
                }
                self.showAlert = true
            }
        }
    }
    
    func googleLogin() {
        googleAuth.signIn()
    }
    
    func logOut() {
        googleAuth.logOut()
    }
}

