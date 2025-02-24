//
//  TeamSelect.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI

struct TeamSelect: View {
    let teams = [
        "Doosan", "Hanwha", "Kiwoom", "Kt", "LG",
        "Lotte", "NC", "Samsung", "SSG", "KIA"
    ]
    
    @State private var selectedTeam: String? = nil // 선택된 팀을 추적하는 상태 변수
    @State private var isAnimating: Bool = false // 애니메이션 상태 변수
    @State private var navigateToCalendar: Bool = false // Calendar로 이동 여부
    
    var body: some View {
        NavigationStack {
            VStack {
                teamSelectionInstructions()
                
                teamGrid()
                
                teamSelectionButton()
                
                // NavigationLink로 Calendar로 이동
                NavigationLink(
                    destination: CalendarView(
                        selectedTeam: selectedTeam ?? "",
                        selectedTeamImage: selectedTeam ?? ""
                    ),
                    isActive: $navigateToCalendar
                ) {
                    EmptyView()
                }
            }
            .padding()
        }
    }
    
    // MARK: - 선택 안내 텍스트
    func teamSelectionInstructions() -> some View {
        Text("응원하실 팀을 선택해주세요")
            .foregroundStyle(.gray)
            .padding(.bottom, 20)
    }
    
    // MARK: - 팀 이미지 그리드
    func teamGrid() -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 50), count: 2), spacing: 30) {
            ForEach(teams, id: \.self) { team in
                teamImageView(team: team)
            }
        }
        .padding()
    }
    
    // MARK: - 팀 이미지 뷰
    func teamImageView(team: String) -> some View {
        VStack {
            Image(team)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 90)
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                // 테두리
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(selectedTeam == team ? Color.blue : Color.gray, lineWidth: 2)
                )
                .opacity(selectedTeam == team ? 1 : 0.5) // 선택된 팀만 원본 색상 보이게
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTeam = team // 클릭된 팀을 추적
                    }
                }
        }
    }
    
    // MARK: - 팀 선택 완료 버튼
    func teamSelectionButton() -> some View {
        Button(action: {
            print("\(selectedTeam ?? "") 팀 선택됨")
            navigateToCalendar = true // Calendar로 이동
        }) {
            Text("팀 선택 완료")
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedTeam != nil ? Color.blue : Color.gray) // 팀이 선택되면 파란색, 아니면 회색
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: selectedTeam != nil ? .blue.opacity(0.3) : .gray.opacity(0.3), radius: 5, x: 0, y: 2)
                .padding(.top, 20)
        }
        .disabled(selectedTeam == nil) // 팀이 선택되지 않으면 버튼 비활성화
    }
}

#Preview {
    TeamSelect()
}
