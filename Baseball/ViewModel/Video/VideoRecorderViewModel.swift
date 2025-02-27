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

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            picker.sourceType = .camera
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeHigh
            picker.cameraCaptureMode = .video
        } else {
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
            if let videoURL = info[.mediaURL] as? URL {
                DispatchQueue.main.async {
                    self.parent.onVideoRecorded(videoURL)
                }
            }
            parent.presentationMode.wrappedValue.dismiss() // ✅ "Use Video" 클릭 시 즉시 닫힘
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onVideoRecorded(nil)
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
