//
//  ContentView.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Main Content View
struct ContentView: View {
    @State private var pads: [SoundPad] = []
    @State private var showingFileImporter = false
    @State private var replacingPadIndex: Int?
    @State private var audioPlayers: [UUID: AVAudioPlayer] = [:]
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @StateObject private var recorder = AudioRecorder()
    @State private var showingRecorderSheet = false
    @State private var recordingPadIndex: Int?
    @State private var showAddOptions = false

    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView {
                    showingFileImporter = true
                }

                PadsGridView(
                    pads: pads,
                    columns: columns,
                    onPadTap: playSound,
                    onPadReplace: handlePadReplace,
                    onPadRemove: removePad,
                    onPadRecord: startRecording,
                    onAddPad: handleAddPad
                )
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .fileImporter(
                isPresented: $showingFileImporter,
                allowedContentTypes: [.wav, .mp3],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result: result)
            }
            .sheet(isPresented: $showingRecorderSheet) {
                RecordingSheet(recorder: recorder) { fileURL in
                    if let fileURL = fileURL, let index = recordingPadIndex {
                        let padName = fileURL.deletingPathExtension().lastPathComponent
                        let newPad = SoundPad(name: padName, fileURL: fileURL, isDefault: false)

                        if pads.indices.contains(index) {
                            // Replace existing pad
                            pads[index] = newPad
                        } else {
                            // Add new pad
                            pads.append(newPad)
                        }

                        saveCustomPads()
                    }
                    showingRecorderSheet = false
                }
            }
            .onAppear {
                setupAudioSession()
                loadPads()
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
            .confirmationDialog("Add New Sound", isPresented: $showAddOptions, titleVisibility: .visible) {
                Button("Import File") {
                    showingFileImporter = true
                }
                Button("Record Sound") {
                    recordingPadIndex = pads.count // Add new pad at the end
                    showingRecorderSheet = true
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func startRecording(for index: Int) {
        recordingPadIndex = index
        showingRecorderSheet = true
    }

    private func handlePadReplace(_ index: Int) {
        replacingPadIndex = index
        showingFileImporter = true
    }

    private func handleAddPad() {
        replacingPadIndex = nil
        showAddOptions = true
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }

    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func playSound(for pad: SoundPad) {
        audioPlayers[pad.id]?.stop()

        do {
            if !FileManager.default.fileExists(atPath: pad.fileURL.path) {
                throw NSError(domain: "FileNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sound file not found"])
            }

            let player = try AVAudioPlayer(contentsOf: pad.fileURL)
            player.prepareToPlay()
            player.play()
            audioPlayers[pad.id] = player

            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()

        } catch {
            print("Play error: \(error)")
            alertMessage = "Error playing sound: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else { return }

            guard selectedFile.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "SecurityError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Cannot access selected file"])
            }

            defer { selectedFile.stopAccessingSecurityScopedResource() }

            let fileName = selectedFile.lastPathComponent
            let savedURL = getDocumentsDirectory().appendingPathComponent(fileName)

            if FileManager.default.fileExists(atPath: savedURL.path) {
                try FileManager.default.removeItem(at: savedURL)
            }

            try FileManager.default.copyItem(at: selectedFile, to: savedURL)

            let padName = savedURL.deletingPathExtension().lastPathComponent
            let newPad = SoundPad(name: padName, fileURL: savedURL, isDefault: false)

            if let index = replacingPadIndex {
                pads[index] = newPad
            } else {
                pads.append(newPad)
            }

            saveCustomPads()
            replacingPadIndex = nil

        } catch {
            print("Import error: \(error)")
            alertMessage = "Error importing file: \(error.localizedDescription)"
            showingAlert = true
        }
    }

    private func removePad(at index: Int) {
        let pad = pads[index]
        audioPlayers[pad.id]?.stop()
        audioPlayers.removeValue(forKey: pad.id)

        if !pad.isDefault {
            try? FileManager.default.removeItem(at: pad.fileURL)
        }

        pads.remove(at: index)
        saveCustomPads()
    }

    private func loadPads() {
        let savedPadsURL = getDocumentsDirectory().appendingPathComponent("customPads.json")

        if let data = try? Data(contentsOf: savedPadsURL),
           let decoded = try? JSONDecoder().decode([PadInfo].self, from: data) {
            pads = decoded.compactMap { info in
                let url = URL(fileURLWithPath: info.path)
                if FileManager.default.fileExists(atPath: url.path) {
                    return SoundPad(name: info.name, fileURL: url, isDefault: false)
                }
                return nil
            }
        }

        if pads.isEmpty {
            pads = loadDefaultPads()
        }
    }

    private func loadDefaultPads() -> [SoundPad] {
        let defaultNames = ["kick", "snare", "hihat", "clap", "tom", "ride", "crash", "perc"]
        return defaultNames.compactMap { name in
            if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
                return SoundPad(name: name, fileURL: url, isDefault: true)
            }
            return nil
        }
    }

    private func saveCustomPads() {
        let customPads = pads.map {
            PadInfo(name: $0.name, path: $0.fileURL.path)
        }

        do {
            let data = try JSONEncoder().encode(customPads)
            let url = getDocumentsDirectory().appendingPathComponent("customPads.json")
            try data.write(to: url)
        } catch {
            print("Save error: \(error)")
        }
    }
}

#Preview {
    ContentView()
} 