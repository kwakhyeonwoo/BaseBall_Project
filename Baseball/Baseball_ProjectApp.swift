//
//  Baseball_ProjectApp.swift
//  Baseball
//
//  Created by 곽현우 on 12/28/24.
//

import SwiftUI
import KakaoSDKCommon
import KakaoSDKAuth
import Firebase


@main
struct Baseball_ProjectApp: App {
    init(){
        KakaoSDK.initSDK(appKey: "6b54fc20e78909e7354f9c49ba25e913")
        FirebaseApp.configure()
        AudioPlayerManager.configureAudioSession()
        NetworkMonitor.shared
    }
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            firstPage()
        }
    }
}
