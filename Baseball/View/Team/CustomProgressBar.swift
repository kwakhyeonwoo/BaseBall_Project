//
//  CircularProgressView.swift
//     
//
//  Created by 곽현우 on 2/6/25.
//

import SwiftUI

struct CustomProgressBar: View {
    @Binding var progress: Double  // 0.0 ~ 1.0 범위
    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width
            let adjustedProgress = max(0.0, min(progress, 1.0))  // progress 값 보정
            let circlePosition = barWidth * adjustedProgress

            ZStack(alignment: .leading) {
                // 막대 바
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)

                Rectangle()
                    .fill(Color.blue)
                    .frame(width: barWidth * adjustedProgress, height: 4)

                // 원 포인터
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .offset(x: circlePosition - 6)  // 원 크기 절반 보정
            }
            .animation(.linear(duration: 0.5), value: progress)  // 부드러운 애니메이션
        }
        .frame(height: 20)  // 전체 높이 지정
    }
}

struct MiniPlayerWithCustomProgressView: View {
    @State private var progress: Double = 0.3  // 임시로 30% 진행 상태로 설정

    var body: some View {
        VStack {
            Text("현재 재생 중인 곡")
                .font(.headline)

            CustomProgressBar(progress: $progress)

            Button(action: {
                // 진행 상태 업데이트 (테스트용)
                progress = min(1.0, progress + 0.1)
            }) {
                Text("진행 상태 증가")
            }
        }
        .padding()
    }
}
