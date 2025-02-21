//
//  SongDetailViewModel.swift
//     
//
//  Created by 곽현우 on 2/12/25.
//

import SwiftUI
import Combine

class SongDetailViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var duration: Double = 0
    @Published var currentTime: Double = 0
    @Published var progress: Double = 0
    @Published var didFinishPlaying: Bool = false
    @Published var hasPrevSong: Bool = false
    @Published var hasNextSong: Bool = false
    @Published var currentSong: Song?

    private let playerManager = AudioPlayerManager.shared
    private let songModel = TeamSelect_SongModel() // Firestore에서 데이터 가져오기
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // ✅ 플레이어 상태 동기화
        playerManager.$isPlaying
            .receive(on: RunLoop.main)
            .assign(to: &$isPlaying)
        
        playerManager.$currentTime
            .receive(on: RunLoop.main)
            .sink { [weak self] time in
                guard let self = self else { return }
                self.currentTime = time
                let safeDuration = max(1, self.playerManager.duration)
                self.progress = min(1, max(0, time / safeDuration))
            }
            .store(in: &cancellables)
        
        playerManager.$duration
            .receive(on: RunLoop.main)
            .assign(to: &$duration)
        
        playerManager.$didFinishPlaying
            .receive(on: RunLoop.main)
            .assign(to: &$didFinishPlaying)

        // ✅ 현재 곡 변경 시 Firestore에서 이전/다음 곡 확인
        playerManager.$currentSong
            .receive(on: RunLoop.main)
            .sink { [weak self] newSong in
                guard let self = self else { return }
                self.currentSong = newSong
                if let song = newSong {
                    self.checkPreviousSongAvailability(for: song)
                    self.checkNextSongAvailability(for: song)
                }
            }
            .store(in: &cancellables)
    }

    //선택한 곡을 현재 재생 중인 곡이랑 비교, 새로 재생할지 결정하는 함수
    func setupPlayerIfNeeded(for song: Song) {
        songModel.getDownloadURL(for: song.audioUrl) { [weak self] url in
            guard let self = self, let url = url else {
                print("❌ URL 변환 실패: \(song.audioUrl)")
                return
            }

            if let currentUrl = playerManager.getCurrentUrl(),
               let player = playerManager.player,
               currentUrl == url, player.currentItem != nil {
                return // ✅ 같은 곡이면 초기화하지 않음
            }

            playerManager.play(url: url, for: song)
        }
    }

    func togglePlayPause(for song: Song) {
        if playerManager.isPlaying {
            playerManager.pause()
        } else {
            if let currentUrl = playerManager.getCurrentUrl(),
               let player = playerManager.player,
               currentUrl == playerManager.currentUrl, player.currentItem != nil {
                playerManager.resume()
            } else {
                let validUrl = playerManager.currentUrl ?? URL(string: song.audioUrl)

                if let url = validUrl {
                    // ✅ 변경 감지를 강제하여 SwiftUI에서 반영되도록 함
                    playerManager.objectWillChange.send()
                    playerManager.play(url: url, for: song)
                } else {
                    print("❌ Error: Invalid URL for song \(song.title)")
                }
            }
        }
    }


    func playPrevious() {
        guard playerManager.currentSong != nil else { return }
        playerManager.playPrevious()
    }

    func playNext() {
        guard playerManager.currentSong != nil else { return }
        playerManager.playNext()
    }

    func checkPreviousSongAvailability(for song: Song) {
        playerManager.hasPreviousSong(for: song) { [weak self] hasPrevious in
            DispatchQueue.main.async {
                self?.hasPrevSong = hasPrevious
            }
        }
    }

    func checkNextSongAvailability(for song: Song) {
        playerManager.hasNextSong(for: song) { [weak self] hasNext in
            DispatchQueue.main.async {
                self?.hasNextSong = hasNext
            }
        }
    }

    func seek(to time: Double) {
        playerManager.seek(to: time)
    }
    
    func resetFinishState() {
        playerManager.didFinishPlaying = false
    }
}
