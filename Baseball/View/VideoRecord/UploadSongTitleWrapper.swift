////
////  UploadSongTitleWrapper.swift
////     
////
////  Created by 곽현우 on 3/13/25.
////
//
//import SwiftUI
//
//struct UploadSongTitleWrapper: View {
//    let selectedTeam: String
//    let selectedTeamImage: String
//    let recordedVideoURL: URL?
//    @Binding var path: NavigationPath
//    @State private var isLoading = true
//    
//    var body: some View {
//        Group {
//            if let videoURL = recordedVideoURL {
//                UploadSongTitleView(
//                    selectedTeam: selectedTeam,
//                    selectedTeamImage: selectedTeamImage,
//                    videoURL: videoURL,
//                    path: $path
//                )
//                .onAppear {
//                    print("✅ UploadSongTitleWrapper: 비디오 URL 존재 -> UploadSongTitleView 이동")
//                    isLoading = false
//                }
//            } else {
//                VStack {
//                    Text("비디오 URL을 불러오는 중입니다...")
//                        .onAppear {
//                            print("❌ UploadSongTitleWrapper: recordedVideoURL이 nil -> CalendarView로 돌아감")
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                if let videoURL = recordedVideoURL {
//                                    print("✅ 다시 확인 후 비디오 URL 감지됨: \(videoURL)")
//                                    isLoading = false
//                                } else {
//                                    print("❌ recordedVideoURL이 여전히 nil -> CalendarView로 돌아감")
//                                    path.removeLast()
//                                }
//                            }
//                        }
//                }
//            }
//        }
//    }
//}
//
//
////#Preview {
////    UploadSongTitleWrapper()
////}
