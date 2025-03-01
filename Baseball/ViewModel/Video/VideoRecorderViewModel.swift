//
//  VideoRecorderViewModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/6/25.
//

import SwiftUI
import UIKit

struct VideoRecorderViewModel: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    var onRecordingComplete: (URL?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        picker.cameraCaptureMode = .video

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoRecorderViewModel

        init(_ parent: VideoRecorderViewModel) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let videoURL = info[.mediaURL] as? URL {
                print("🎬 녹화된 동영상: \(videoURL.absoluteString)")
                DispatchQueue.main.async {
                    print("✅ 비디오 녹화 완료: \(videoURL.absoluteString)")
                    self.parent.onRecordingComplete(videoURL)
                }
            } else {
                DispatchQueue.main.async {
                    print("❌ 녹화된 비디오를 찾을 수 없음")
                    self.parent.onRecordingComplete(nil)
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            print("❌ 녹화가 취소되었습니다.")
            parent.onRecordingComplete(nil)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
