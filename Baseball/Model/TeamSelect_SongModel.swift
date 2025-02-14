//
//  TeamSelect_SongModel.swift
//     
//
//  Created by 곽현우 on 1/21/25.
//

import FirebaseFirestore
import FirebaseStorage
import AVFoundation

struct Song: Identifiable, Equatable {
    let id: String
    let title: String
    let audioUrl: String
    let lyrics: String
    let teamImageName: String
}

class TeamSelect_SongModel {
    private let db = Firestore.firestore()
    //URL 캐시 - 중복 다운로드 방지, 초기에 다운된 URL 저장 후 재요청시 호출
    private var cachedUrls: [String: URL] = [:]
    private var audioPlayer: AVPlayer?

    // 노래 목록 가져오기
    // firebase와 네트워크 연동
    func fetchSongs(for team: String, category: SongCategory, completion: @escaping ([Song]) -> Void) {
        print("Fetching \(category == .teamSongs ? "team songs" : "player songs") for team: \(team)")

        let collectionName = category == .teamSongs ? "teamSongs" : "playerSongs"
        db.collection("songs").document(team).collection(collectionName).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

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
            let group = DispatchGroup()

            for doc in documents {
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let gsUrl = data["audioUrl"] as? String,
                      let lyrics = data["lyrics"] as? String else {
                    continue
                }

                let teamImageName = determineTeamImageName(for: team)

                if let cachedUrl = self.cachedUrls[gsUrl] {
                    // 캐시된 URL을 사용
                    songs.append(Song(id: doc.documentID, title: title, audioUrl: cachedUrl.absoluteString, lyrics: lyrics, teamImageName: teamImageName))
                } else {
                    // URL 다운로드 작업을 그룹에 추가
                    group.enter()
                    self.getDownloadURL(for: gsUrl) { [weak self] httpUrl in
                        if let httpUrl = httpUrl {
                            self?.cachedUrls[gsUrl] = httpUrl
                            songs.append(Song(id: doc.documentID, title: title, audioUrl: httpUrl.absoluteString, lyrics: lyrics, teamImageName: teamImageName))
                        } else {
                            print("Failed to fetch URL for song: \(title)")
                        }
                        group.leave()  // 비동기 작업이 완료되면 그룹에서 작업 제거
                    }
                }
            }

            // 모든 비동기 작업이 완료되면 UI 업데이트
            // 리스트 오름차순
            group.notify(queue: .main) {
                let sortedSongs = songs.sorted { lhs, rhs in
                    let lhsIsEnglish = lhs.title.range(of: "^[A-Za-z]", options: .regularExpression) != nil
                    let rhsIsEnglish = rhs.title.range(of: "^[A-Za-z]", options: .regularExpression) != nil

                    // 영어 제목이 우선 정렬
                    if lhsIsEnglish && !rhsIsEnglish {
                        return true
                    } else if !lhsIsEnglish && rhsIsEnglish {
                        return false
                    }

                    // 영어 또는 한국어끼리는 자연 정렬 (숫자 포함)
                    let lhsComponents = lhs.title.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
                    let rhsComponents = rhs.title.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }

                    if let lhsNumber = lhsComponents.first, let rhsNumber = rhsComponents.first {
                        return lhsNumber < rhsNumber
                    }

                    return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
                }

                completion(sortedSongs)
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
    
    // MARK: 팀 선택시 제어 화면에서 보이는 팀 이미지
    private func determineTeamImageName(for team: String) -> String {
        switch team {
        case "SSG": return "SSG"
        case "Samsung": return "Samsung"
        case "LG": return "LG"
        case "Doosan": return "Doosan"
        case "Hanwha": return "Hanwha"
        case "KIA": return "KIA"
        case "Kiwoom": return "Kiwoom"
        case "Kt": return "Kt"
        case "Lotte": return "Lotte"
        case "NC": return "NC"
        default: return "DefaultTeamImage"
        }
    }
}

extension TeamSelect_SongModel {
    /// 🔹 Firestore에서 모든 곡 불러오기
    func getAllSongs(completion: @escaping ([Song]) -> Void) {
        let teams = ["SSG", "Samsung", "LG", "Doosan", "Hanwha", "KIA", "Kiwoom", "Kt", "Lotte", "NC"]
        var allSongs: [Song] = []
        let group = DispatchGroup()

        for team in teams {
            group.enter()
            db.collection("songs").document(team).collection("teamSongs").getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore에서 노래 목록을 불러오는 데 실패함: \(error.localizedDescription)")
                    group.leave()
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ \(team)의 팀 응원가 없음")
                    group.leave()
                    return
                }

                for document in documents {
                    let data = document.data()
                    guard let title = data["title"] as? String,
                          let audioUrl = data["audioUrl"] as? String,
                          let lyrics = data["lyrics"] as? String else { continue }

                    let song = Song(id: document.documentID, title: title, audioUrl: audioUrl, lyrics: lyrics, teamImageName: team)
                    allSongs.append(song)
                }

                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(allSongs.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending })
        }
    }


    /// 🔹 Firestore에서 현재 곡의 이전 곡 찾기
    func getPreviousSong(for song: Song, completion: @escaping (Song?) -> Void) {
        getAllSongs { songs in
            guard let index = songs.firstIndex(where: { $0.id == song.id }), index > 0 else {
                completion(nil)
                return
            }
            completion(songs[index - 1])
        }
    }

    func getNextSong(for song: Song, completion: @escaping (Song?) -> Void) {
        getAllSongs { songs in
            guard let index = songs.firstIndex(where: { $0.id == song.id }), index < songs.count - 1 else {
                completion(nil)
                return
            }
            completion(songs[index + 1])
        }
    }

    /// 🔹 Firestore에서 현재 곡의 이전 곡 존재 여부 확인
    func hasPreviousSong(for song: Song, completion: @escaping (Bool) -> Void) {
        getAllSongs { songs in
            let hasPrevious = (songs.firstIndex(where: { $0.id == song.id }) ?? 0) > 0
            completion(hasPrevious)
        }
    }

    /// 🔹 Firestore에서 현재 곡의 다음 곡 존재 여부 확인
    func hasNextSong(for song: Song, completion: @escaping (Bool) -> Void) {
        getAllSongs { songs in
            let hasNext = (songs.firstIndex(where: { $0.id == song.id }) ?? songs.count - 1) < songs.count - 1
            completion(hasNext)
        }
    }
}
