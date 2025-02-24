//
//  TeamSelect_SongModel.swift
//     
//
//  Created by 곽현우 on 1/21/25.
//

import FirebaseFirestore
import FirebaseStorage
import Firebase
import AVFoundation

struct Song: Identifiable, Equatable, Codable {
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
        getAllSongs { allSongs in
            let teamSongs = allSongs.filter { $0.teamImageName == team }
            completion(teamSongs)
        }
    }


    //MARK: 리스트 오름차순
    private func customSort(_ songs: [Song]) -> [Song] {
        return songs.sorted { lhs, rhs in
            let lhsIsEnglish = lhs.title.range(of: "^[A-Za-z]", options: .regularExpression) != nil
            let rhsIsEnglish = rhs.title.range(of: "^[A-Za-z]", options: .regularExpression) != nil

            // 영어 먼저 정렬
            if lhsIsEnglish && !rhsIsEnglish {
                return true
            } else if !lhsIsEnglish && rhsIsEnglish {
                return false
            }

            // ✅ 2. Extract numeric components for sorting numbers (e.g., "Song 1" < "Song 2")
            let lhsNumbers = lhs.title.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
            let rhsNumbers = rhs.title.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }

            if let lhsNumber = lhsNumbers.first, let rhsNumber = rhsNumbers.first {
                return lhsNumber < rhsNumber
            }

            // ✅ 3. Final fallback: Sort by localized standard comparison
            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
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
    /// 🔹 Firestore에서 모든 곡 불러오기 rotlqkf wrkxek
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
            let sortedSongs = self.customSort(allSongs)  // ✅ Apply the same sorting
            completion(sortedSongs)
        }
    }


    /// 🔹 Firestore에서 현재 곡의 이전 곡 찾기
    func getPreviousSong(for song: Song, completion: @escaping (Song?) -> Void) {
        getAllSongs { songs in
            guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
                print("❌ Error: Song not found in playlist.")
                completion(nil)
                return
            }
            let prevIndex = (index == 0) ? songs.count - 1 : index - 1  // ✅ Loop to last song if at start
            _ = songs[prevIndex]
            completion(songs[prevIndex])
        }
    }

    func getNextSong(for song: Song, completion: @escaping (Song?) -> Void) {
        getAllSongs { songs in
            guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
                print("❌ Error: Current song not found in the playlist")
                completion(nil)
                return
            }

            let nextIndex = (index + 1) % songs.count // ✅ Loop to first song if at the end
            let nextSong = songs[nextIndex]
            
            print("🎵 Next Song: \(nextSong.title) at Index \(nextIndex)")
            completion(nextSong)
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
