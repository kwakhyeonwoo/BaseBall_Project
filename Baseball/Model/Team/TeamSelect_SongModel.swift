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
import FirebaseAuth

struct Song: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let title: String
    let audioUrl: String
    let lyrics: String
    let teamImageName: String
    let lyricsStartTime: Double
    let timestamps: [Double]
}

extension Song {
    func withUpdatedUrl(_ newUrl: String) -> Song {
        return Song(
            id: self.id,
            title: self.title,
            audioUrl: newUrl,
            lyrics: self.lyrics,
            teamImageName: self.teamImageName,
            lyricsStartTime: self.lyricsStartTime,
            timestamps: self.timestamps
        )
    }
}

class TeamSelect_SongModel {
    private let db = Firestore.firestore()
    private var cachedUrls: [String: URL] = [:]

    func fetchSongs(for team: String, category: SongCategory, completion: @escaping ([Song]) -> Void) {
        getAllSongs { allSongs in
            let teamSongs = allSongs.filter { $0.teamImageName == team }
            completion(teamSongs)
        }
    }

    private func customSort(_ songs: [Song]) -> [Song] {
        return songs.sorted { lhs, rhs in
            let lhsIsEnglish = lhs.title.range(of: "^[A-Za-z]", options: .regularExpression) != nil
            let rhsIsEnglish = rhs.title.range(of: "^[A-Za-z]", options: .regularExpression) != nil
            if lhsIsEnglish != rhsIsEnglish { return lhsIsEnglish }

            let lhsNum = lhs.title.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init).first ?? 0
            let rhsNum = rhs.title.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap(Int.init).first ?? 0
            if lhsNum != rhsNum { return lhsNum < rhsNum }

            return lhs.title.localizedStandardCompare(rhs.title) == .orderedAscending
        }
    }

    func getDownloadURL(for gsUrl: String, completion: @escaping (URL?) -> Void) {
        guard gsUrl.starts(with: "gs://") else {
            print("❌ Invalid gs:// URL: \(gsUrl)")
            completion(nil)
            return
        }
        if let cached = cachedUrls[gsUrl] {
            completion(cached)
            return
        }
        let ref = Storage.storage().reference(forURL: gsUrl)
        ref.downloadURL { url, error in
            DispatchQueue.main.async {
                if let url = url {
                    self.cachedUrls[gsUrl] = url
                    print("✅ URL 변환 완료: \(url.absoluteString)")
                    completion(url)
                } else {
                    print("❌ URL 변환 실패: \(error?.localizedDescription ?? "unknown")")
                    completion(nil)
                }
            }
        }
    }

    func convertToHttp(gsUrl: String) -> String? {
        let bucket = "baseball-642ed.firebasestorage.app"
        guard gsUrl.starts(with: "gs://\(bucket)/") else { return nil }
        let path = gsUrl.replacingOccurrences(of: "gs://\(bucket)/", with: "")
        guard let encoded = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else { return nil }
        return "https://firebasestorage.googleapis.com/v0/b/\(bucket)/o/\(encoded)?alt=media"
    }

    func getAllSongs(completion: @escaping ([Song]) -> Void) {
        let teams = ["SSG", "Samsung", "LG", "Doosan", "Hanwha", "KIA", "Kiwoom", "Kt", "Lotte", "NC"]
        var allSongs: [Song] = []
        let group = DispatchGroup()

        for team in teams {
            group.enter()
            db.collection("songs").document(team).collection("teamSongs").getDocuments { snapshot, error in
                defer { group.leave() }
                guard error == nil, let docs = snapshot?.documents else { return }
                for doc in docs {
                    let data = doc.data()
                    guard let title = data["title"] as? String,
                          let audioUrl = data["audioUrl"] as? String,
                          let lyrics = data["lyrics"] as? String,
                          let lyricsStartTime = data["lyricsStartTime"] as? Double,
                          let timestamps = data["timestamps"] as? [Double] else { continue }
                    allSongs.append(Song(id: doc.documentID, title: title, audioUrl: audioUrl, lyrics: lyrics, teamImageName: team, lyricsStartTime: lyricsStartTime, timestamps: timestamps))
                }
            }
        }

        group.notify(queue: .main) {
            completion(self.customSort(allSongs))
        }
    }

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

    func hasPreviousSong(for song: Song, completion: @escaping (Bool) -> Void) {
        getAllSongs { songs in
            completion((songs.firstIndex(where: { $0.id == song.id }) ?? 0) > 0)
        }
    }

    func hasNextSong(for song: Song, completion: @escaping (Bool) -> Void) {
        getAllSongs { songs in
            guard let index = songs.firstIndex(where: { $0.id == song.id }) else {
                completion(false)
                return
            }
            completion(index < songs.count - 1)
        }
    }
}
