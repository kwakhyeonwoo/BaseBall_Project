//
//  UploadedSongsManager.swift
//     
//
//  Created by 곽현우 on 3/1/25.
//

import FirebaseFirestore
import FirebaseStorage

class UploadedSongsManager {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    func uploadVideo(title: String, videoURL: URL, uploader: String, completion: @escaping (Bool) -> Void) {
        let videoRef = storage.reference().child("uploadedVideos/\(UUID().uuidString).mov")

        videoRef.putFile(from: videoURL, metadata: nil) { _, error in
            if let error = error {
                print("🔥 동영상 업로드 실패: \(error.localizedDescription)")
                completion(false)
                return
            }

            videoRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    print("🔥 다운로드 URL 가져오기 실패")
                    completion(false)
                    return
                }

                let songData: [String: Any] = [
                    "title": title,
                    "uploader": uploader,
                    "videoURL": downloadURL.absoluteString,
                    "timestamp": FieldValue.serverTimestamp()
                ]

                self.db.collection("uploadedSongs").addDocument(data: songData) { error in
                    if let error = error {
                        print("🔥 Firestore 저장 실패: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("✅ Firestore 저장 성공")
                        completion(true)
                    }
                }
            }
        }
    }
}

