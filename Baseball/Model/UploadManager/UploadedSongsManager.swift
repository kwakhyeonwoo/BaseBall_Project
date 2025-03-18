//
//  UploadedSongsManager.swift
//     
//
//  Created by 곽현우 on 3/1/25.
//

import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import AVFoundation

class UploadedSongsManager {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()

    //업로드시 MB줄이기
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

            // ✅ 동영상 압축 실행
            self.compressVideo(inputURL: videoURL) { success, compressedVideoURL in
                guard success, let compressedVideoURL = compressedVideoURL else {
                    print("❌ 동영상 압축 실패")
                    completion(false)
                    return
                }

                // ✅ 압축된 파일로 업로드 진행
                guard let videoData = try? Data(contentsOf: compressedVideoURL) else {
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

                        // ✅ Firestore에 저장
                        self.saveSongToFirestore(title: title, videoURL: correctedURL, uploaderID: uploaderID, selectedTeam: selectedTeam, completion: completion)
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

    // MARK: Firestore에 데이터 저장 (이제 uploader는 "ID" 또는 "익명")
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
    
    //동영상 압축
    func compressVideo(inputURL: URL, completion: @escaping (Bool, URL?) -> Void) {
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(UUID().uuidString).mov") // ✅ 새로운 파일명 사용

        // ✅ 기존 파일 삭제 (덮어쓰기 방지)
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
                print("✅ 기존 압축 파일 삭제 완료: \(outputURL.path)")
            } catch {
                print("❌ 기존 파일 삭제 실패: \(error.localizedDescription)")
                completion(false, nil)
                return
            }
        }

        let asset = AVURLAsset(url: inputURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            print("❌ 동영상 압축 세션 생성 실패")
            completion(false, nil)
            return
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = true

        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("✅ 동영상 압축 완료: \(outputURL.absoluteString)")
                completion(true, outputURL)
            case .failed:
                print("❌ 동영상 압축 실패: \(exportSession.error?.localizedDescription ?? "알 수 없는 오류")")
                completion(false, nil)
            default:
                print("⚠️ 동영상 압축 진행 중...")
            }
        }
    }
}
