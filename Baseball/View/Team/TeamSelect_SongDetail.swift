//
//  SwiftUIView.swift
//
//
//  Created by 곽현우 on 1/24/25.
//

import SwiftUI
import AVKit
import Combine

struct SongDetailView: View {
    let song: Song
    let selectedTeam: String
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = SongDetailViewModel()

    @State private var lyricsLines: [String] = [] // 줄 단위 가사 저장
    @State private var activeLineIndex: Int = -1 // 현재 하이라이트된 줄 (초기값 -1)
    @State private var scrollProxy: ScrollViewProxy? = nil

    var body: some View {
        ZStack {
            // ✅ 배경에 팀 로고 추가
            Image("\(selectedTeam)") // Assets에서 로고 이미지 불러오기
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250) // 로고 크기 조절
                .opacity(0.2) // 투명도 20% 적용
                .offset(y: -30) // 위치 조정 (필요 시 수정 가능)
            
            VStack(spacing: 20) {
                Text(viewModel.currentSong?.title ?? song.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(lyricsLines.indices, id: \.self) { index in
                                Text(lyricsLines[index])
                                    .font(.title2)
                                    .fontWeight(index == activeLineIndex ? .bold : .regular)
                                    .foregroundColor(index == activeLineIndex ? .green : .primary)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .id(index)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .onAppear { scrollProxy = proxy }
                }
                
                if viewModel.duration > 0 {
                    CustomProgressBar(
                        progress: $viewModel.progress,
                        onSeek: { newProgress in
                            let newTime = newProgress * max(1, viewModel.duration)
                            viewModel.seek(to: newTime)
                        },
                        teamColor: TeamColorModel.shared.getColor(for: selectedTeam)
                    )
                    .frame(height: 8)
                    .padding(.horizontal, 20)
                    .padding(.top, 5)
                    
                    HStack {
                        Text(formatTime(viewModel.currentTime))
                        Spacer()
                        Text("-" + formatTime(viewModel.duration - viewModel.currentTime))
                    }
                    .padding()
                }
                
                HStack {
                    Button(action: { viewModel.playPrevious() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 30))
                            .foregroundColor(viewModel.hasPrevSong ? .primary : .gray)
                            .frame(width: 50, height: 50)
                    }
                    .disabled(!viewModel.hasPrevSong)
                    
                    Spacer()
                    
                    Button(action: { viewModel.togglePlayPause(for: song) }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .padding()
                            .background(viewModel.isPlaying ? Color.gray : Color.blue)
                            .clipShape(Circle())
                            .frame(width: 70, height: 70)
                    }
                    
                    Spacer()
                    
                    Button(action: { viewModel.playNext() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 30))
                            .foregroundColor(viewModel.hasNextSong ? .primary : .gray)
                            .frame(width: 50, height: 50)
                    }
                    .disabled(!viewModel.hasNextSong)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white) // 배경색 추가 (필요하면 제거 가능)
        .edgesIgnoringSafeArea(.all) // 전체 화면 적용
        .onAppear {
            updateLyrics(for: song)
            if viewModel.currentSong?.id != song.id {
                viewModel.setupPlayerIfNeeded(for: song)
            }
            lyricsLines = formatLyrics(song.lyrics)
            viewModel.lyricsStartTime = song.lyricsStartTime
            AVPlayerBackgroundManager.configureAudioSession()
        }
        .onReceive(viewModel.$currentSong) { newSong in
            if let newSong = newSong {
                updateLyrics(for: newSong) // ✅ 곡 변경 시 가사 갱신
            }
        }
        .onReceive(viewModel.$currentTime) { currentTime in
            updateHighlightedLyric(for: currentTime)
        }
    }

    /// 🔹 새로운 곡이 로드될 때 가사 업데이트
    private func updateLyrics(for song: Song) {
        lyricsLines = formatLyrics(song.lyrics) // ✅ 줄 단위 변환
        viewModel.lyricsStartTime = song.lyricsStartTime
        activeLineIndex = -1 // ✅ 곡이 바뀌면 초기화
    }

    
    /// 🔹 가사를 줄 단위로 변환하는 함수
    private func formatLyrics(_ lyrics: String) -> [String] {
        return lyrics
            .replacingOccurrences(of: "\\n\\n", with: "\n\n")
            .components(separatedBy: "\n\n") // 🔹 개행을 기준으로 분리
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } // 🔹 공백 제거
            .filter { !$0.isEmpty } // 🔹 빈 줄 제거
    }
    
    // 🔥 가사가 실제로 시작되는 타이밍을 감지하고, 줄별로 색상을 변경하는 함수
    private func updateHighlightedLyric(for time: Double) {
        var timestamps = viewModel.timestamps // ✅ Firestore에서 가져온 timestamps

        // 🔹 timestamps 배열과 lyricsLines 배열 개수가 다르면 보정
        if timestamps.count != lyricsLines.count - 1 {
            print("⚠️ timestamps(\(timestamps.count))와 lyricsLines(\(lyricsLines.count)) 개수가 다름 → 자동 조정")
            while timestamps.count < lyricsLines.count - 1 { timestamps.append(timestamps.last ?? viewModel.lyricsStartTime) }
            while timestamps.count > lyricsLines.count - 1 { timestamps.removeLast() }
        }

        // 🔹 가사 시작 전이면 하이라이트 없음
        if time < viewModel.lyricsStartTime {
            activeLineIndex = -1
            return
        }

        let adjustedTime = time // ✅ 전체 시간을 사용하여 timestamps 매칭

        // ✅ 첫 번째 가사는 lyricsStartTime 기준으로 처리
        if timestamps.isEmpty || adjustedTime < timestamps[0] {
            if activeLineIndex != 0 {
                activeLineIndex = 0
                withAnimation {
                    scrollProxy?.scrollTo(0, anchor: .center)
                }
            }
            return
        }

        // ✅ timestamps에서 현재 시간과 가장 가까운 값을 찾기
        if let newIndex = timestamps.lastIndex(where: { $0 <= adjustedTime }) {
            let highlightIndex = min(newIndex + 1, lyricsLines.count - 1) // ✅ 첫 번째 가사는 timestamps에 없으므로 +1 적용

            if highlightIndex != activeLineIndex {
                activeLineIndex = highlightIndex
                withAnimation {
                    scrollProxy?.scrollTo(highlightIndex, anchor: .center)
                }
            }
        } else {
            // 🔹 마지막 줄까지 도달한 경우 마지막 줄 유지
            activeLineIndex = lyricsLines.count - 1
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
