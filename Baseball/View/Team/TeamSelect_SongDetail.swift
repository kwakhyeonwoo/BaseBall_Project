//
//  SwiftUIView.swift
//     
//
//  Created by 곽현우 on 1/24/25.
//

import SwiftUI

struct SongDetailView: View {
    let song: Song
    @StateObject private var playerManager = AudioPlayerManager.shared

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
            if playerManager.duration > 0 {
                ProgressView(value: playerManager.currentTime / playerManager.duration)
                    .padding()
                HStack {
                    Text("\(formatTime(playerManager.currentTime))")
                    Spacer()
                    Text("-\(formatTime(playerManager.duration - playerManager.currentTime))")
                }
            }

            // 음원 재생/일시정지 버튼
            Button(action: togglePlayPause) {
                Text(playerManager.isPlaying ? "일시정지" : "재생")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(playerManager.isPlaying ? Color.gray : Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear(perform: setupPlayer)
    }

    private func setupPlayer() {
        guard let url = URL(string: song.audioUrl) else { return }
        playerManager.play(url: url)
    }

    private func togglePlayPause() {
        if playerManager.isPlaying {
            playerManager.pause()
        } else {
            if playerManager.getCurrentUrl() == URL(string: song.audioUrl) {
                playerManager.play(url: URL(string: song.audioUrl)!)
            } else {
                setupPlayer()
            }
        }
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
