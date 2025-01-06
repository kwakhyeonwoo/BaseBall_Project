//
//  Calendar.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI

struct CalendarView: View {
    @StateObject private var viewModel = GameScheduleViewModel()
    @State private var selectedTeam: String? = "ssg2"
    @State private var selectedTeamImage: String? = "ssg2"
    @State private var selectedTab: String? = "경기일정" // 현재 선택된 탭
    
    var body: some View {
        VStack(spacing: 20) {
            teamHeader()
            scheduleSection()
            Spacer()
            tabView()
        }
        .padding()
        .onAppear {
            if let team = selectedTeam {
                viewModel.fetchGameSchedules(for: team)
            }
        }
    }
    
    // MARK: - 상단 선택한 팀 섹션
    func teamHeader() -> some View {
        Group {
            if let team = selectedTeam, let image = selectedTeamImage {
                HStack(spacing: 10) {
                    Image(image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    
                    Text("\(team) 일정입니다.")
                        .font(.headline)
                }
                .padding()
            } else {
                Text("팀을 선택해주세요.")
                    .font(.headline)
                    .padding()
            }
        }
    }
    
    // MARK: - 경기 일정 섹션
    func scheduleSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("오늘의 경기 일정")
                .font(.title2)
                .bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let team = selectedTeam {
                Text("\(team)의 경기 일정")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.top)
            } else {
                Text("선택된 팀이 없습니다.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            // 실제 경기 일정 목록
            ForEach(viewModel.gameSchedules, id: \.gameDate) { game in
                VStack(alignment: .leading) {
                    Text("\(game.gameDate)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("대상팀: \(game.opponent)")
                        .font(.body)
                        .foregroundColor(.black)
                }
                .padding(.top, 5)
            }
            
            Text("다른 팀 금일 경기 일정")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    // MARK: - 하단 탭 메뉴
    func tabView() -> some View {
        HStack(spacing: 0) {
            tabButton(label: "경기일정", icon: "calendar", tag: "경기일정")
            tabButton(label: "공식 응원가", icon: "music.note", tag: "공식 응원가")
            tabButton(label: "응원가 업로드", icon: "arrow.up.circle", tag: "응원가 업로드")
            tabButton(label: "보관함", icon: "tray.full", tag: "보관함")
        }
        .frame(height: 100) // HStack 안의 모든 버튼 높이 동일
    }
    
    // MARK: - 공통 버튼 뷰
    func tabButton(label: String, icon: String, tag: String) -> some View {
        Button(action: {
            selectedTab = tag // 선택된 버튼 업데이트
        }) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 30))
                    .foregroundColor(selectedTab == tag ? .gray : .black) // 선택 상태에 따라 색상 변경
                Text(label)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(selectedTab == tag ? .gray : .black) // 선택 상태에 따라 색상 변경
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
            .background(Color.clear)
        }
        .buttonStyle(PlainButtonStyle()) // 기본 버튼 스타일 제거
    }
}



#Preview {
    CalendarView()
}

//calendar,music.note,arrow.up.circle,tray.full
