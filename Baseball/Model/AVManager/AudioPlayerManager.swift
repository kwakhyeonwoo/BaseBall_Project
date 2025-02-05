//
//  AudioPlayerManager.swift
//     
//
//  Created by 곽현우 on 1/31/25.
//

import AVFoundation
import Combine
import MediaPlayer

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0

    private var player: AVPlayer?
    private var playerObserver: Any?
    private var currentUrl: URL?
    //외부에서 읽기만 하고 수정은 불가능
    private(set) var currentSong: Song?
    private let backgroundManager = AVPlayerBackgroundManager()

    init() {
        backgroundManager.setupAudioSessionNotifications()
        backgroundManager.configureRemoteCommandCenter(for: self)
        setupEndTimeObserver()
    }

    // MARK: - 재생 메서드
    func play(url: URL, for song: Song) {
        if currentUrl != url {
            setupPlayer(url: url, for: song)
            currentUrl = url
            currentSong = song
        }

        player?.play()
        isPlaying = true
        backgroundManager.setupNowPlayingInfo(for: song, player: player)
    }

    // MARK: - 플레이어 초기화
    private func setupPlayer(url: URL, for song: Song) {
        stop()  // 기존 플레이어 정리

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                self.duration = CMTimeGetSeconds(playerItem.asset.duration)
                self.backgroundManager.setupNowPlayingInfo(for: song, player: self.player)
            }
        }

        playerObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
            self.currentTime = CMTimeGetSeconds(time)
            self.backgroundManager.updateNowPlayingPlaybackState(for: self.player, duration: self.duration)
        }
    }

    // MARK: 일시정지
    func pause() {
        player?.pause()
        isPlaying = false
        backgroundManager.updateNowPlayingPlaybackState(for: player, duration: duration)
    }
    
    // MARK: 다시 시작
    func resume() {
        player?.play()
        isPlaying = true
    }

    // MARK: 음원 종료시 메모리 해제
    func stop() {
        player?.pause()
        player = nil
        currentUrl = nil
        currentTime = 0
        duration = 0
        isPlaying = false

        if let observer = playerObserver {
            player?.removeTimeObserver(observer)
            playerObserver = nil
        }
    }

    // MARK: 실행되고 있는 URL 불러오기 
    func getCurrentUrl() -> URL? {
        return currentUrl
    }
    
    // 종료 알림 설정
    private func setupEndTimeObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    // 재생이 끝났을 때 호출되는 메서드
    @objc private func playerDidFinishPlaying() {
        player?.seek(to: .zero)  // 재생 위치를 처음으로 이동
        isPlaying = false        // 재생 상태를 false로 변경
        backgroundManager.updateNowPlayingPlaybackState(for: player, duration: duration)
    }
}
