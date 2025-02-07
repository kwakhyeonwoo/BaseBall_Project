//
//  Color.swift
//     
//
//  Created by 곽현우 on 2/7/25.
//

import SwiftUI

// Hex to Color 변환
extension Color {
    init(hex: String) {
        let hexCleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgbValue: UInt64 = 0
        Scanner(string: hexCleaned).scanHexInt64(&rgbValue)

        let red = Double((rgbValue >> 16) & 0xFF) / 255.0
        let green = Double((rgbValue >> 8) & 0xFF) / 255.0
        let blue = Double(rgbValue & 0xFF) / 255.0

        self.init(red: red, green: green, blue: blue)
    }
}

