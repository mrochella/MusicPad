//
//  PadsViewModel.swift
//  AbletonPush
//
//  Created by Megan Rochella on 20/06/25.
//

import SwiftData
import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

@MainActor
class PadsViewModel: ObservableObject {
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
    @Published var pendingPadURL: URL? = nil
    @Published var isNamingNewPad: Bool = false
    @Published var newPadName: String = ""
    @Published var soundPadEntities: [SoundPadEntity] = []
    
    private let modelContext: ModelContext
    private var audioPlayers: [UUID: AVAudioPlayer] = [:]
    private let recorder = AudioRecorder()
    
    // Computed property to convert SoundPadEntity to SoundPad
    var pads: [SoundPad] {
        let convertedPads = soundPadEntities.map { $0.asSoundPad }
        print("🎵 Pads computed property called - \(convertedPads.count) pads available")
        return convertedPads
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        setupAudioSession()
        loadPads()
    }
    
    // MARK: - Data Loading
    
    private func loadPads() {
        do {
            let descriptor = FetchDescriptor<SoundPadEntity>()
            soundPadEntities = try modelContext.fetch(descriptor)
            print("📱 Loaded \(soundPadEntities.count) pads from SwiftData")
            
            // Debug: List all files in Documents directory
            listDocumentsFiles()
            
            // Debug: Print all loaded entities
            for (index, entity) in soundPadEntities.enumerated() {
                print("📦 Pad \(index): \(entity.name) - \(entity.filePath) - Default: \(entity.isDefault)")
            }
            
            // Validate and fix file paths instead of removing entities
            validateAndFixFilePaths()
            
            // Load default pads if needed
            ensureDefaultPadsLoaded()
        } catch {
            print("❌ Failed to load pads: \(error)")
        }
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
            print("🎵 Trying to play sound: \(pad.name)")
            print("📁 File path: \(pad.fileURL.path)")
            print("🔍 File exists: \(FileManager.default.fileExists(atPath: pad.fileURL.path))")
            
            if !FileManager.default.fileExists(atPath: pad.fileURL.path) {
                print("❌ File not found at path: \(pad.fileURL.path)")
                throw NSError(domain: "FileNotFound", code: 404, userInfo: [NSLocalizedDescriptionKey: "Sound file not found"])
            }
            
            let player = try AVAudioPlayer(contentsOf: pad.fileURL)
            player.prepareToPlay()
            player.play()
            audioPlayers[pad.id] = player
            
            print("✅ Successfully playing: \(pad.name)")
            
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
        guard index < soundPadEntities.count else { return }
        
        let entity = soundPadEntities[index]
        let pad = entity.asSoundPad
        
        audioPlayers[pad.id]?.stop()
        audioPlayers.removeValue(forKey: pad.id)

        if !entity.isDefault {
            try? FileManager.default.removeItem(at: pad.fileURL)
        }

        modelContext.delete(entity)
        soundPadEntities.remove(at: index)
        selectedPadIndexForEdit = nil  // ✅ clear selection after removing

        // Save the context
        do {
            try modelContext.save()
            print("💾 Removed pad: \(pad.name)")
        } catch {
            print("❌ Failed to save after removing pad: \(error)")
        }

        // Hapus semua instance sound ini dari timeline
        timelineItems.removeAll { item in
            if let sound = item as? SoundPad {
                return sound.id == pad.id
            }
            return false
        }
    }
    
    func handleRecordingCompletion(fileURL: URL?) {
        if let fileURL = fileURL {
            // Store the URL first
            pendingPadURL = fileURL
            isNamingNewPad = true
        }
        
        showingRecorderSheet = false
    }
    
    // MARK: - File Operations
    
