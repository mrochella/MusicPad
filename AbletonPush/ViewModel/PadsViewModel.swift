//
//  PadsViewModel.swift
//  AbletonPush
//
//  Created by Megan Rochella on 20/06/25.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

@MainActor
class PadsViewModel: ObservableObject {
    @Published var pads: [SoundPad] = []
    @Published var timelineItems: [Any] = []
    @Published var showingFileImporter = false
    @Published var replacingPadIndex: Int?
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var showingRecorderSheet = false
    @Published var recordingPadIndex: Int?
    @Published var showAddOptions = false
    @Published var isPauseEnable: Bool = false
    @Published var isEditMode: Bool = false
    @Published var editingPadIndex: Int? = nil
    @Published var showingPadOptions = false
    @Published var selectedPadIndexForEdit: Int? = nil
    @Published var showingDelayInput = false
    
    private var audioPlayers: [UUID: AVAudioPlayer] = [:]
    private let recorder = AudioRecorder()
    
    init() {
        setupAudioSession()
        loadPads()
    }
    
    // MARK: - Audio Management
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup error: \(error)")
        }
    }
    
    func playSound(for pad: SoundPad) {
        
        // Ensure audio session is active
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to activate audio session: \(error)")
        }
        
        audioPlayers[pad.id]?.stop()
        
        do {
            if !FileManager.default.fileExists(atPath: pad.fileURL.path) {
                throw NSError(domain: "FileNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sound file not found"])
            }
            
            let player = try AVAudioPlayer(contentsOf: pad.fileURL)
            player.prepareToPlay()
            player.play()
            audioPlayers[pad.id] = player
            
            // efek geteran
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Add sound to timeline
            addSoundToTimeline(pad)
            
        } catch {
            print("❌ Play error: \(error)")
            alertMessage = "Error playing sound: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // MARK: - Timeline Management
    
    func addSoundToTimeline(_ sound: SoundPad) {
        timelineItems.append(sound)
    }
    
    func removeSoundFromTimeline(at index: Int) {
        if timelineItems.indices.contains(index) {
            timelineItems.remove(at: index)
        }
    }
    
    func removeItemFromTimeline(at index: Int) {
        if timelineItems.indices.contains(index) {
            timelineItems.remove(at: index)
        }
    }
    
    func moveItemInTimeline(from fromIndex: Int, to toIndex: Int) {
        guard fromIndex != toIndex,
              timelineItems.indices.contains(fromIndex),
              timelineItems.indices.contains(toIndex) else { return }
        
        let item = timelineItems.remove(at: fromIndex)
        timelineItems.insert(item, at: toIndex)
    }
    
    func clearTimeline() {
        timelineItems.removeAll()
    }
    
    func playSoundFromTimeline(_ sound: SoundPad) {
        playSoundWithoutAddingToTimeline(sound)
    }
    
    private func playSoundWithoutAddingToTimeline(_ pad: SoundPad) {
        
        // Ensure audio session is active
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to activate audio session: \(error)")
        }
        
        audioPlayers[pad.id]?.stop()
        
        do {
            if !FileManager.default.fileExists(atPath: pad.fileURL.path) {
                throw NSError(domain: "FileNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sound file not found"])
            }
            
            let player = try AVAudioPlayer(contentsOf: pad.fileURL)
            player.prepareToPlay()
            player.play()
            audioPlayers[pad.id] = player
            
            // memberi efek getaran
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } catch {
            print("❌ Play error: \(error)")
            alertMessage = "Error playing sound: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    func stopAllAudio() {
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
    }
    
    // MARK: - Delay Management
    
    func addDelayToTimeline(duration: Double) {
        let delayItem = DelayItem(duration: duration)
        timelineItems.append(delayItem)
    }
    
    func removeDelayFromTimeline(at index: Int) {
        if timelineItems.indices.contains(index) {
            timelineItems.remove(at: index)
        }
    }
    
    func showDelayInput() {
        showingDelayInput = true
    }
    
    // MARK: - Pad Management
    
    func startRecording(for index: Int) {
        recordingPadIndex = index
        showingRecorderSheet = true
    }
    
    func handlePadReplace(_ index: Int) {
        replacingPadIndex = index
        showingFileImporter = true
    }
    
    func handleAddPad() {
        replacingPadIndex = nil
        showAddOptions = true
    }
    
    func removePad(at index: Int) {
        let pad = pads[index]
        audioPlayers[pad.id]?.stop()
        audioPlayers.removeValue(forKey: pad.id)

        if !pad.isDefault {
            try? FileManager.default.removeItem(at: pad.fileURL)
        }

        pads.remove(at: index)
        selectedPadIndexForEdit = nil  // ✅ clear selection after removing
        saveCustomPads()

        // Hapus semua instance sound ini dari timeline
        timelineItems.removeAll { item in
            if let sound = item as? SoundPad {
                return sound.id == pad.id
            }
            return false
        }
    }
    
    func handleRecordingCompletion(fileURL: URL?) {
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
    
    // MARK: - File Operations
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func handleFileImport(result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else { 
                print("❌ No file selected")
                return 
            }

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

            // Handle different scenarios
            if let index = editingPadIndex {
                // Editing existing pad
                pads[index] = newPad
                editingPadIndex = nil
            } else if let index = replacingPadIndex {
                // Replacing existing pad
                pads[index] = newPad
                replacingPadIndex = nil
            } else {
                // Adding new pad
                pads.append(newPad)
            }
            
            selectedPadIndexForEdit = nil
            saveCustomPads()
            
        } catch {
            print("❌ Import error: \(error)")
            alertMessage = "Error importing file: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // MARK: - Data Persistence
    
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
    
    // MARK: - Public Properties
    
    var recorderInstance: AudioRecorder {
        return recorder
    }
} 
