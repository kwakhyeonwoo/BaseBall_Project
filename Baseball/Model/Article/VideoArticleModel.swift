//
//  VideoArticleModel.swift
//     
//
//  Created by 곽현우 on 3/26/25.
//

import Foundation

struct HighlightVideo: Codable, Identifiable {
    let id = UUID()
    let title: String
    let thumbnailURL: String
    let videoURL: String
}
