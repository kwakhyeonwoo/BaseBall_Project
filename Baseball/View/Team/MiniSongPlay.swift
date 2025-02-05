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
    
    var body: some View {
        if let currentSong = playerManager.currentSong {
            VStack {
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
                    // 클릭 시 전체 재생 화면으로 이동
                    // NavigationLink 또는 직접 화면 전환
                }
            }
            .padding([.horizontal, .bottom], 10)
            .transition(.move(edge: .bottom))
            .animation(.spring())
        }
    }
}


#Preview {
    MiniPlayerView()
}
