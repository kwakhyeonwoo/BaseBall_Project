//
//  Calendar.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = GameScheduleViewModel()
    let selectedTeam: String
    let selectedTeamImage: String
    @State private var selectedTab: String? = "경기일정"
    @State private var showVideoRecorder: Bool = false
    @State private var navigateToSongView: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                teamHeader()
                Spacer()
                tabView()
            }
            .padding()
            .onAppear {
                viewModel.fetchGameSchedules(for: selectedTeam)
            }
            .sheet(isPresented: $showVideoRecorder) {
                VideoRecorderViewModel { videoURL in
                    if let videoURL = videoURL {
                        print("녹화된 동영상 경로: \(videoURL)")
                    } else {
                        print("녹화가 취소되었습니다.")
                    }
                }
            }
            .background(
                NavigationLink(
                    destination: TeamSelect_SongView(selectedTeam: selectedTeam, selectedTeamImage: selectedTeamImage),
                    isActive: $navigateToSongView
                ) {
                    EmptyView()
                }
                .hidden()
            )
        }
    }

    func teamHeader() -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(selectedTeamImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .shadow(radius: 5)
                
                Text("팀이 선택되었습니다")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
        }
        .padding()
    }

    func tabView() -> some View {
        HStack(spacing: 0) {
            tabButton(label: "경기일정", icon: "calendar", tag: "경기일정")
            tabButton(label: "공식 응원가", icon: "music.note", tag: "공식 응원가", isMultiline: true)
            tabButton(label: "응원가 업로드", icon: "arrow.up.circle", tag: "응원가 업로드", isMultiline: true)
            tabButton(label: "응원가 확인하기", icon: "play.rectangle", tag: "응원가 확인하기", isMultiline: true)
            tabButton(label: "보관함", icon: "tray.full", tag: "보관함")
        }
        .frame(height: 80)
        .background(Color.white)
        .padding(.horizontal, 10)
    }

    func tabButton(label: String, icon: String, tag: String, isMultiline: Bool = false) -> some View {
        Button(action: {
            selectedTab = tag
            if tag == "응원가 업로드" {
                showVideoRecorder = true
            } else if tag == "공식 응원가" {
                navigateToSongView = true
            }
        }) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: selectedTab == tag ? 26 : 24, weight: selectedTab == tag ? .bold : .regular))
                    .foregroundColor(.black)
                    .frame(height: 24) // 아이콘 높이 통일
                Text(label)
                    .font(.footnote)
                    .fontWeight(selectedTab == tag ? .bold : .regular)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(height: isMultiline ? 30 : 14) // 텍스트 높이 통일
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical, 5) // 전체 높이 균형 맞추기
        }
        .buttonStyle(PlainButtonStyle())
    }
}

//#Preview {
//    CalendarView(selectedTeam: , selectedTeamImage: <#String#>)
//}

//calendar,music.note,arrow.up.circle,tray.full
