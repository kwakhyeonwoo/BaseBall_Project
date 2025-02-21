//
//  AVPlayerBackground.swift
//     
//
//  Created by 곽현우 on 2/4/25.
//

import AVFoundation
import MediaPlayer

class AVPlayerBackgroundManager {
    
    // MARK: - 오디오 세션 설정 및 알림
    func setupAudioSessionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        
    }
    
    /// ✅ **오디오 세션 설정** (백그라운드에서도 재생 유지)
    static func configureAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            // ✅ 1. Set category first (NO INVALID OPTIONS)
            try audioSession.setCategory(.playback, mode: .default, options: [])
            
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            //✅ 2. Activate session LAST (ONLY if not already active)
            if !audioSession.isOtherAudioPlaying {
                try audioSession.setActive(true, options: [])
                print("✅ Audio session configured and activated successfully.")
            } else {
                print("⚠️ Another audio is already playing. Skipping activation.")
            }
            
            //✅ 3. Listen for route changes (e.g., Bluetooth, AirPods disconnect)
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: nil
            )
            
        } catch let error {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 제어센터 명령 설정
    func configureRemoteCommandCenter(for playerManager: AudioPlayerManager) {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        //재생
        commandCenter.playCommand.addTarget { [weak playerManager] _ in
            guard let playerManager = playerManager,
                  let currentUrl = playerManager.getCurrentUrl(),
                  let currentSong = playerManager.currentSong else { return .commandFailed }
            
            if !playerManager.isPlaying {
                playerManager.play(url: currentUrl, for: currentSong)
            }
            return .success
        }
        
        //일시정지
        commandCenter.pauseCommand.addTarget { [weak playerManager] _ in
            playerManager?.pause()
            return .success
        }
        
        //재생, 일시정지 토글
        commandCenter.togglePlayPauseCommand.addTarget { [weak playerManager] _ in
            guard let playerManager = playerManager,
                  let currentUrl = playerManager.getCurrentUrl(),
                  let currentSong = playerManager.currentSong else { return .commandFailed }
            
            if playerManager.isPlaying {
                playerManager.pause()
            } else {
                playerManager.play(url: currentUrl, for: currentSong)
            }
            return .success
        }
        
        //이전 음원
        commandCenter.previousTrackCommand.addTarget { [weak playerManager] _ in
            guard let playerManager = playerManager else { return .commandFailed }
            
            if let currentSong = playerManager.currentSong {
                playerManager.playPrevious()
                return .success
            }
            return .commandFailed
        }
        
        //다음 음원
        commandCenter.nextTrackCommand.addTarget { [weak playerManager] _ in
            guard let playerManager = playerManager else { return .commandFailed }
            
            if let currentSong = playerManager.currentSong {
                playerManager.playNext()
                return .success
            }
            return .commandFailed
        }
        
        //seek, 막대바 이동
        commandCenter.changePlaybackPositionCommand.addTarget { [weak playerManager] event in
            guard let playerManager = playerManager,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            
            print("🎵 사용자 요청 시크 위치: \(positionEvent.positionTime)초")
            playerManager.seek(to: positionEvent.positionTime)
            return .success
        }
    }
    
    // MARK: - Now Playing 정보 설정
    func setupNowPlayingInfo(for song: Song, player: AVPlayer?) {
        guard let player = player else {
            print("❌ setupNowPlayingInfo - player가 nil 상태입니다.")
            return
        }
        
        let teamImage = UIImage(named: song.teamImageName) ?? UIImage()
        let imageWithWhiteBackground = addWhiteBackground(to: teamImage)
        
        let artwork = MPMediaItemArtwork(boundsSize: imageWithWhiteBackground.size) { _ in
            return imageWithWhiteBackground
        }
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: "응원가",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
            MPMediaItemPropertyPlaybackDuration: player.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate,
            MPMediaItemPropertyArtwork: artwork
        ]
        
        //이전, 다음 음원 조작
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueIndex] = player.rate > 0 ? 1 : 0
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackQueueCount] = 1
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("✅ Now Playing 정보 업데이트됨: \(song.title), 시간: \(player.currentTime().seconds)")
    }
    
    // MARK: 실시간 업데이트 현황
    func updateNowPlayingPlaybackState(for player: AVPlayer?, duration: Double) {
        guard let player = player else { return }
        
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime().seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.currentItem?.duration.seconds ?? duration
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: 이미지를 감싸는 배경 색 변경
    private func addWhiteBackground(to image: UIImage) -> UIImage {
        let newSize = CGSize(width: image.size.width, height: image.size.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)
        UIColor.white.setFill()
        UIRectFill(CGRect(origin: .zero, size: newSize))
        
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let imageWithBackground = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        
        return imageWithBackground
    }
    
    // MARK: - 인터럽션 및 라우트 변경 처리
    @objc private func handleInterruption(notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        if type == .began {
            AudioPlayerManager.shared.pause()
        } else if type == .ended {
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               optionsValue == AVAudioSession.InterruptionOptions.shouldResume.rawValue,
               let currentUrl = AudioPlayerManager.shared.getCurrentUrl(),
               let currentSong = AudioPlayerManager.shared.currentSong {
                AudioPlayerManager.shared.play(url: currentUrl, for: currentSong)
            }
        }
    }
    
    // MARK: 오디오 경로 변경 감지
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }
        
        switch reason {
        case .oldDeviceUnavailable:
            DispatchQueue.main.async {
                if AudioPlayerManager.shared.isPlaying {
                    AudioPlayerManager.shared.player?.play()
                    print("🎧 이어폰이 제거됨 → 스피커로 전환 후 자동 재생")
                }
            }
        case .newDeviceAvailable:
            DispatchQueue.main.async {
                if AudioPlayerManager.shared.isPlaying {
                    AudioPlayerManager.shared.player?.play()
                    print("🔊 새로운 오디오 장치 연결됨 → 자동 재생")
                }
            }
        default:
            break
        }
    }
}
