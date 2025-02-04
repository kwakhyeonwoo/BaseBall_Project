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
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
            print("Audio session configured for playback.")
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
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
        guard let player = player else { return }
        
        let nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime().seconds,
            MPMediaItemPropertyPlaybackDuration: player.currentItem?.duration.seconds ?? 0,
            MPNowPlayingInfoPropertyPlaybackRate: player.rate
        ]

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

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
}

