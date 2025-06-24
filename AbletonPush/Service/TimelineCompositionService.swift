//
//  TimelineCompositionService.swift
//  AbletonPush
//
//  Created by Nessa on 25/06/25.
//

import Foundation
import AVFoundation
import SwiftData

class TimelineCompositionService: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    
    private let modelContext: ModelContext
    private var audioPlayers: [UUID: AVAudioPlayer] = [:]
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func saveTimelineComposition(_ timelineItems: [Any], trackName: String) async throws -> SavedTrack {
        await MainActor.run {
            isProcessing = true
            progress = 0.0
        }
        
        print("🎵 Saving timeline composition: \(trackName)")
        
        // Convert timeline items to data with index
        var timelineData: [TimelineItemData] = []
        var totalDuration: Double = 0
        
        for (index, item) in timelineItems.enumerated() {
            if let sound = item as? SoundPad {
                // For sounds, store the file path and calculate duration
                let duration = await getAudioDuration(for: sound.fileURL)
                
                let timelineItem = TimelineItemData(
                    index: index,
                    type: "sound",
                    name: sound.name,
                    duration: duration,
                    filePath: sound.fileURL.path
                )
                timelineData.append(timelineItem)
                totalDuration += duration
                
            } else if let delay = item as? DelayItem {
                // For delays, store the duration
                let timelineItem = TimelineItemData(
                    index: index,
                    type: "delay",
                    name: nil,
                    duration: delay.duration,
                    filePath: nil
                )
                timelineData.append(timelineItem)
                totalDuration += delay.duration
            }
            
            await MainActor.run {
                progress = Double(index + 1) / Double(timelineItems.count)
            }
        }
        
        print("🎵 Total duration: \(totalDuration)s")
        print("🎵 Timeline items: \(timelineData.count)")
        
        // Create SavedTrack entity
        let savedTrack = SavedTrack(
            name: trackName,
            filePath: "", // No actual file, just composition data
            duration: totalDuration,
            timelineItems: []
        )
        
        // Set the relationship for each timeline item
        for timelineItem in timelineData {
            timelineItem.savedTrack = savedTrack
        }
        
        // Set the timeline items for the saved track
        savedTrack.timelineItems = timelineData
        
        // Save to SwiftData
        modelContext.insert(savedTrack)
        try modelContext.save()
        
        print("🎵 Composition saved to database: \(savedTrack.name)")
        
        await MainActor.run {
            isProcessing = false
            progress = 1.0
        }
        
        return savedTrack
    }
    
    private func getAudioDuration(for url: URL) async -> Double {
        do {
            let audioFile = try AVAudioFile(forReading: url)
            return Double(audioFile.length) / audioFile.processingFormat.sampleRate
        } catch {
            print("❌ Failed to get duration for \(url.lastPathComponent): \(error)")
            return 0.25 // Default duration
        }
    }
    
    func playComposition(_ track: SavedTrack) async {
        print("🎵 Playing composition: \(track.name)")
        
        // Stop any currently playing audio
        stopAllAudio()
        
        // Sort timeline items by index to maintain order
        let sortedTimelineItems = track.timelineItems.sorted { $0.index ?? 0 < $1.index ?? 0 }
        
        print("🎵 Playing \(sortedTimelineItems.count) items in order")
        
        // Play each item in sequence
        var currentDelay: Double = 0
        
        for (index, timelineItem) in sortedTimelineItems.enumerated() {
            print("🎵 Playing item \(index + 1): \(timelineItem.type) at index \(timelineItem.index)")
            
            if timelineItem.type == "sound", let filePath = timelineItem.filePath {
                // Play sound after delay
                await playSoundAfterDelay(filePath: filePath, delay: currentDelay)
                currentDelay += timelineItem.duration ?? 0.25
                
            } else if timelineItem.type == "delay" {
                // Just add delay
                currentDelay += timelineItem.duration ?? 0
            }
        }
    }
    
    private func playSoundAfterDelay(filePath: String, delay: Double) async {
        do {
            let fileURL = URL(fileURLWithPath: filePath)
            
            // Verify file exists
            guard FileManager.default.fileExists(atPath: filePath) else {
                print("❌ File not found: \(filePath)")
                return
            }
            
            // Create audio player
            let player = try AVAudioPlayer(contentsOf: fileURL)
            player.prepareToPlay()
            
            // Generate unique ID for this player
            let playerId = UUID()
            
            // Schedule playback after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                player.play()
                self.audioPlayers[playerId] = player
                
                // Remove player after it finishes
                DispatchQueue.main.asyncAfter(deadline: .now() + player.duration) {
                    self.audioPlayers.removeValue(forKey: playerId)
                }
            }
            
        } catch {
            print("❌ Failed to play sound: \(error)")
        }
    }
    
    func stopAllAudio() {
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
    }
    
    func loadSavedTracks() -> [SavedTrack] {
        do {
            let descriptor = FetchDescriptor<SavedTrack>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Failed to load saved tracks: \(error)")
            return []
        }
    }
    
    func deleteSavedTrack(_ track: SavedTrack) {
        // Delete from SwiftData
        modelContext.delete(track)
        try? modelContext.save()
    }
} 