    private func getDocumentsDirectory() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        print("📁 Documents directory: \(documentsURL.path)")
        return documentsURL
    }
    
    func finalizePadNaming() {
        guard let url = pendingPadURL else { 
            print("❌ No pending URL to finalize")
            return 
        }

        let padName = newPadName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = padName.isEmpty ? url.deletingPathExtension().lastPathComponent : padName
        
        print("🎵 Finalizing pad: \(finalName)")
        print("📁 File path to save: \(url.path)")
        print("🔍 File exists before saving: \(FileManager.default.fileExists(atPath: url.path))")
        
        // Create new SoundPadEntity
        let newEntity = SoundPadEntity(name: finalName, filePath: url.path, isDefault: false)

        if let index = editingPadIndex, index < soundPadEntities.count {
            // Replace existing entity
            let oldEntity = soundPadEntities[index]
            modelContext.delete(oldEntity)
            modelContext.insert(newEntity)
            soundPadEntities[index] = newEntity
            editingPadIndex = nil
            print("🔄 Replaced pad at index \(index)")
        } else if let index = replacingPadIndex, index < soundPadEntities.count {
            // Replace existing entity
            let oldEntity = soundPadEntities[index]
            modelContext.delete(oldEntity)
            modelContext.insert(newEntity)
            soundPadEntities[index] = newEntity
            replacingPadIndex = nil
            print("🔄 Replaced pad at index \(index)")
        } else if let index = recordingPadIndex {
            if index < soundPadEntities.count {
                // Replace existing entity
                let oldEntity = soundPadEntities[index]
                modelContext.delete(oldEntity)
                modelContext.insert(newEntity)
                soundPadEntities[index] = newEntity
                print("🔄 Replaced recorded pad at index \(index)")
            } else {
                // Add new entity
                modelContext.insert(newEntity)
                soundPadEntities.append(newEntity)
                print("➕ Added new recorded pad")
            }
        } else {
            // Add new entity
            modelContext.insert(newEntity)
            soundPadEntities.append(newEntity)
            print("➕ Added new pad")
        }

        // Save the context
        do {
            try modelContext.save()
            print("💾 Saved new pad: \(finalName)")
        } catch {
            print("❌ Failed to save pad: \(error)")
        }

        recordingPadIndex = nil
        selectedPadIndexForEdit = nil
        pendingPadURL = nil
        newPadName = ""
        isNamingNewPad = false
    }
    
    func handleFileImport(result: Result<[URL], Error>) {
        do {
            guard let selectedFile = try result.get().first else {
                print("❌ No file selected")
                return
            }

            print("📥 Selected file: \(selectedFile.path)")

            guard selectedFile.startAccessingSecurityScopedResource() else {
                throw NSError(domain: "SecurityError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Cannot access selected file"])
            }

            defer { selectedFile.stopAccessingSecurityScopedResource() }

            // Generate a unique filename to avoid conflicts
            let originalName = selectedFile.deletingPathExtension().lastPathComponent
            let fileExtension = selectedFile.pathExtension
            let timestamp = Int(Date().timeIntervalSince1970)
            let uniqueFileName = "\(originalName)_\(timestamp).\(fileExtension)"
            
            let savedURL = getDocumentsDirectory().appendingPathComponent(uniqueFileName)
            
            print("💾 Saving file to: \(savedURL.path)")

            if FileManager.default.fileExists(atPath: savedURL.path) {
                try FileManager.default.removeItem(at: savedURL)
                print("🗑️ Removed existing file at destination")
            }

            try FileManager.default.copyItem(at: selectedFile, to: savedURL)
            print("✅ File copied successfully")

            // Verify file exists after copy
            if FileManager.default.fileExists(atPath: savedURL.path) {
                print("✅ File exists after copy: \(savedURL.path)")
            } else {
                print("❌ File does not exist after copy: \(savedURL.path)")
            }

            // ✅ Save for later
            pendingPadURL = savedURL
            isNamingNewPad = true

        } catch {
            print("❌ Import error: \(error)")
            alertMessage = "Error importing file: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    // MARK: - Default Pads Loading
    
    func ensureDefaultPadsLoaded() {
        print("🔍 Checking for default pads...")
        print("📊 Current soundPadEntities count: \(soundPadEntities.count)")
        
        // Check if we already have default pads loaded
        let hasDefaultPads = soundPadEntities.contains { $0.isDefault }
        print("🎵 Has default pads: \(hasDefaultPads)")
        
        if !hasDefaultPads {
            print("📱 Loading default pads...")
            let defaultPads = loadDefaultPads()
            print("📦 Found \(defaultPads.count) default pads to load")
            
            for pad in defaultPads {
                let entity = SoundPadEntity(name: pad.name, filePath: pad.fileURL.path, isDefault: true)
                modelContext.insert(entity)
                soundPadEntities.append(entity)
                print("✅ Added default pad: \(pad.name) at path: \(pad.fileURL.path)")
            }
            
            // Save the context
            do {
                try modelContext.save()
                print("💾 Default pads saved to SwiftData")
            } catch {
                print("❌ Failed to save default pads: \(error)")
            }
        } else {
            print("📱 Default pads already loaded")
        }
    }
    
    private func loadDefaultPads() -> [SoundPad] {
        let defaultNames = ["kick", "clap", "drum", "beatbox"]
        return defaultNames.compactMap { name in
            if let url = Bundle.main.url(forResource: name, withExtension: "wav") {
                return SoundPad(name: name, fileURL: url, isDefault: true)
            }
            return nil
        }
    }
    
    // MARK: - File Validation and Recovery
    
    private func validateAndFixFilePaths() {
        print("🔧 Validating and fixing file paths...")
        
        for (index, entity) in soundPadEntities.enumerated() {
            let fileURL = URL(fileURLWithPath: entity.filePath)
            let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
            
            if !fileExists {
                if entity.isDefault {
                    // For default files, try to find them in bundle
                    if let bundleURL = Bundle.main.url(forResource: entity.name, withExtension: "wav") {
                        print("🔄 Fixing default file path for \(entity.name)")
                        entity.filePath = bundleURL.path
                    } else {
                        print("❌ Default file not found in bundle for \(entity.name)")
                    }
                } else {
                    // For custom files, search more comprehensively in Documents
                    let documentsURL = getDocumentsDirectory()
                    
                    // Try to find the file in Documents directory with various patterns
                    let possiblePaths = [
                        documentsURL.appendingPathComponent(fileURL.lastPathComponent),
                        documentsURL.appendingPathComponent(entity.name + ".wav"),
                        documentsURL.appendingPathComponent(entity.name + ".aiff"),
                        documentsURL.appendingPathComponent(entity.name + ".mp3"),
                        documentsURL.appendingPathComponent(entity.name + ".m4a")
                    ]
                    
                    var foundPath: URL?
                    for path in possiblePaths {
                        if FileManager.default.fileExists(atPath: path.path) {
                            foundPath = path
                            break
                        }
                    }
                    
                    // If not found with exact patterns, search for files containing the entity name
                    if foundPath == nil {
                        do {
                            let files = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                            for file in files {
                                let fileName = file.deletingPathExtension().lastPathComponent
                                if fileName.contains(entity.name) || entity.name.contains(fileName) {
                                    foundPath = file
                                    print("🔍 Found file by partial name match: \(file.lastPathComponent)")
                                    break
                                }
                            }
                        } catch {
                            print("❌ Error searching Documents directory: \(error)")
                        }
                    }
                    
                    if let foundPath = foundPath {
                        print("🔄 Found custom file at different path for \(entity.name): \(foundPath.path)")
                        entity.filePath = foundPath.path
                    } else {
                        print("❌ Custom file not found anywhere for \(entity.name)")
                    }
                }
            }
        }
        
        // Save changes
        do {
            try modelContext.save()
            print("💾 Saved fixed file paths")
        } catch {
            print("❌ Failed to save fixed file paths: \(error)")
        }
    }
    
    // MARK: - Debug Functions
    
    private func listDocumentsFiles() {
        let documentsURL = getDocumentsDirectory()
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            print("📁 Files in Documents directory:")
            for file in files {
                print("   📄 \(file.lastPathComponent)")
            }
        } catch {
            print("❌ Error listing Documents directory: \(error)")
        }
    }
    
    // MARK: - Public Properties
    
    var recorderInstance: AudioRecorder {
        return recorder
    }
} 
