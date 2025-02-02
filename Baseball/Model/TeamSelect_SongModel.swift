//
//  TeamSelect_SongModel.swift
//     
//
//  Created by 곽현우 on 1/21/25.
//

import FirebaseFirestore
import FirebaseStorage
import AVFoundation

struct Song: Identifiable {
    let id: String
    let title: String
    let audioUrl: String
    let lyrics: String
}

class TeamSelect_SongModel {
    private let db = Firestore.firestore()
    //URL 캐시 - 중복 다운로드 방지, 초기에 다운된 URL 저장 후 재요청시 호출
    private var cachedUrls: [String: URL] = [:]
    private var audioPlayer: AVPlayer?

    // 노래 목록 가져오기
    func fetchSongs(for team: String, category: SongCategory, completion: @escaping ([Song]) -> Void) {
        print("Fetching \(category == .teamSongs ? "team songs" : "player songs") for team: \(team)")

        let collectionName = category == .teamSongs ? "teamSongs" : "playerSongs"
        db.collection("songs").document(team).collection(collectionName).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching songs: \(error.localizedDescription)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                print("No songs found for \(category.rawValue) in team: \(team)")
                completion([])
                return
            }

            print("Fetched \(documents.count) documents for \(category.rawValue)")
            var songs: [Song] = []
            //네트워크 요청 최대 3개까지 설정해서 과도한 부하 방지
            let semaphore = DispatchSemaphore(value: 3)
            let group = DispatchGroup()

            for doc in documents {
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let gsUrl = data["audioUrl"] as? String,
                      let lyrics = data["lyrics"] as? String else {
                    continue
                }

                if let cachedUrl = self.cachedUrls[gsUrl] {
                    // 캐시된 URL을 사용
                    songs.append(Song(id: doc.documentID, title: title, audioUrl: cachedUrl.absoluteString, lyrics: lyrics))
                } else {
                    // QoS 일치 및 semaphore 대기
                    DispatchQueue.global(qos: .utility).async(group: group) {
                        semaphore.wait()
                        self.getDownloadURL(for: gsUrl) { [weak self] httpUrl in
                            if let httpUrl = httpUrl {
                                self?.cachedUrls[gsUrl] = httpUrl
                                songs.append(Song(id: doc.documentID, title: title, audioUrl: httpUrl.absoluteString, lyrics: lyrics))
                            }
                            semaphore.signal()
                        }
                    }
                }
            }

            group.notify(queue: .main) {
                completion(songs)
            }
        }
    }

    // Firebase Storage URL 가져오기
    func getDownloadURL(for gsUrl: String, completion: @escaping (URL?) -> Void) {
        guard let range = gsUrl.range(of: "gs://") else {
            completion(nil)
            return
        }

        let path = String(gsUrl[range.upperBound...])
        guard let slashIndex = path.firstIndex(of: "/") else {
            completion(nil)
            return
        }

        let storagePath = String(path[slashIndex...]).dropFirst()
        let storageRef = Storage.storage().reference(withPath: String(storagePath))

        //다운로드 URL을 백그라운드로 가져오고 메인 쓰레드에서 결과 처리 
        DispatchQueue.global(qos: .userInitiated).async {
            storageRef.downloadURL { url, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error fetching download URL: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        completion(url)
                    }
                }
            }
        }
    }
}
