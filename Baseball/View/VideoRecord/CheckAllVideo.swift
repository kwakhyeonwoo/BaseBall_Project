//
//  CheckAllVideo.swift
//     
//
//  Created by 곽현우 on 2/27/25.
//

import SwiftUI
import AVKit
import FirebaseFirestore

struct CheckAllVideo: View {
    let selectedTeam: String
    let selectedTeamImage: String
    @State private var selectedCategory: UploadedSongCategory = .uploaded
    @State private var uploadedSongs: [UploadedSong] = []
    @State private var favoriteSongs: Set<String> = [] // 하트 기능
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            VStack {
                categoryPicker()
                songListView()
                Spacer()
            }
            .padding()
            .navigationTitle("업로드된 응원가")
            .onAppear {
                loadUploadedSongs()
            }
        }
    }
    
    private func categoryPicker() -> some View {
        Picker("Category", selection: $selectedCategory) {
            Text("업로드 응원가").tag(UploadedSongCategory.uploaded)
            Text("인기 응원가").tag(UploadedSongCategory.popular)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding()
        .onChange(of: selectedCategory) { _ in
            loadUploadedSongs()
        }
    }
    
    private func songListView() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(uploadedSongs) { song in
                    songCard(song: song)
                }
            }
            .padding()
        }
    }
    
    private func songCard(song: UploadedSong) -> some View {
        HStack {
            Image(selectedTeamImage)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
            VStack(alignment: .leading) {
                Text(song.uploader)
                    .font(.headline)
                Text(song.title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            
            Button(action: {
                toggleFavorite(song: song)
            }) {
                Image(systemName: favoriteSongs.contains(song.id) ? "heart.fill" : "heart")
                    .foregroundColor(favoriteSongs.contains(song.id) ? .red : .gray)
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
    
    private func toggleFavorite(song: UploadedSong) {
        if favoriteSongs.contains(song.id) {
            favoriteSongs.remove(song.id)
        } else {
            favoriteSongs.insert(song.id)
        }
    }
    
    private func loadUploadedSongs() {
        db.collection("uploadedSongs").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching uploaded songs: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.uploadedSongs = documents.compactMap { document in
                    let data = document.data()
                    return UploadedSong(
                        id: document.documentID,
                        title: data["title"] as? String ?? "Unknown Title",
                        uploader: data["uploader"] as? String ?? "익명"
                    )
                }
            }
        }
    }
    
    func uploadNewSong(title: String, uploader: String) {
        let newSong: [String: Any] = [
            "title": title,
            "uploader": uploader
        ]
        
        db.collection("uploadedSongs").addDocument(data: newSong) { error in
            if let error = error {
                print("Error uploading song: \(error.localizedDescription)")
            } else {
                print("✅ 응원가 업로드 완료: \(title)")
                loadUploadedSongs() // 새로고침
            }
        }
    }
    
    private func fetchUploadedSongs() {
        db.collection("uploadedSongs")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore에서 응원가 불러오기 실패: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                uploadedSongs = documents.map { doc in
                    let data = doc.data()
                    return UploadedSong(
                        id: doc.documentID,
                        title: data["title"] as? String ?? "제목 없음",
                        uploader: data["uploader"] as? String ?? "익명"
                    )
                }
            }
    }
}

struct UploadedSong: Identifiable {
    let id: String
    let title: String
    let uploader: String
}

enum UploadedSongCategory {
    case uploaded
    case popular
}


//#Preview {
//    CheckAllVideo()
//}
