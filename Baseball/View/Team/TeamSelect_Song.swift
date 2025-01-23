//
//  TeamSelect_Song.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI
import AVKit

struct TeamSelect_SongView: View {
    let team: String
    @StateObject private var viewModel = TeamSelectSongViewModel()
    @State private var player: AVPlayer? = nil

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                loadingView()
            } else if !viewModel.songs.isEmpty {
                songsListView()
            } else {
                errorView(message: "응원가 정보를 불러올 수 없습니다.")
            }
        }
        .onAppear {
            print("Fetching songs for selected team: \(team)") // 팀 이름 출력
            viewModel.fetchSongs(for: team)
        }
        .navigationTitle("\(team) 응원가")
    }

    // MARK: - Loading View
    private func loadingView() -> some View {
        ProgressView("로딩 중...")
            .padding()
    }

    // MARK: - Songs List View
    private func songsListView() -> some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(viewModel.songs) { song in
                    songCard(song: song)
                }
            }
            .padding()
        }
    }

    // MARK: - Song Card
    private func songCard(song: Song) -> some View {
        VStack(spacing: 10) {
            Text(song.title)
                .font(.title)
                .fontWeight(.bold)

            Button(action: {
                playSong(url: song.audioUrl)
            }) {
                Text("응원가 재생")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }

            Text("가사")
                .font(.headline)
                .padding(.top)

            Text(song.lyrics)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
        }
        .padding()
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        Text(message)
            .foregroundColor(.red)
    }

    // MARK: - Play Song
    private func playSong(url: String) {
        guard let audioURL = URL(string: url) else {
            print("Invalid URL: \(url)")
            return
        }
        player = AVPlayer(url: audioURL)
        player?.play()
    }
}

#Preview {
    TeamSelect_SongView(team: "SSG")
}
