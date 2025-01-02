//
//  GoogleAuthModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/2/25.
//

import Foundation

// 로그인 관련 정보를 관리하는 모델
class GoogleAuthModel: ObservableObject {
    @Published var isSignedIn: Bool = false        // 로그인 상태 확인
    @Published var userName: String? = nil         // 사용자 이름
    @Published var userEmail: String? = nil        // 사용자 이메일
    @Published var isLoggedIn: Bool = false        // 로그인 상태 추적
}

