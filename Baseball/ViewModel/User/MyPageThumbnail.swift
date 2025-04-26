//
//  myPageThumbnail.swift
//     
//
//  Created by 곽현우 on 4/24/25.
//

import AVFoundation
import UIKit

func generateThumbnail(from url: URL, completion: @escaping (UIImage?) -> Void) {
    let asset = AVAsset(url: url)
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true

    let time = CMTime(seconds: 1, preferredTimescale: 60)
    imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { _, cgImage, _, _, error in
        if let cgImage = cgImage {
            let uiImage = UIImage(cgImage: cgImage)
            DispatchQueue.main.async {
                completion(uiImage)
            }
        } else {
            print("❌ 썸네일 생성 실패: \(error?.localizedDescription ?? "Unknown error")")
            DispatchQueue.main.async {
                completion(nil)
            }
        }
    }
}

