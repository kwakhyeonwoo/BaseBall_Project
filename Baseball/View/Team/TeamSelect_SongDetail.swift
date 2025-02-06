//
//  SwiftUIView.swift
//     
//
//  Created by 곽현우 on 1/24/25.
//

import SwiftUI

struct SongDetailView: View {
    let song: Song
    @Environment(\.presentationMode) var presentationMode
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

            // 음원 진행 상태 - 원형 마커 추가
            if playerManager.duration > 0 {
                CustomProgressBar(progress: .constant(playerManager.currentTime / playerManager.duration))
                    .padding()
                
                HStack {
                    Text("\(formatTime(playerManager.currentTime))")
                    Spacer()
                    Text("-\(formatTime(playerManager.duration - playerManager.currentTime))")
                }
                .padding()
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
        .onAppear(perform: setupPlayerIfNeeded)
        .onReceive(playerManager.$didFinishPlaying) { didFinish in
            if didFinish {
                // 재생이 끝났을 때 화면 닫기
                presentationMode.wrappedValue.dismiss()

                // 상태 초기화
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    playerManager.didFinishPlaying = false
                }
            }
        }
    }

    // 현재 곡과 다른 경우에만 플레이어를 새로 설정
    private func setupPlayerIfNeeded() {
        guard playerManager.getCurrentUrl() != URL(string: song.audioUrl) else {
            return  // 이미 같은 곡이 재생 중이면 건너뜀
        }

        guard let url = URL(string: song.audioUrl) else { return }
        playerManager.play(url: url, for: song)
    }

    private func togglePlayPause() {
        if playerManager.isPlaying {
            playerManager.pause()
        } else {
            // 이미 설정된 URL이 있다면, 해당 URL로 재생을 계속 진행
            if let currentUrl = playerManager.getCurrentUrl(), currentUrl == URL(string: song.audioUrl) {
                playerManager.resume()  // 이어서 재생
            } else {
                // URL이 다를 경우 새로 재생
                playerManager.play(url: URL(string: song.audioUrl)!, for: song)
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
