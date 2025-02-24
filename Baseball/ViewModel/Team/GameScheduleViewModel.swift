//
//  TeamScheduleViewModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/5/25.
//

import SwiftUI

class GameScheduleViewModel: ObservableObject {
    @Published var gameSchedules: [TeamScheduleModel] = []
    
    func fetchGameSchedules(for team: String) {
        guard let url = URL(string: "https://api.naver.com/baseball/games/\(team)") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("gaQ9abn61x6i6MsxWf8m", forHTTPHeaderField: "X-Naver-Client-Id")
        request.setValue("j7Yc0FLwRh", forHTTPHeaderField: "X-Naver-Client-Secret")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let gameResponse = try decoder.decode(GameResponse.self, from: data)
                
                DispatchQueue.main.async {
                    self.gameSchedules = gameResponse.games
                }
            } catch {
                print("Error decoding data: \(error)")
            }
        }.resume()
    }
}


