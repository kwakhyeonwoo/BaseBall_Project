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

    // MARK: - Main Upload Entry
    func processAndUploadVideo(title: String, videoURL: URL, selectedTeam: String, uploader: String, completion: @escaping (Bool) -> Void) {
        convertToHLS(inputURL: videoURL) { success, hlsDirectory in
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

    // MARK: - MP4 Compression
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

    // MARK: - HLS Convert Entry
    func convertToHLS(inputURL: URL, completion: @escaping (Bool, URL?) -> Void) {
        convertToMP4(inputURL: inputURL) { success, mp4URL in
            guard success, let mp4URL = mp4URL else {
                completion(false, nil)
                return
            }

            self.convertMP4ToHLS(mp4URL: mp4URL) { success, hlsURL, _ in
                completion(success, hlsURL)
            }
        }
    }

    // MARK: - FFmpeg HLS 변환 및 .m3u8 절대경로 처리
    func convertMP4ToHLS(mp4URL: URL, completion: @escaping (Bool, URL?, String?) -> Void) {
        let uuid = UUID().uuidString
        let hlsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("HLS_\(uuid)")

        do {
            try FileManager.default.createDirectory(at: hlsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("❌ HLS 디렉토리 생성 실패: \(error.localizedDescription)")
            completion(false, nil, nil)
            return
        }

        let m3u8Output = hlsDirectory.appendingPathComponent("\(uuid).m3u8")
        let segmentPath = hlsDirectory.appendingPathComponent("\(uuid)_%03d.ts").path

        let command = """
        -i \(mp4URL.path) -codec copy -start_number 0 -hls_time 3 -hls_list_size 0 \
        -hls_segment_filename \(segmentPath) -f hls \(m3u8Output.path)
        """

        FFmpegKit.executeAsync(command) { session in
            if let session = session, let returnCode = session.getReturnCode(), returnCode.isValueSuccess() {
                print("✅ HLS 변환 성공: \(m3u8Output.absoluteString)")
                completion(true, hlsDirectory, uuid)
            } else {
                print("❌ HLS 변환 실패")
                completion(false, nil, nil)
            }
        }
    }

    // MARK: - HLS 파일 존재 확인
    func verifyHLSFiles(hlsDirectory: URL, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1.0) {
            do {
                let files = try FileManager.default.contentsOfDirectory(atPath: hlsDirectory.path)
                if files.contains(where: { $0.hasSuffix(".m3u8") }) {
                    completion(true)
                } else {
                    print("❌ .m3u8 파일이 존재하지 않음")
                    completion(false)
                }
            } catch {
                print("❌ 디렉토리 검사 실패: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    // MARK: - 다운로드 URL 재시도 유틸리티
    func getDownloadURLWithRetry(ref: StorageReference, retryCount: Int = 3, delay: TimeInterval = 1.0, completion: @escaping (URL?) -> Void) {
        ref.downloadURL { url, error in
            if let url = url {
                completion(url)
            } else if retryCount > 0 {
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.getDownloadURLWithRetry(ref: ref, retryCount: retryCount - 1, delay: delay, completion: completion)
                }
            } else {
                print("❌ 재시도 후에도 URL 획득 실패: \(error?.localizedDescription ?? "알 수 없음")")
                completion(nil)
            }
        }
    }

    // MARK: - Firebase Storage에 업로드
    func uploadHLSToFirebase(hlsDirectory: URL, completion: @escaping (Bool, String?) -> Void) {
        verifyHLSFiles(hlsDirectory: hlsDirectory) { isReady in
            guard isReady else {
                print("❌ HLS 파일이 아직 접근 불가능. 업로드 취소.")
                completion(false, nil)
                return
            }

            do {
                let allFiles = try FileManager.default.contentsOfDirectory(at: hlsDirectory, includingPropertiesForKeys: nil)
                guard let m3u8URL = allFiles.first(where: { $0.pathExtension == "m3u8" }) else {
                    print("❌ .m3u8 파일을 찾을 수 없습니다.")
                    completion(false, nil)
                    return
                }

                let uuid = m3u8URL.deletingPathExtension().lastPathComponent
                let folderRef = Storage.storage().reference().child("hlsVideos").child(uuid)

                let tsFiles = allFiles.filter { $0.pathExtension == "ts" }
                var tsURLMap: [String: String] = [:]
                let dispatchGroup = DispatchGroup()
                let dispatchQueue = DispatchQueue(label: "ts-upload-sync") // 동기적 딕셔너리 접근용

                // ✅ 병렬 업로드
                for tsFile in tsFiles {
                    let fileName = tsFile.lastPathComponent
                    let tsRef = folderRef.child(fileName)

                    dispatchGroup.enter()
                    tsRef.putFile(from: tsFile, metadata: nil) { metadata, error in
                        if let error = error {
                            print("❌ .ts 업로드 실패 (\(fileName)): \(error.localizedDescription)")
                            dispatchGroup.leave()
                            return
                        }

                        tsRef.downloadURL { url, error in
                            if let url = url {
                                dispatchQueue.sync {
                                    tsURLMap[fileName] = url.absoluteString
                                }
                                print("✅ .ts 업로드 및 URL 확보 완료: \(fileName)")
                            } else {
                                print("❌ .ts 다운로드 URL 실패 (\(fileName)): \(error?.localizedDescription ?? "")")
                            }
                            dispatchGroup.leave()
                        }
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    do {
                        var m3u8Content = try String(contentsOf: m3u8URL)
                        for (fileName, url) in tsURLMap {
                            m3u8Content = m3u8Content.replacingOccurrences(of: fileName, with: url)
                        }

                        let updatedM3U8Path = hlsDirectory.appendingPathComponent("updated_\(uuid).m3u8")
                        try m3u8Content.write(to: updatedM3U8Path, atomically: true, encoding: .utf8)

                        let m3u8Ref = folderRef.child("\(uuid).m3u8")
                        m3u8Ref.putFile(from: updatedM3U8Path, metadata: nil) { metadata, error in
                            if let error = error {
                                print("❌ .m3u8 업로드 실패: \(error.localizedDescription)")
                                completion(false, nil)
                                return
                            }

                            m3u8Ref.downloadURL { url, error in
                                if let url = url {
                                    print("✅ Firestore에 저장할 HLS URL: \(url.absoluteString)")
                                    completion(true, url.absoluteString)
                                } else {
                                    print("❌ .m3u8 URL 획득 실패")
                                    completion(false, nil)
                                }
                            }
                        }
                    } catch {
                        print("❌ .m3u8 수정 또는 업로드 실패: \(error.localizedDescription)")
                        completion(false, nil)
                    }
                }

            } catch {
                print("❌ HLS 디렉토리 탐색 실패: \(error.localizedDescription)")
                completion(false, nil)
            }
        }
    }

    // MARK: - Firestore 저장
    func saveHLSToFirestore(title: String, hlsURL: String, selectedTeam: String, uploader: String, completion: @escaping (Bool) -> Void) {
        let data: [String: Any] = [
            "title": title,
            "uploader": uploader,
            "videoURL": hlsURL,
            "team": selectedTeam,
            "timestamp": Timestamp(date: Date())
        ]

        db.collection("uploadedSongs").addDocument(data: data) { error in
            if let error = error {
                print("❌ Firestore 저장 실패: \(error.localizedDescription)")
                completion(false)
            } else {
                print("✅ Firestore 저장 성공: \(title)")
                completion(true)
            }
        }
    }
}
