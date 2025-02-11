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
                // 배경 및 막대
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)

                Rectangle()
                    .fill(teamColor)
                    .frame(width: max(0, CGFloat(progress) * geometry.size.width), height: 4)

                Circle()
                    .fill(teamColor)
                    .frame(width: 12, height: 12)
                    .offset(x: max(0, min(CGFloat(progress), 1.0) * geometry.size.width - 6))
            }
            .frame(height: 20)
            .contentShape(Rectangle())  // 전체 진행 바에 대한 터치 영역 설정
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let newProgress = max(0, min(value.location.x / geometry.size.width, 1))
                        progress = newProgress
                        onSeek(newProgress)
                    }
            )
            .frame(height: 20)
            .onTapGesture { location in
                let tapLocation = location.x / geometry.size.width
                progress = max(0, min(tapLocation, 1))
                onSeek(progress)
            }
        }
    }
}
