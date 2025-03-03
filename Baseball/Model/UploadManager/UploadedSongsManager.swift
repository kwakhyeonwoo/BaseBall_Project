//
//  UploadedSongsManager.swift
//     
//
//  Created by 곽현우 on 3/1/25.
//

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore

class UploadedSongsManager {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()

    func uploadVideo(title: String, videoURL: URL, selectedTeam: String, completion: @escaping (Bool) -> Void) {
        print("✅ Firebase 업로드 시작: \(videoURL.absoluteString)")

        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 로그인 정보가 없습니다. 다시 로그인해주세요.")
            completion(false)
            return
        }

        let uploaderUID = currentUser.uid  // ✅ Firebase Auth의 UID 사용
        let userEmail = currentUser.email ?? "익명"

        // ✅ Firestore에서 사용자의 ID 가져오기
        fetchUserID(uid: uploaderUID) { userID in
            var uploaderID = "익명"  // 기본값은 "익명"

            // ✅ Firestore에서 ID를 가져왔을 경우, ID가 존재하면 사용
            if let fetchedID = userID, !fetchedID.isEmpty {
                uploaderID = fetchedID
            }

            // ✅ Firebase Auth에서 제공하는 email이 Google/Kakao 이메일이라면 무조건 "익명" 처리
            if self.isSocialLogin(email: userEmail) {
                uploaderID = "익명"
            }

            print("✅ Firestore에서 가져온 사용자 ID (또는 익명): \(uploaderID)")

            // ✅ 앱 내부 tmp 경로의 파일을 Firebase Storage로 업로드
            guard let videoData = try? Data(contentsOf: videoURL) else {
                print("❌ 비디오 데이터를 가져올 수 없습니다.")
                completion(false)
                return
            }

            let storageRef = self.storage.reference().child("uploadedVideos/\(UUID().uuidString).mov")

            storageRef.putData(videoData, metadata: nil) { metadata, error in
                if let error = error {
                    print("❌ Firebase Storage 업로드 실패: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                // ✅ Firebase Storage URL 가져오기
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("❌ Firebase Storage URL 가져오기 실패: \(error.localizedDescription)")
                        completion(false)
                        return
                    }

                    guard let downloadURL = url?.absoluteString else {
                        print("❌ Firebase Storage URL이 nil입니다.")
                        completion(false)
                        return
                    }

                    print("✅ Firebase Storage 업로드 성공: \(downloadURL)")

                    // ✅ Firestore에 저장 (사용자의 ID 또는 익명 저장)
                    self.saveSongToFirestore(title: title, videoURL: downloadURL, uploaderID: uploaderID, selectedTeam: selectedTeam, completion: completion)
                }
            }
        }
    }

    // ✅ Firestore에서 사용자 ID 가져오는 함수
    private func fetchUserID(uid: String, completion: @escaping (String?) -> Void) {
        db.collection("users").document(uid).getDocument { document, error in
            if let document = document, document.exists {
                let userID = document.data()?["id"] as? String
                completion(userID)
            } else {
                completion(nil) // Firestore에서 ID를 찾을 수 없을 경우
            }
        }
    }

    // ✅ Firebase Auth의 Email을 기반으로 구글/카카오 로그인 여부 확인
    private func isSocialLogin(email: String) -> Bool {
        return email.contains("@gmail.com") || email.contains("@kakao.com")
    }

    // ✅ Firestore에 데이터 저장 (이제 uploader는 "ID" 또는 "익명")
    private func saveSongToFirestore(title: String, videoURL: String, uploaderID: String, selectedTeam: String, completion: @escaping (Bool) -> Void) {
        let newSong: [String: Any] = [
            "title": title,
            "uploader": uploaderID,  // ✅ 이제 uploader는 Firestore의 ID 또는 "익명"
            "videoURL": videoURL,
            "team": selectedTeam,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("uploadedSongs").addDocument(data: newSong) { error in
            if let error = error {
                print("❌ Firestore 업로드 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Firestore 업로드 성공: \(title) - 업로더: \(uploaderID)")
                completion(true)
            }
        }
    }
}
