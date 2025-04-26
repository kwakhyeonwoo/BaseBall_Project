//
//  myPage.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI

struct MyPageView: View {
    let selectedTeam: String
    let selectedTeamImage: String
    @State private var selectedVideoURL: String?
    @State private var showPlayer = false
    @StateObject private var viewModel = MyPageViewModel()
    @StateObject private var playerManager = AudioPlayerManager.shared

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 24) {
                    userHeader()
                    Divider().padding(.horizontal, 20)
                    likedTeamSongSection()
                    Divider().padding(.horizontal, 20)
                    likedUploadedSongSection()
                    Spacer(minLength: 40)
                }

                if playerManager.currentSong != nil {
                    MiniPlayerView(selectedTeam: selectedTeam)
                        .padding(.bottom, 10)
                        .transition(.move(edge: .bottom))
                        .animation(.spring(), value: playerManager.currentSong)
                }
            }
            .navigationTitle("보관함")
            .onAppear {
                viewModel.fetchNickname()
                viewModel.fetchLikedTeamSongs(for: selectedTeam)
                viewModel.fetchLikedUploadedSongs()
            }
            .sheet(isPresented: $showPlayer) {
                if let url = selectedVideoURL {
                    MyPageUploadFullView(videoURL: url)
                }
            }
        }
    }

    private func userHeader() -> some View {
        HStack {
            Image(selectedTeamImage)
                .resizable()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .scaledToFit()

            Text(viewModel.nickname.isEmpty ? "닉네임 불러오는 중..." : viewModel.nickname)
                .font(.title2)
                .bold()

            Spacer()

            Button("로그아웃") {
                // 로그아웃 처리
            }
            .foregroundColor(.red)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    private func likedTeamSongSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("좋아요 한 응원가 - 응원가")
                .font(.headline)
                .padding(.horizontal, 20)

            if viewModel.likedTeamSongs.isEmpty {
                Text("좋아요한 응원가가 없습니다.")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(Array(viewModel.likedTeamSongs.enumerated()), id: \.element.id) { index, song in
                            VStack(spacing: 8) {
                                HStack {
                                    Image(selectedTeamImage)
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                        .padding(6)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(song.title)
                                            .font(.headline)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .onTapGesture {
                                    if let url = URL(string: song.audioUrl) {
                                        playerManager.play(url: url, for: song)
                                    }
                                }

                                if index < viewModel.likedTeamSongs.count - 1 {
                                    Divider()
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                }
                .frame(height: 300)
            }
        }
    }

    private func likedUploadedSongSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("좋아요 한 응원가 - 업로드")
                .font(.headline)
                .padding(.horizontal, 20)

            if viewModel.likedUploadedSongs.isEmpty {
                Text("좋아요한 응원가가 없습니다.")
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.likedUploadedSongs, id: \.id) { song in
                            VStack {
                                if let thumbnail = viewModel.thumbnailCache[song.videoURL] {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(height: 100)
                                } else {
                                    Color.gray
                                        .frame(height: 100)
                                        .onAppear {
                                            viewModel.loadThumbnail(for: song)
                                        }
                                }

                                Text(song.title)
                                    .font(.caption)
                            }
                            .onTapGesture {
                                selectedVideoURL = song.videoURL
                                showPlayer = true
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 120)
            }
        }
    }
}


//#Preview {
//    myPage()
//}
