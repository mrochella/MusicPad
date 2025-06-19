//
//  UtilityButtonsViewModel.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
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
    
    // MARK: - Utility Button Handlers
    
    func handleLoop() {
        isLoopEnabled.toggle()
        print("Loop \(isLoopEnabled ? "enabled" : "disabled")")
        
        if isLoopEnabled {
            alertMessage = "Loop mode enabled"
        } else {
            alertMessage = "Loop mode disabled"
        }
        showingAlert = true
    }
    
    func handleReset() {
        // Stop all playing audio
        audioPlayers.values.forEach { $0.stop() }
        audioPlayers.removeAll()
        
        // Reset loop state
        isLoopEnabled = false
        
        // Reset play state
        isPlaying = false
        
        print("Reset completed - all audio stopped")
        alertMessage = "All audio reset"
        showingAlert = true
    }
    
    func handlePlayPause() {
        isPlaying.toggle()
        print("Play/Pause toggled - isPlaying: \(isPlaying)")
        
        if isPlaying {
            alertMessage = "Play mode activated"
        } else {
            alertMessage = "Pause mode activated"
        }
        showingAlert = true
    }
    
    func handleEdit() {
        print("Edit mode activated")
        alertMessage = "Edit mode activated"
        showingAlert = true
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
} 