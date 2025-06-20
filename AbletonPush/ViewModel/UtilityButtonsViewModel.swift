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
    
    private var audioPlayers: [UUID: AVAudioPlayer] = [:]
    private weak var padsViewModel: PadsViewModel?
    
    // MARK: - Initialization
    
    func setPadsViewModel(_ viewModel: PadsViewModel) {
        self.padsViewModel = viewModel
    }
    
    // MARK: - Utility Button Handlers
    
    func handleLoop() {
        isLoopEnabled.toggle()
        
        if isLoopEnabled {
            // Mulai play timeline jika ada sound di timeline
            if let padsVM = padsViewModel, !padsVM.selectedSounds.isEmpty {
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
    
    // Play Pause button
    func handlePlayPause() {
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
    
    // MARK: - Audio Management
    
    func addAudioPlayer(_ player: AVAudioPlayer, for id: UUID) {
        audioPlayers[id] = player
    }
    
    func removeAudioPlayer(for id: UUID) {
        audioPlayers.removeValue(forKey: id)
    }
    
    func stopAllAudio() {
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
    
    // MARK: - Timeline Playback
    
    private func playAllTimelineSounds() {
        guard let padsVM = padsViewModel else {
            print("PadsViewModel not set")
            return
        }
        
        let timelineSounds = padsVM.selectedSounds
        
        if timelineSounds.isEmpty {
            print("No sounds in timeline to play")
            isPlaying = false
            return
        }
        
        // play sound with delay
        for (index, sound) in timelineSounds.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.25) {
                if self.isPlaying { // Check if still playing
                    padsVM.playSoundFromTimeline(sound)
                    
                    // If this is the last sound and loop is enabled, restart
                    if index == timelineSounds.count - 1 && self.isLoopEnabled {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if self.isPlaying && self.isLoopEnabled {
                                self.playAllTimelineSounds()
                            } else {
                                print("🛑 Loop stopped - isPlaying: \(self.isPlaying), isLoopEnabled: \(self.isLoopEnabled)")
                            }
                        }
                    } else if index == timelineSounds.count - 1 && !self.isLoopEnabled {
                        // If not looping, stop after last sound
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if !self.isLoopEnabled {
                                print("🛑 Playback finished - loop disabled")
                                self.isPlaying = false
                            }
                        }
                    }
                }
            }
        }
    }
} 
