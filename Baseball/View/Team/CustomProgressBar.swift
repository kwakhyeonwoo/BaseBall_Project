//
//  CircularProgressView.swift
//     
//
//  Created by 곽현우 on 2/6/25.
//

import SwiftUI

struct CustomProgressBar: View {
    @Binding var progress: Double
    var teamColor: Color = .blue

    var body: some View {
        GeometryReader { geometry in
            let safeProgress = max(0, min(progress.isNaN ? 0 : progress, 1))  // NaN 방지 및 0~1 범위 제한

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 4)

                Capsule()
                    .fill(teamColor)
                    .frame(width: geometry.size.width * safeProgress, height: 4)
            }
        }
        .frame(height: 4)
    }
}
