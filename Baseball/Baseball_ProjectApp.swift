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
        KakaoSDK.initSDK(appKey: "")
        FirebaseApp.configure()
        AVPlayerBackgroundManager.configureAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            firstPage()
        }
    }
}
