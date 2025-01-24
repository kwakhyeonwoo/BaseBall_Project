//
//  TeamSelect_SongViewModel.swift
//     
//
//  Created by 곽현우 on 1/21/25.
//

import SwiftUI

enum SongCategory {
    case teamSongs
    case playerSongs
}

class TeamSelectSongViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var favoriteSongs: [String] = [] // 즐겨찾기된 Song ID를 저장
    @Published var selectedCategory: SongCategory = .teamSongs // 현재 선택된 카테고리

    private let model = TeamSelect_SongModel()

    // MARK: - Fetch Songs
    func fetchSongs(for team: String) {
        isLoading = true
        model.fetchSongs(for: team, category: selectedCategory) { [weak self] fetchedSongs in
            DispatchQueue.main.async {
                self?.songs = fetchedSongs
                self?.isLoading = false
            }
        }
    }

    // MARK: - Toggle Favorite
    func toggleFavorite(song: Song) {
        if let index = favoriteSongs.firstIndex(of: song.id) {
            favoriteSongs.remove(at: index) // 즐겨찾기에서 제거
        } else {
            favoriteSongs.append(song.id) // 즐겨찾기에 추가
        }
    }

    // MARK: - Check if Song is Favorite
    func isFavorite(song: Song) -> Bool {
        return favoriteSongs.contains(song.id)
    }
}
