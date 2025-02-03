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

    init(){
        setupAudioSessionNotifications()
        configureRemoteCommandCenter()
    }
    // 오디오 세션 노티피케이션 설정
    private func setupAudioSessionNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }
    
    // 인터럽션 처리
    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            pause()
        } else if type == .ended {
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               optionsValue == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
                if let currentUrl = getCurrentUrl() {
                    play(url: currentUrl)
                }
            }
        }
    }
    
    // 오디오 라우트 변경 처리 (예: 이어폰 연결 해제 시)
    @objc private func handleRouteChange(notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        if reason == .oldDeviceUnavailable {
            pause()  // 이어폰이 제거되면 일시정지
        }
    }
    
    private func configureRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.play(url: self?.currentUrl ?? URL(string: "")!)
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] event in
            if self?.isPlaying == true {
                self?.pause()
            } else {
                self?.play(url: self?.currentUrl ?? URL(string: "")!)
            }
            return .success
        }
    }

    
    // URL을 통해 재생
    func play(url: URL) {
        if currentUrl != url {
            setupPlayer(url: url)
            currentUrl = url
        }

        player?.play()
        isPlaying = true

        // Now Playing Info 업데이트
        setupNowPlayingInfo(for: Song(id: "", title: "Now Playing", audioUrl: url.absoluteString, lyrics: ""), player: player)
    }


    // 플레이어 초기화
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
        }
    }

    // 일시 정지
    func pause() {
        player?.pause()
        isPlaying = false
    }

    // 현재 URL 반환
    func getCurrentUrl() -> URL? {
        return currentUrl
    }

    // 정지 및 메모리 해제, 메모리 관리
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
    
    // 백그라운드에서 음원 출혁
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
    
    //iOS 제어센터에서 음원 재생바 출력
    func setupNowPlayingInfo(for song: Song, player: AVPlayer?) {
        guard let player = player else { return }

        // 재생 상태 및 기본 정보 설정
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
            MPMediaItemPropertyPlaybackDuration: player.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }}
