//
//  TeamColorModel.swift
//     
//
//  Created by 곽현우 on 2/7/25.
//

import SwiftUI

class TeamColorModel {
    static let shared = TeamColorModel()

    // 팀 별 팀 컬러
    private let teamColors: [String: String] = [
        "SSG": "#CE0E2D",
        "삼성": "#074CA1",
        "롯데": "#041E42",
        "두산": "#1A1748",
        "한화": "#FC4E00",
        "키움": "#570514",
        "KT": "#000000",
        "LG": "#C30452",
        "NC": "#315288",
        "KIA": "#EA0029"
    ]

    func getColor(for team: String) -> Color {
        if let hexColor = teamColors[team] {
            return Color(hex: hexColor)
        }
        return Color.gray  // 기본 색상
    }
}
