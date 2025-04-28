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
    @State private var player: AVPlayer? = nil

    var body: some View {
        if let url = URL(string: videoURL) {
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    player = AVPlayer(url: url)
                    player?.play()
                }
                .onDisappear {
                    player?.pause()
                    player = nil // 메모리 해제까지
                }
        } else {
            Text("유효하지 않은 URL입니다.")
        }
    }
}


//#Preview {
//    myPageUploadFullView()
//}
