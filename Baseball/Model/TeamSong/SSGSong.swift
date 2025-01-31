//
//  SSGSong.swift
//     
//
//  Created by 곽현우 on 1/27/25.
//

//import FirebaseFirestore
//
//func addTestSongs() {
//    let db = Firestore.firestore()
//    
//    let songs = [
//        ["title": "승리의 깃발", "audioUrl": "gs://baseball-642ed.firebasestorage.app/SSG/ssg_01.mp4", "lyrics": "가사 내용"],
//        ["title": "We are the Landers", "audioUrl": "gs://baseball-642ed.firebasestorage.app/SSG/We are the Landers.mp4", "lyrics": "가사 내용"]
//    ]
//    
//    for (index, song) in songs.enumerated() {
//        db.collection("songs").document("SSG").collection("teamSongs").document("song_\(index + 1)").setData(song) { error in
//            if let error = error {
//                print("Error adding song: \(error.localizedDescription)")
//            } else {
//                print("Song added successfully.")
//            }
//        }
//    }
//}
