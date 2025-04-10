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

    @StateObject private var viewModel = MyPageViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // 사용자 정보 헤더
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
                            // 탈퇴 로직 추가
                        }
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Divider().padding(.horizontal, 20)

                    // 좋아요 한 응원가 섹션
                    VStack(alignment: .leading, spacing: 8) {
                        Text("좋아요 한 응원가")
                            .font(.headline)
                            .padding(.horizontal, 20)

                        // 👉 여기에 좋아요한 응원가 리스트 들어갈 예정
                        // ScrollView로 대체될 예정
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.likedSongs) { song in
                                    VStack(alignment: .leading) {
                                        Image(systemName: "music.note.list")
                                            .resizable()
                                            .frame(width: 80, height: 80)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                        
                                        Text(song.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                            .frame(width: 80, alignment: .leading)
                                    }
                                    .padding(.vertical, 5)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .frame(height: 120)
                    }
                    Divider()
                    Spacer()

                    // 업로드한 응원가 섹션
                    VStack(alignment: .leading, spacing: 8) {
                        Text("업로드 한 응원가")
                            .font(.headline)
                            .padding(.horizontal, 20)

                        // 👉 여기에 업로드한 응원가 리스트 들어갈 예정
                        // ScrollView로 대체될 예정
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 120)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }

                    Spacer()
                }
            }
            .navigationTitle("보관함")
            .onAppear {
                viewModel.fetchNickname()
                viewModel.fetchLikedSongs()
            }
        }
    }
}


//#Preview {
//    myPage()
//}
