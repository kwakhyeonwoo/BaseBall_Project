//
//  AudioMonitor.swift
//     
//
//  Created by 곽현우 on 2/27/25.
//

import AVFoundation

class AudioMonitor: NSObject, AVAudioRecorderDelegate {
    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var silenceDuration: TimeInterval = 0

    func startMonitoring() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.record, mode: .default, options: [])
        try? audioSession.setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatAppleLossless,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let url = URL(fileURLWithPath: "/dev/null")
        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.isMeteringEnabled = true
        recorder?.delegate = self
        recorder?.record()

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.checkSilence()
        }
    }

    func checkSilence() {
        guard let recorder = recorder else { return }
        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)

        if level < 30 { // 특정 데시벨 이하일 경우
            silenceDuration += 1
        } else {
            silenceDuration = 0
        }

        if silenceDuration >= 15 {
            print("10초간 소리가 없어 녹화 중지")
            stopMonitoring()
            NotificationCenter.default.post(name: NSNotification.Name("StopRecording"), object: nil)
        }
    }

    func stopMonitoring() {
        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
    }
}
