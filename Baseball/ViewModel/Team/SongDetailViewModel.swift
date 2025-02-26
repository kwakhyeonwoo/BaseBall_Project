//
//  SongDetailViewModel.swift
//     
//
//  Created by 곽현우 on 2/12/25.
//

import SwiftUI
import Combine
import AVFoundation

class SongDetailViewModel: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var duration: Double = 0
    @Published var currentTime: Double = 0
    @Published var progress: Double = 0
    @Published var didFinishPlaying: Bool = false
    @Published var hasPrevSong: Bool = false
    @Published var hasNextSong: Bool = false
    @Published var currentSong: Song?
    @Published var lyricsStartTime: Double = 0.0
    @Published var timestamps: [Double] = [] // ✅ Firestore에서 가져온 timestamps 저장

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
                self.updateCurrentSong(newSong)
            }
            .store(in: &cancellables)
    }

    /// 🔹 새로운 곡 정보 업데이트 및 `timestamps` 불러오기
    private func updateCurrentSong(_ newSong: Song?) {
        guard let song = newSong else { return }
        self.currentSong = song
        self.lyricsStartTime = song.lyricsStartTime // ✅ Firestore에서 가져온 시작 시간 반영
        self.timestamps = song.timestamps // ✅ Firestore에서 가져온 timestamps 반영
        
        checkPreviousSongAvailability(for: song)
        checkNextSongAvailability(for: song)
    }

    // 🔹 선택한 곡을 현재 재생 중인 곡과 비교, 새로 재생할지 결정하는 함수
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

            print("🎵 새로운 곡 로드: \(song.title)")
            playerManager.play(url: url, for: song)

            // ✅ Now Playing 정보 즉시 업데이트
            DispatchQueue.main.async {
                self.playerManager.backgroundManager.updateNowPlayingInfo()
            }
        }
    }

    func togglePlayPause(for song: Song) {
        if AudioPlayerManager.shared.isPlaying {
            AudioPlayerManager.shared.pause()
        } else {
            if let player = AudioPlayerManager.shared.player,
               let currentSong = AudioPlayerManager.shared.currentSong,
               let currentUrl = AudioPlayerManager.shared.getCurrentUrl(),
               currentUrl == URL(string: currentSong.audioUrl), player.currentItem != nil {
                
                let savedTime = AudioPlayerManager.shared.currentTime // ✅ 이전 재생 위치 저장
                print("🔄 제어센터에서 재생 버튼 눌림, 이전 재생 위치: \(savedTime)초")

                player.seek(to: CMTime(seconds: savedTime, preferredTimescale: 600)) // ✅ 이전 위치 유지
                player.play()
                AudioPlayerManager.shared.isPlaying = true
                AudioPlayerManager.shared.objectWillChange.send()

                // ✅ Now Playing 정보 업데이트
                DispatchQueue.main.async {
                    AudioPlayerManager.shared.backgroundManager.updateNowPlayingInfo()
                }

            } else {
                // ✅ 기존 곡 정보 유지하여 새로 로드하지 않음
                if let validUrl = URL(string: AudioPlayerManager.shared.currentSong?.audioUrl ?? "") {
                    print("🔄 기존 곡 유지하여 다시 재생: \(AudioPlayerManager.shared.currentSong?.title ?? "Unknown")")
                    AudioPlayerManager.shared.play(url: validUrl, for: AudioPlayerManager.shared.currentSong!)
                } else {
                    print("❌ Error: Invalid URL for song \(AudioPlayerManager.shared.currentSong?.title ?? "Unknown")")
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
