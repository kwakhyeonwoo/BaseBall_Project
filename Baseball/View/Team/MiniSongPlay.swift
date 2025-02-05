//
//  MiniSongPlay.swift
//     
//
//  Created by 곽현우 on 2/5/25.
//

import SwiftUI
import AVKit

struct MiniPlayerView: View {
    @StateObject private var playerManager = AudioPlayerManager.shared
    @State private var isShowingDetail = false  // 상세 화면 표시 여부

    var body: some View {
        VStack {
            if let currentSong = playerManager.currentSong {
                HStack {
                    // 현재 곡 정보
                    Text(currentSong.title)
                        .font(.headline)
                        .lineLimit(1)

                    Spacer()

                    // 재생/일시정지 버튼
                    Button(action: {
                        if playerManager.isPlaying {
                            playerManager.pause()
                        } else {
                            if let currentUrl = playerManager.getCurrentUrl() {
                                playerManager.play(url: currentUrl, for: currentSong)
                            }
                        }
                    }) {
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(12)
                .shadow(radius: 2)
                .onTapGesture {
                    // 화면 전환만 수행 (음원 상태 변경 없음)
                    isShowingDetail = true
                }
                .sheet(isPresented: $isShowingDetail) {
                    SongDetailView(song: currentSong)  // 밑에서 올라오는 상세 화면
                }
            }
        }
        .padding([.horizontal, .bottom], 10)
        .transition(.move(edge: .bottom))
        .animation(.spring(), value: playerManager.isPlaying)
    }
}
