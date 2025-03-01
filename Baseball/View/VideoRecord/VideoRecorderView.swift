//
//  VideoRecorderView.swift
//     
//
//  Created by 곽현우 on 3/1/25.
//

import SwiftUI
import AVFoundation

struct VideoRecorderView: View {
    @State private var showRecorder = false
    @State private var recordedVideoURL: URL?

    var body: some View {
        VStack {
            Button("응원가 업로드") {
                showRecorder = true
            }
            .sheet(isPresented: $showRecorder) {
                VideoRecorderViewModel { videoURL in
                    DispatchQueue.main.async {
                        if let videoURL = videoURL {
                            print("🎬 녹화된 동영상: \(videoURL)")
                            recordedVideoURL = videoURL
                        } else {
                            print("❌ 녹화가 취소되었습니다.")
                        }
                    }
                }
            }

            if let videoURL = recordedVideoURL {
                Text("녹화된 파일: \(videoURL.absoluteString)")
            }
        }
    }
}
