//
//  SwiftUIView.swift
//     
//
//  Created by 곽현우 on 1/24/25.
//

import SwiftUI
import AVKit

struct SongDetailView: View {
    let song: Song
    @State private var player: AVPlayer? = nil
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            // 제목
            Text(song.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()
            
            // 가사
            ScrollView {
                Text(song.lyrics)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(10)
            }

            // 음원 진행 상태
            if duration > 0 {
                ProgressView(value: currentTime / duration)
                    .padding()
                HStack {
                    Text("\(formatTime(currentTime))")
                    Spacer()
                    Text("-\(formatTime(duration - currentTime))")
                }
            }

            // 음원 재생 버튼
            Button(action: {
                if let player = player {
                    player.rate == 0 ? player.play() : player.pause()
                } else {
                    playSong()
                }
            }) {
                Text(player?.rate == 0 ? "재생" : "일시정지")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(player?.rate == 0 ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }

    // MARK: - Audio Player
    private func setupPlayer() {
        guard let url = URL(string: song.audioUrl) else { return }
        player = AVPlayer(url: url)
        let asset = AVURLAsset(url: url)
        duration = CMTimeGetSeconds(asset.duration)
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let currentTime = player?.currentTime() else { return }
            self.currentTime = CMTimeGetSeconds(currentTime)
        }
    }

    private func playSong() {
        player?.play()
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

//#Preview {
//    SongDetailView(song: <#Song#>)
//}
