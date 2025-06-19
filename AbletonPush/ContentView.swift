//
//  ContentView.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct SoundPad: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var fileURL: URL
    var isDefault: Bool

    static func == (lhs: SoundPad, rhs: SoundPad) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Header View Component
struct HeaderView: View {
    let onAddSounds: () -> Void

    var body: some View {
        HStack {
            Text("SOUNDS PAD")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
            Button("Add Sounds") {
                onAddSounds()
            }
            .foregroundColor(.orange)
        }
        .padding()
        .background(Color.black)
    }
}

// MARK: - Sound Pad Button Component
struct SoundPadButton: View {
    let pad: SoundPad
    let index: Int
    let onTap: () -> Void
    let onReplace: () -> Void
    let onRemove: (() -> Void)?
    let onRecord: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            padContent
        }
        .contextMenu {
            contextMenuContent
        }
    }

    private var padContent: some View {
        VStack(spacing: 4) {
            Text(pad.name.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("\(index + 1)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(padBackground)
    }

    private var padBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundGradient)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
    }

    private var backgroundGradient: LinearGradient {
        if pad.isDefault {
            return LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Button("Replace Sound", systemImage: "arrow.triangle.2.circlepath") {
            onReplace()
        }

        Button("Record Sound", systemImage: "mic") {
            onRecord?()
        }

        if let onRemove = onRemove {
            Button("Remove", systemImage: "trash", role: .destructive) {
                onRemove()
            }
        }
    }
}

// MARK: - Add Pad Button Component
struct AddPadButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.6))
                Text("ADD")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .background(Color.clear)
            )
        }
    }
}

// MARK: - Pads Grid Component
struct PadsGridView: View {
    let pads: [SoundPad]
    let columns: [GridItem]
    let onPadTap: (SoundPad) -> Void
    let onPadReplace: (Int) -> Void
    let onPadRemove: (Int) -> Void
    let onPadRecord: (Int) -> Void
    let onAddPad: () -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(pads.enumerated()), id: \.element.id) { index, pad in
                    SoundPadButton(
                        pad: pad,
                        index: index,
                        onTap: { onPadTap(pad) },
                        onReplace: { onPadReplace(index) },
                        onRemove: pad.isDefault ? nil : { onPadRemove(index) },
                        onRecord: { onPadRecord(index) }
                    )
                }

                if pads.count < 16 {
                    AddPadButton(onTap: onAddPad)
                }
            }
            .padding()
        }
        .background(Color.black.opacity(0.9))
    }
}

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

struct PadInfo: Codable {
    let name: String
    let path: String
}

#Preview {
    ContentView()
}
