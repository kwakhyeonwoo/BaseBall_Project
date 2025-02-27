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
    var onVideoRecorded: (URL?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // 카메라 사용 가능 여부 확인
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"] // 동영상 녹화 활성화
            picker.videoQuality = .typeHigh // 고화질 설정
            picker.cameraCaptureMode = .video
        } else {
            // 카메라가 없으면 갤러리에서 선택하도록 변경
            picker.sourceType = .photoLibrary
            picker.mediaTypes = ["public.movie"]
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoRecorderViewModel

        init(_ parent: VideoRecorderViewModel) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // 동영상 URL 가져오기
            if let videoURL = info[.mediaURL] as? URL {
                parent.onVideoRecorded(videoURL)
            } else {
                parent.onVideoRecorded(nil)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onVideoRecorded(nil)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
