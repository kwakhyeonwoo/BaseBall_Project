//
//  myPageThumbnail.swift
//     
//
//  Created by 곽현우 on 4/24/25.
//

//import AVFoundation
//import UIKit
//
////썸네일 생성 
//func generateThumbnailImage(from videoURL: URL, completion: @escaping (UIImage?) -> Void) {
//    let asset = AVAsset(url: videoURL)
//    let generator = AVAssetImageGenerator(asset: asset)
//    generator.appliesPreferredTrackTransform = true
//    let time = CMTime(seconds: 1, preferredTimescale: 600)
//
//    DispatchQueue.global(qos: .userInitiated).async {
//        do {
//            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
//            let image = UIImage(cgImage: cgImage)
//            DispatchQueue.main.async {
//                completion(image)
//            }
//        } catch {
//            print("❌ 썸네일 생성 실패: \(error.localizedDescription)")
//            DispatchQueue.main.async {
//                completion(nil)
//            }
//        }
//    }
//}
//
////썸네일 JPEG로 변환 후 Storage에 업로드
//func uploadThumbnailImage(_ image: UIImage, uuid: String, completion: @escaping (URL?) -> Void) {
//    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//        completion(nil)
//        return
//    }
//
//    let storageRef = Storage.storage().reference().child("hlsVideos/\(uuid)/thumbnail.jpg")
//
//    storageRef.putData(imageData, metadata: nil) { metadata, error in
//        if let error = error {
//            print("❌ 썸네일 업로드 실패: \(error.localizedDescription)")
//            completion(nil)
//            return
//        }
//
//        storageRef.downloadURL { url, error in
//            if let url = url {
//                completion(url)
//            } else {
//                print("❌ 썸네일 URL 획득 실패")
//                completion(nil)
//            }
//        }
//    }
//}
