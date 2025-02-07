//
//  TeamColorModel.swift
//     
//
//  Created by 곽현우 on 2/7/25.
//

import SwiftUI

class TeamColorModel {
    static let shared = TeamColorModel()

    private let teamColors: [String: String] = [
        "SSG": "#CE0E2D",
        "Samsung": "#074CA1",
        "Lotte": "#041E42",
        "Doosan": "#1A1748",
        "Hanwha": "#FC4E00",
        "Kiwoom": "#570514",
        "Kt": "#000000",
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
