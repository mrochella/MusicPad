//
//  AudioRecorder.swift
//  AbletonPush
//
//  Created by Megan Rochella on 18/06/25.
//

import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    private var audioRecorder: AVAudioRecorder?
    private var outputURL: URL?

    func startRecording(fileName: String) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }

            if granted {
                DispatchQueue.main.async {
                    self.setupAndStartRecording(fileName: fileName)
                }
            } else {
                print("Microphone permission denied.")
            }
        }
    }

    private func setupAndStartRecording(fileName: String) {
        let recordingSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(fileName).m4a")
        outputURL = fileURL

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: recordingSettings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true

        } catch {
            print("Recording failed: \(error)")
        }
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        return outputURL
    }
}
