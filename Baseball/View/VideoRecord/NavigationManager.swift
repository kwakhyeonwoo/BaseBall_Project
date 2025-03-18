////
////  NavigationManager.swift
////     
////
////  Created by 곽현우 on 3/12/25.
////
//
//import SwiftUI
//
//class NavigationManager: ObservableObject {
//    @Published var navigationPath = NavigationPath() // ✅ 네비게이션 스택 관리
//
//    func popToRoot() {
//        DispatchQueue.main.async {
//            self.navigationPath = NavigationPath() // ✅ 네비게이션 스택을 완전히 초기화
//        }
//    }
//}
