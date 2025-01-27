//
//  TeamSelect_SongModel.swift
//     
//
//  Created by 곽현우 on 1/21/25.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

struct Song: Identifiable {
    let id: String
    let title: String
    let audioUrl: String
    let lyrics: String
}

class TeamSelect_SongModel {
    private let db = Firestore.firestore()
    
    // 노래 데이터 가져오기
    //음원이 나옴
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
                print("No songs found for \(category) in team: \(team)")
                completion([])
                return
            }
            
            print("Fetched \(documents.count) documents for \(category)")
            
            var songs: [Song] = []
            let group = DispatchGroup()
            
            for doc in documents {
                let data = doc.data()
                guard let title = data["title"] as? String,
                      let gsUrl = data["audioUrl"] as? String,
                      let lyrics = data["lyrics"] as? String else {
                    print("Invalid data format: \(doc.data())")
                    continue
                }
                
                group.enter()
                
                self.getDownloadURL(for: gsUrl) { httpUrl in
                    guard let httpUrl = httpUrl else {
                        print("Failed to convert gsUrl to HTTP URL: \(gsUrl)")
                        group.leave()
                        return
                    }
                    
                    let song = Song(
                        id: doc.documentID,
                        title: title,
                        audioUrl: httpUrl.absoluteString,
                        lyrics: lyrics
                    )
                    songs.append(song)
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                completion(songs)
            }
        }
    }
    
     //한글 리스트 나옴
//     func fetchSongs(for team: String, category: SongCategory, completion: @escaping ([Song]) -> Void) {
//             let collectionName = category == .teamSongs ? "teamSongs" : "playerSongs"
//             db.collection("songs").document(team).collection(collectionName).getDocuments { snapshot, error in
//                 if let error = error {
//                     print("Error fetching songs: \(error.localizedDescription)")
//                     completion([])
//                     return
//                 }
//                 
//                 guard let documents = snapshot?.documents else {
//                     print("No songs found for team: \(team) in category: \(category.rawValue)")
//                     completion([])
//                     return
//                 }
//                 
//                 let fetchedSongs = documents.compactMap { doc -> Song? in
//                     let data = doc.data()
//                     guard let title = data["title"] as? String,
//                           let audioUrl = data["audioUrl"] as? String,
//                           let lyrics = data["lyrics"] as? String else {
//                         print("Invalid data format: \(doc.data())")
//                         return nil
//                     }
//                     
//                     return Song(
//                         id: doc.documentID,
//                         title: title,
//                         audioUrl: audioUrl,
//                         lyrics: lyrics
//                     )
//                 }
//                 
//                 completion(fetchedSongs)
//             }
//         }
     

    // Firebase Storage에서 다운로드 URL 가져오기
    func getDownloadURL(for gsUrl: String, completion: @escaping (URL?) -> Void) {
        print("Original gsUrl: \(gsUrl)")
        
        // `gs://` 경로에서 Storage Path 추출
        guard let range = gsUrl.range(of: "gs://") else {
            print("Invalid gsUrl format: \(gsUrl)")
            completion(nil)
            return
        }

        let path = String(gsUrl[range.upperBound...]) // "bucket-name/path/to/file"
        guard let slashIndex = path.firstIndex(of: "/") else {
            print("Invalid path format: \(path)")
            completion(nil)
            return
        }

        let storagePath = String(path[slashIndex...]).dropFirst() // "path/to/file"
        let finalStoragePath = String(storagePath) // Substring → String 변환
        print("Extracted storage path: \(finalStoragePath)")

        let storageRef = Storage.storage().reference(withPath: finalStoragePath)
        storageRef.downloadURL { url, error in
            if let error = error {
                print("Error fetching download URL: \(error.localizedDescription)")
                completion(nil)
            } else {
                print("Successfully fetched HTTP URL: \(url?.absoluteString ?? "nil")")
                completion(url)
            }
        }
    }
}

