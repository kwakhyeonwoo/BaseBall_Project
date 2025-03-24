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
import ffmpegkit

class UploadedSongsManager {
    private let storage = Storage.storage()
    private let db = Firestore.firestore()

    //업로드시 MB줄이기
    func processAndUploadVideo(title: String, videoURL: URL, selectedTeam: String, uploader: String, completion: @escaping (Bool) -> Void) {
        convertToMP4(inputURL: videoURL) { success, hlsDirectory in
            guard success, let hlsDirectory = hlsDirectory else {
                completion(false)
                return
            }

            self.uploadHLSToFirebase(hlsDirectory: hlsDirectory) { success, hlsURL in
                guard success, let hlsURL = hlsURL else {
                    completion(false)
                    return
                }

                self.saveHLSToFirestore(title: title, hlsURL: hlsURL, selectedTeam: selectedTeam, uploader: uploader, completion: completion)
            }
        }
    }

    //mp4로 변경
    func convertToMP4(inputURL: URL, completion: @escaping (Bool, URL?) -> Void) {
        let asset = AVURLAsset(url: inputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            print("❌ MP4 변환 세션 생성 실패")
            completion(false, nil)
            return
        }
        
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(UUID().uuidString).mp4")
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously {
            switch exportSession.status {
            case .completed:
                print("✅ MP4 변환 완료: \(outputURL.absoluteString)")
                completion(true, outputURL)
            case .failed:
                print("❌ MP4 변환 실패: \(exportSession.error?.localizedDescription ?? "알 수 없는 오류")")
                completion(false, nil)
            default:
                print("⚠️ MP4 변환 진행 중...")
            }
        }
    }
    
    // ✅ FFmpegKit을 사용하여 MP4를 HLS로 변환하는 함수
    func convertMP4ToHLS(mp4URL: URL, completion: @escaping (Bool, URL?) -> Void) {
        let hlsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HLS_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: hlsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("❌ HLS 저장 디렉토리 생성 실패: \(error.localizedDescription)")
            completion(false, nil)
            return
        }
        
        let hlsOutputURL = hlsDirectory.appendingPathComponent("playlist.m3u8")
        
        let command = """
        -i \(mp4URL.path) -codec copy -start_number 0 -hls_time 10 -hls_list_size 0 -hls_segment_filename \(hlsDirectory.path)/segment_%03d.ts -f hls \(hlsOutputURL.path)
        """


