//
//  ArticleModel.swift
//     
//
//  Created by 곽현우 on 3/25/25.
//

import Foundation

//struct Article {
//    let title: String
//    let link: String
//}

struct Article: Identifiable {
    let id = UUID()
    let title: String
    let link: String
}
