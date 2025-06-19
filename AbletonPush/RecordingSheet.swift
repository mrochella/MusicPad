//
//  RecordingSheet.swift
//  AbletonPush
//
//  Created by Megan Rochella on 18/06/25.
//

import SwiftUI

struct RecordingSheet: View {
    @ObservedObject var recorder: AudioRecorder
    let onStop: (URL?) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Voice Recorder")
                .font(.headline)
            
            if recorder.isRecording {
                Button("Stop Recording") {
                    let url = recorder.stopRecording()
                    onStop(url)
                }
                .padding()
                .foregroundColor(.red)
            } else {
                Button("Start Recording") {
                    let timestamp = Int(Date().timeIntervalSince1970)
                    recorder.startRecording(fileName: "recording_\(timestamp)")
                }
                .padding()
            }
        }
        .padding()
    }
}
