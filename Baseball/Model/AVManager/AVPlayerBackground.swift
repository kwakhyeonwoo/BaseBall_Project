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
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleRouteChange), name: AVAudioSession.routeChangeNotification, object: nil)
    }

    static func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()

            // ✅ 기존 세션을 안전하게 비활성화
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)

            // ✅ iOS 16+에서는 .defaultToSpeaker 옵션 추가 필요 (스피커로 재생 설정)
            try audioSession.setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .defaultToSpeaker]
            )

            // ✅ AVAudioSession 활성화
            try audioSession.setActive(true)

            print("✅ Audio session configured and activated for playback.")
        } catch let error as NSError {
            print("❌ Failed to configure audio session: \(error), \(error.userInfo)")
        }
    }

    // MARK: - 제어센터 명령 설정
    func configureRemoteCommandCenter(for playerManager: AudioPlayerManager) {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak playerManager] _ in
            guard let playerManager = playerManager, let currentUrl = playerManager.getCurrentUrl(), let currentSong = playerManager.currentSong else { return .commandFailed }

            if !playerManager.isPlaying {
                playerManager.play(url: currentUrl, for: currentSong)
            }
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak playerManager] _ in
            playerManager?.pause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak playerManager] _ in
            guard let playerManager = playerManager, let currentUrl = playerManager.getCurrentUrl(), let currentSong = playerManager.currentSong else { return .commandFailed }

            if playerManager.isPlaying {
                playerManager.pause()
            } else {
                playerManager.play(url: currentUrl, for: currentSong)
            }
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

        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: "응원가",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
            MPMediaItemPropertyPlaybackDuration: player.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate,
            MPMediaItemPropertyArtwork: artwork
        ]

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

    @objc private func handleRouteChange(notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            AudioPlayerManager.shared.pause()
        }
    }
    
    // MARK: 이미지를 감싸는 배경 색 변경
    private func addWhiteBackground(to image: UIImage) -> UIImage {
        let newSize = CGSize(width: image.size.width, height: image.size.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, true, 0.0)  // 불투명(true)로 설정하여 흰 배경 생성
        UIColor.white.setFill()  // 배경색을 흰색으로 설정
        UIRectFill(CGRect(origin: .zero, size: newSize))  // 흰색으로 채우기

        image.draw(in: CGRect(origin: .zero, size: newSize))  // 원본 이미지를 그리기
        let imageWithBackground = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()

        return imageWithBackground
    }
}

