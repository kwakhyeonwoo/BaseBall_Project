//
//  UploadSong.swift
//     
//
//  Created by 곽현우 on 4/28/25.
//

import Foundation

struct UploadedSong: Identifiable {
    let id: String
    let title: String
    let uploader: String
    let videoURL: String
    let thumbnailURL: String
}

enum UploadedSongCategory {
    case uploaded
    case popular
}
