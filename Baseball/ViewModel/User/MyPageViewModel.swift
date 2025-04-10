//
//  MyPageViewModel.swift
//     
//
//  Created by 곽현우 on 4/10/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class MyPageViewModel: ObservableObject {
    @Published var nickname: String = ""
    
    private let db = Firestore.firestore()

    func fetchNickname() {
        guard let user = Auth.auth().currentUser else {
            print("❌ 현재 로그인된 사용자가 없습니다.")
            return
        }

        let uid = user.uid
        print("✅ 현재 로그인된 UID: \(uid)")

        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                print("❌ Firestore 사용자 정보 가져오기 실패: \(error.localizedDescription)")
                return
            }

            if let data = snapshot?.data(),
               let id = data["id"] as? String {
                DispatchQueue.main.async {
                    self?.nickname = id
                    print("✅ 닉네임 불러오기 성공: \(id)")
                }
            } else {
                print("❌ 사용자 데이터에서 'id' 필드를 찾을 수 없음")
            }
        }
    }
}
