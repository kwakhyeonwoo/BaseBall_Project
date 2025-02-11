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
                // 배경 막대
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)

                // 팀 컬러 막대
                Rectangle()
                    .fill(teamColor)
                    .frame(width: max(0, CGFloat(progress) * geometry.size.width), height: 4)

                // 원 포인터
                Circle()
                    .fill(teamColor)
                    .frame(width: 12, height: 12)  // 원 포인터 크기
                    .offset(x: max(0, CGFloat(progress) * geometry.size.width - 6))
//                    .contentShape(Rectangle().inset(by: -20))  // 터치 가능 영역 확장
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDragging = true
                                let newProgress = max(0, min(value.location.x / geometry.size.width, 1))
                                progress = newProgress
                                onSeek(newProgress)
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
            }
            .frame(height: 20)
            .onTapGesture { location in
                let tapLocation = location.x / geometry.size.width
                progress = max(0, min(tapLocation, 1))
                onSeek(progress)
            }
        }
    }
}
