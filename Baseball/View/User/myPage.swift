//
//  myPage.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - MyPageView
struct MyPageView: View {
    let selectedTeam: String
    let selectedTeamImage: String

    @StateObject private var viewModel = MyPageViewModel()
    @StateObject private var playerManager = AudioPlayerManager.shared

    @State private var selectedUploadedSong: UploadedSong? = nil

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
            .sheet(item: $selectedUploadedSong) { song in
                MyPageUploadFullView(videoURL: song.videoURL)
            }
        }
    }

    // MARK: - 사용자 프로필 헤더
    private func userHeader() -> some View {
        HStack {
            Image(selectedTeamImage)
                .resizable()
                .frame(width: 32, height: 32)
                .clipShape(Circle())

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

    // MARK: - 좋아요 한 응원가 - 공식
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
                        ForEach(viewModel.likedTeamSongs, id: \ .id) { song in
                            HStack {
                                Image(selectedTeamImage)
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .padding(6)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)

                                VStack(alignment: .leading) {
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

                            Divider()
                        }
                    }
                    .padding(.vertical, 5)
                }
                .frame(height: 300)
            }
        }
    }

    // MARK: - 좋아요 한 응원가 - 업로드
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
                            VStack(spacing: 8) {
                                if let url = URL(string: song.thumbnailURL) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 100, height: 100)
                                                .clipped()
                                                .cornerRadius(8)
                                        } else {
                                            Color.gray
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(8)
                                        }
                                    }
                                } else {
                                    Color.gray
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(8)
                                }

                                Text(song.title)
                                    .font(.caption)
                                    .frame(width: 100)
                                    .lineLimit(1)
                            }
                            .onTapGesture {
                                selectedUploadedSong = song
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(height: 150)
            }
        }
    }
}


//#Preview {
//    myPage()
//}
