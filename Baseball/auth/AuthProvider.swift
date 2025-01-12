//
//  AuthProvider.swift
//  Baseball
//
//  Created by 곽현우 on 1/12/25.
//

import Foundation

protocol AuthProvider {
    var isSignedIn: Bool { get }
    var userName: String? { get }
    var userEmail: String? { get }
    
    func signIn()
    func signOut()
}
