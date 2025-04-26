//
//  myPageUploadFullView.swift
//     
//
//  Created by 곽현우 on 4/24/25.
//

import SwiftUI
import AVKit

struct MyPageUploadFullView: View {
    let videoURL: String

    var body: some View {
        if let url = URL(string: videoURL) {
            VideoPlayer(player: AVPlayer(url: url))
                .edgesIgnoringSafeArea(.all)
                .onDisappear {
                    // 재생 중인 AVPlayer 중지
                    AVPlayer(url: url).pause()
                }
        } else {
            Text("유효하지 않은 URL입니다.")
        }
    }
}


//#Preview {
//    myPageUploadFullView()
//}
