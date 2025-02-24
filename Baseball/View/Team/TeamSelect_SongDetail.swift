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
        VStack(spacing: 20) {
            Text(viewModel.currentSong?.title ?? song.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        ForEach(lyricsLines.indices, id: \.self) { index in
                            Text(lyricsLines[index])
                                .font(.title3)
                                .fontWeight(index == activeLineIndex ? .bold : .regular)
                                .foregroundColor(index == activeLineIndex ? .green : .primary)
                                .padding(.vertical, 5)
                                .id(index)
                        }
                    }
                    .padding(.horizontal, 50)
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
                }

                Spacer()

                Button(action: { viewModel.playNext() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 30))
                        .foregroundColor(viewModel.hasNextSong ? .primary : .gray)
                }
                .disabled(!viewModel.hasNextSong)
            }
            .padding(.top, 10)
        }
        .padding()
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
            .replacingOccurrences(of: ")", with: ")\n") // 🔹 특정 구문 뒤에서 개행 추가
            .components(separatedBy: "\n") // 🔹 개행을 기준으로 분리
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } // 🔹 공백 제거
            .filter { !$0.isEmpty } // 🔹 빈 줄 제거
    }
    
    // 🔥 가사가 실제로 시작되는 타이밍을 감지하고, 줄별로 색상을 변경하는 함수
    private func updateHighlightedLyric(for time: Double) {
        guard lyricsLines.count > 0 else { return }
        
        // 🔥 가사 시작 전까지는 하이라이트하지 않음
        if time < viewModel.lyricsStartTime {
            activeLineIndex = -1
            return
        }
        
        let adjustedTime = time - viewModel.lyricsStartTime // 🔥 가사 시작 이후의 경과 시간
        let estimatedTimePerLine = viewModel.duration > 0
        ? (viewModel.duration - viewModel.lyricsStartTime) / Double(lyricsLines.count)
        : 2.7 // 기본값 2.7초 후 줄바꿈
        
        // 🔥 NaN 또는 Infinite 값 방지
        guard estimatedTimePerLine.isFinite, !estimatedTimePerLine.isNaN, estimatedTimePerLine > 0 else { return }
        
        // 🔥 현재 줄 계산 (소수점 절삭하여 int 변환)
        let newIndex = min(max(0, Int(adjustedTime / estimatedTimePerLine)), lyricsLines.count - 1)
        
        // 🔥 현재 줄이 변경될 경우만 업데이트
        if newIndex != activeLineIndex {
            activeLineIndex = newIndex
            withAnimation {
                scrollProxy?.scrollTo(newIndex, anchor: .center)
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
