//
//  FindIDModel.swift
//  Baseball
//
//  Created by 곽현우 on 1/14/25.
//

import Foundation
import FirebaseFirestore

class FindIDModel {
    var email: String = ""
    var verificationCode: String = ""
    
    private let db = Firestore.firestore()

    // 이메일 형식 검증
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    // 랜덤 코드 생성
    func generateRandomCode(length: Int) -> String {
        return String((0..<length).map { _ in "0123456789".randomElement()! })
    }

    // 이메일 전송 함수 (Firebase Cloud Function 호출)
    func sendVerificationEmail(to email: String, code: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "https://sendverificationcode-csknue227q-uc.a.run.app") else {
            completion(false)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["email": email, "code": code]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending email: \(error.localizedDescription)")
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }.resume()
    }

    // Firebase Firestore에서 이메일로 ID 찾기
    func fetchID(for email: String, completion: @escaping (Result<String, Error>) -> Void) {
        db.collection("users")
            .whereField("email", isEqualTo: email)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                if let documents = querySnapshot?.documents, let document = documents.first {
                    let id = document.data()["id"] as? String ?? "알 수 없는 아이디"
                    completion(.success(id))
                } else {
                    completion(.failure(NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "해당 이메일에 연결된 아이디를 찾을 수 없습니다."])))
                }
            }
    }

}
