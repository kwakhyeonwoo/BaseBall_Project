//
//  CircularProgressView.swift
//     
//
//  Created by 곽현우 on 2/6/25.
//

import SwiftUI

struct CustomProgressBar: View {
    @Binding var progress: Double
    @State private var isDragging = false
    let onSeek: (Double) -> Void
    let teamColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 배경 바
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)
                
                // 진행 바
                // progress가 음수거나 NaN이면 0으로 처리
                Rectangle()
                    .fill(teamColor)
                    .frame(width: max(0, min(CGFloat(progress), 1.0)) * geometry.size.width, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: progress)
                
                // 원 포인터
                Circle()
                    .fill(teamColor)
                    .frame(width: 12, height: 12)
                    .offset(x: CGFloat(progress) * geometry.size.width - 6) // 원이 막대 중앙에 위치하도록 오프셋 조정
            }
            .contentShape(Rectangle()) // 클릭 영역 확장
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDragging = true
                        // 클릭 위치에 따라 progress 업데이트
                        let newProgress = min(max(0, value.location.x / geometry.size.width), 1)
                        progress = newProgress
                        onSeek(newProgress)
                    }
                    .onEnded { value in
                        isDragging = false
                        // 드래그 종료 시 호출 - 새로운 위치로 음원 이동
                        let newProgress = min(max(0, value.location.x / geometry.size.width), 1)
//                        onSeek(newProgress)
                    }
            )
        }
        .frame(height: 20)
    }
}
