//
//  UtilityButtonsViewModel.swift
//  AbletonPush
//
//  Created by Megan Rochella on 20/06/25.
//

import SwiftUI
import AVFoundation

@MainActor
class UtilityButtonsViewModel: ObservableObject {
    @Published var isLoopEnabled: Bool = false
    @Published var isPlaying: Bool = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var isTimelineEmpty: Bool = true
    @Published var showingSaveModal = false
    
    private var audioPlayers: [UUID: AVAudioPlayer] = [:]
    private weak var padsViewModel: PadsViewModel?
    private var timelineCompositionService: TimelineCompositionService?
    
    // MARK: - Initialization
    
    func setPadsViewModel(_ viewModel: PadsViewModel) {
        self.padsViewModel = viewModel
    }
    
    func setTimelineCompositionService(_ service: TimelineCompositionService) {
        self.timelineCompositionService = service
    }
    
    // MARK: - Utility Button Handlers
    
    func handleLoop() {
        // Don't enable loop if timeline is empty
        if isTimelineEmpty {
            return
        }
        
        isLoopEnabled.toggle()
        
        if isLoopEnabled && !isPlaying{
            // Mulai play timeline jika ada item di timeline
            if let padsVM = padsViewModel, !padsVM.timelineItems.isEmpty {
                isPlaying = true
                playAllTimelineSounds()
            }
        } else {
            // Stop playing jika loop dimatikan
            isPlaying = false
            stopAllAudio()
        }
    }
    
    func handleReset() {
        // Stop all playing sound
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
        
        // Stop all audio from PadsViewModel
        if let padsVM = padsViewModel {
            padsVM.stopAllAudio()
            padsVM.clearTimeline()
        }
        
        isLoopEnabled = false
        isPlaying = false
    }
    
    func handlePlayPause() {
        if isTimelineEmpty {
            return
        }

        isPlaying.toggle()
        
        if isPlaying {
            playAllTimelineSounds()
        } else {
            stopAllAudio()
        }
    }
    
    // MARK: - TODO EDIT BUTTON
    func handleEdit() {
        guard let padsVM = padsViewModel else { return }
        padsVM.isEditMode.toggle()
    }
    
    // MARK: - Delay Button Handler
    func handleDelay() {
        guard let padsVM = padsViewModel else { return }
        padsVM.showDelayInput()
    }
    
    // MARK: - Save timeline composition
    func handleSave() {
        guard let padsVM = padsViewModel, !padsVM.timelineItems.isEmpty else {
            alertMessage = "Timeline is empty. Add some sounds first!"
            showingAlert = true
            return
        }
        
        showingSaveModal = true
    }
    
    func saveTrack(withName name: String) {
        guard let padsVM = padsViewModel,
              let service = timelineCompositionService else {
            alertMessage = "Service not available"
            showingAlert = true
            return
        }
        
        Task {
            do {
                let savedTrack = try await service.saveTimelineComposition(padsVM.timelineItems, trackName: name)
                
                await MainActor.run {
                    showingSaveModal = false
                    alertMessage = "Track '\(savedTrack.name)' saved successfully!"
                    showingAlert = true
                }
                
            } catch {
                await MainActor.run {
                    showingSaveModal = false
                    alertMessage = "Failed to save track: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    // MARK: - Audio Management
    
    func addAudioPlayer(_ player: AVAudioPlayer, for id: UUID) {
        audioPlayers[id] = player
    }
    
    func removeAudioPlayer(for id: UUID) {
        audioPlayers.removeValue(forKey: id)
    }
    
    func stopAllAudio() {
        isLoopEnabled = false
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
    }
    
    // MARK: - State Management
    
    func getLoopState() -> Bool {
        return isLoopEnabled
    }
    
    func getPlayState() -> Bool {
        return isPlaying
    }
    
    func updateTimelineEmptyState(_ isEmpty: Bool) {
        isTimelineEmpty = isEmpty
        
        // If timeline becomes empty, disable loop and stop playing
        if isEmpty {
            isLoopEnabled = false
            isPlaying = false
            stopAllAudio()
        }
    }
    
    // MARK: - Timeline Playback
    
    private func playAllTimelineSounds() {
        guard let padsVM = padsViewModel else {
            print("PadsViewModel not set")
            return
        }
        
        let timelineItems = padsVM.timelineItems
        
        if timelineItems.isEmpty {
            print("No items in timeline to play")
            isPlaying = false
            return
        }
        
        // Calculate total duration of timeline
        var totalDuration: Double = 0
        for item in timelineItems {
            if item is SoundPad {
                totalDuration += 0.25 // Default delay between sounds
            } else if let delay = item as? DelayItem {
                totalDuration += delay.duration
            }
        }
        
        // play sound with delay
        var currentDelay: Double = 0
        
        for (_, item) in timelineItems.enumerated() {
            if let sound = item as? SoundPad {
                DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) {
                    if self.isPlaying { // Check if still playing
                        padsVM.playSoundFromTimeline(sound)
                    }
                }
                currentDelay += 0.25 // Default delay between sounds
            } else if let delay = item as? DelayItem {
                currentDelay += delay.duration
            }
        }
        
        // Handle loop after total duration
        if isLoopEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                if self.isPlaying && self.isLoopEnabled {
                    print("🔄 Restarting loop after total duration: \(totalDuration)")
                    self.playAllTimelineSounds()
                } else {
                    print("🛑 Loop stopped - isPlaying: \(self.isPlaying), isLoopEnabled: \(self.isLoopEnabled)")
                }
            }
        } else {
            // If not looping, stop after total duration
            DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
                if !self.isLoopEnabled {
                    print("🛑 Playback finished - loop disabled")
                    self.isPlaying = false
                }
            }
        }
    }
} 
