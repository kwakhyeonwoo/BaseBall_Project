//
//  TeamScheduleModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/5/25.
//

import Foundation

struct TeamScheduleModel: Decodable {
    let teamName: String
    let gameDate: String
    let opponent: String
}

struct GameResponse: Decodable {
    let games: [TeamScheduleModel]
}