        FFmpegKit.executeAsync(command) { session in
            if let session = session, let returnCode = session.getReturnCode(), returnCode.isValueSuccess() {
                print("✅ HLS 변환 성공: \(hlsOutputURL.absoluteString)")

                // ✅ 1️⃣ 추가적인 파일 생성 시간을 확보하기 위해 2초 대기 후 검증 실행
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.verifyHLSFiles(hlsDirectory: hlsDirectory) { success in
                        if success {
                            print("✅ 변환된 HLS 파일이 정상적으로 존재함")
                            completion(true, hlsDirectory) // ✅ 반환값을 디렉토리로 수정
                        } else {
                            print("❌ HLS 변환 후 일부 파일 누락됨")
                            completion(false, nil)
                        }
                    }
                }
            } else {
                print("❌ HLS 변환 실패")
                completion(false, nil)
            }
        }
    }

    // ✅ MP4 → HLS 변환하는 최종 함수
    func convertToHLS(inputURL: URL, completion: @escaping (Bool, URL?) -> Void) {
        convertToMP4(inputURL: inputURL) { success, mp4URL in
            guard success, let mp4URL = mp4URL else {
                completion(false, nil)
                return
            }
            
            self.convertMP4ToHLS(mp4URL: mp4URL) { success, hlsURL in
                completion(success, hlsURL)
            }
        }
    }
    // ✅ 변환된 HLS 파일이 실제로 존재하는지 확인하는 함수 (추가)
    func verifyHLSFiles(hlsDirectory: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 2.0) { // ✅ 2초 대기 후 확인
            let playlistPath = hlsDirectory.appendingPathComponent("playlist.m3u8")
            
            if FileManager.default.fileExists(atPath: playlistPath.path) {
                do {
                    let fileHandle = try FileHandle(forReadingFrom: playlistPath)
                    fileHandle.closeFile()
                    print("✅ 'playlist.m3u8' 파일이 정상적으로 열림.")
                    completion(true)
                } catch {
                    print("❌ 'playlist.m3u8' 파일을 열 수 없음: \(error.localizedDescription)")
                    completion(false)
                }
            } else {
                print("❌ 'playlist.m3u8' 파일이 존재하지 않음. HLS 폴더 내용: \(try? FileManager.default.contentsOfDirectory(atPath: hlsDirectory.path))")
                completion(false)
            }
        }
    }

    // ✅ 변환된 HLS 파일들을 Firebase Storage에 업로드하는 함수
    func uploadHLSToFirebase(hlsDirectory: URL, completion: @escaping (Bool, String?) -> Void) {
        verifyHLSFiles(hlsDirectory: hlsDirectory) { isReady in
            guard isReady else {
                print("❌ HLS 파일이 아직 접근 불가능. 업로드 취소.")
                completion(false, nil)
                return
            }

            let storageRef = Storage.storage().reference().child("hlsVideos")
            let uuid = UUID().uuidString
            let m3u8FileName = "\(uuid).m3u8"
            var finalHLSURL: String?

            do {
                let fileURLs = try FileManager.default.contentsOfDirectory(at: hlsDirectory, includingPropertiesForKeys: nil)
                    .filter { $0.pathExtension == "ts" || $0.pathExtension == "m3u8" } // ✅ Only upload .ts and .m3u8 files

                print("📂 Firebase 업로드할 파일 목록: \(fileURLs.map { $0.lastPathComponent })")

                let dispatchGroup = DispatchGroup()

                for fileURL in fileURLs {
                    if FileManager.default.fileExists(atPath: fileURL.path) {
                        let fileName = fileURL.lastPathComponent == "playlist.m3u8" ? m3u8FileName : fileURL.lastPathComponent // ✅ Rename .m3u8 file
                        let fileRef = storageRef.child(fileName) // ✅ Upload directly to `hlsVideos/`

                        dispatchGroup.enter()
                        fileRef.putFile(from: fileURL, metadata: nil) { metadata, error in
                            if let error = error {
                                print("❌ Firebase 업로드 실패 (\(fileURL.lastPathComponent)): \(error.localizedDescription)")
                            } else {
                                let uploadedPath = fileRef.fullPath
                                print("✅ Firebase 업로드 성공: \(uploadedPath)")

                                if fileName == m3u8FileName {
                                    finalHLSURL = uploadedPath // ✅ Store correct HLS URL
                                }
                            }
                            dispatchGroup.leave()
                        }
                    } else {
                        print("❌ 파일이 존재하지 않음: \(fileURL.lastPathComponent)")
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    guard let masterPlaylist = finalHLSURL else {
                        print("❌ 마스터 플레이리스트(.m3u8) 업로드 실패")
                        completion(false, nil)
                        return
                    }

                    // ✅ Retrieve correct download URL
                    storageRef.child(m3u8FileName).downloadURL { url, error in
                        if let error = error {
                            print("❌ Firebase Storage URL 가져오기 실패: \(error.localizedDescription)")
                            completion(false, nil)
                        } else if let downloadURL = url?.absoluteString {
                            let correctedURL = downloadURL.replacingOccurrences(of: ":443", with: "") // ✅ Remove :443
                            print("✅ Firestore에 저장할 HLS URL (Fixed): \(correctedURL)")
                            completion(true, correctedURL)
                        }
                    }
                }
            } catch {
                print("❌ HLS 디렉토리 내용을 가져올 수 없습니다: \(error.localizedDescription)")
                completion(false, nil)
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
    func saveHLSToFirestore(title: String, hlsURL: String, selectedTeam: String, uploader: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let newSong: [String: Any] = [
            "title": title,
            "uploader": uploader,
            "videoURL": hlsURL, // ✅ Firestore에 저장하는 것은 HLS URL
            "team": selectedTeam,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("uploadedSongs").addDocument(data: newSong) { error in
            if let error = error {
                print("❌ Firestore 업로드 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Firestore 업로드 성공: \(title) - \(hlsURL)")
                completion(true)
            }
        }
    }
}
