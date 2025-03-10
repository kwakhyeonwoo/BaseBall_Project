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

        let uploaderUID = currentUser.uid
        let userEmail = currentUser.email ?? "익명"

        fetchUserID(uid: uploaderUID) { userID in
            var uploaderID = userID ?? "익명"

            if self.isSocialLogin(email: userEmail) {
                uploaderID = "익명"
            }

            print("✅ Firestore에서 가져온 사용자 ID (또는 익명): \(uploaderID)")

            guard let videoData = try? Data(contentsOf: videoURL) else {
                print("❌ 비디오 데이터를 가져올 수 없습니다.")
                completion(false)
                return
            }

            let fileName = "\(UUID().uuidString).mov"
            let storageRef = self.storage.reference().child("uploadedVideos/\(fileName)")

            storageRef.putData(videoData, metadata: nil) { metadata, error in
                if let error = error {
                    print("❌ Firebase Storage 업로드 실패: \(error.localizedDescription)")
                    completion(false)
                    return
                }

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

                    // ✅ URL에서 :443 제거
                    let correctedURL = downloadURL.replacingOccurrences(of: ":443", with: "")

                    // ✅ 퍼센트 인코딩 문제 해결: %252F → %2F 복구
                    if let fixedURL = correctedURL.removingPercentEncoding {
                        print("✅ 최종 Firestore에 저장될 Firebase Storage URL: \(fixedURL)")

                        self.saveSongToFirestore(title: title, videoURL: fixedURL, uploaderID: uploaderID, selectedTeam: selectedTeam, completion: completion)
                    } else {
                        print("❌ URL 디코딩 실패")
                        completion(false)
                    }
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
