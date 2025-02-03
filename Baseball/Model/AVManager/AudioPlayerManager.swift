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
    private var currentSong: Song?

    init() {
        setupAudioSessionNotifications()
        configureRemoteCommandCenter()
    }

    // MARK: - 오디오 세션 노티피케이션 설정
    private func setupAudioSessionNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }

    // MARK: - 인터럽션 처리
    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .began {
            pause()
        } else if type == .ended {
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               optionsValue == AVAudioSession.InterruptionOptions.shouldResume.rawValue,
               let currentUrl = getCurrentUrl(),
               let currentSong = currentSong {  // currentSong 옵셔널 바인딩 추가
                play(url: currentUrl, for: currentSong)
            }
        }
    }

    // MARK: - 라우트 변경 처리 (예: 이어폰 제거 시)
    @objc private func handleRouteChange(notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            pause()
        }
    }

    // MARK: - 제어 센터 명령 설정
    private func configureRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self, let currentUrl = self.currentUrl, let currentSong = self.currentSong else {
                return .commandFailed
            }
            self.play(url: currentUrl, for: currentSong)
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            if self.isPlaying {
                self.pause()
            } else if let currentUrl = self.currentUrl, let currentSong = self.currentSong {
                self.play(url: currentUrl, for: currentSong)
            }
            return .success
        }
    }

    // MARK: - 재생 메서드
    func play(url: URL, for song: Song) {
        if currentUrl != url {
            setupPlayer(url: url)
            currentUrl = url
        }

        player?.play()
        isPlaying = true

        // Now Playing 정보 업데이트
        setupNowPlayingInfo(for: song)
    }


    // MARK: - 플레이어 초기화
    private func setupPlayer(url: URL) {
        stop()  // 기존 플레이어 정리

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // 총 재생 시간 가져오기
        playerItem.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                self.duration = CMTimeGetSeconds(playerItem.asset.duration)
            }
        }

        // 시간 업데이트 옵저버 추가
        playerObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { time in
            self.currentTime = CMTimeGetSeconds(time)
            self.updateNowPlayingPlaybackState()  // Now Playing 정보 갱신
        }
    }

    // MARK: - 일시 정지
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingPlaybackState()  // 재생 상태 변경 시 Now Playing 정보 업데이트
    }

    // MARK: - 현재 URL 반환
    func getCurrentUrl() -> URL? {
        return currentUrl
    }

    // MARK: - 정지 및 메모리 해제
    func stop() {
        player?.pause()
        player = nil
        currentUrl = nil
        currentTime = 0
        duration = 0
        isPlaying = false

        // 옵저버 해제
        if let observer = playerObserver {
            player?.removeTimeObserver(observer)
            playerObserver = nil
        }
    }

    // MARK: - 오디오 세션 설정
    static func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("Audio session configured for playback.")
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - Now Playing 정보 설정
    func setupNowPlayingInfo(for song: Song) {
        guard let player = player else { return }

        print("Setting Now Playing info for song: \(song.title)")
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
            MPMediaItemPropertyPlaybackDuration: player.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func updateNowPlayingPlaybackState() {
        guard let player = player else { return }

        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

}
