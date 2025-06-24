//
//  MyTracksView.swift
//  AbletonPush
//
//  Created by Nessa on 24/06/25.
//

import SwiftUI
import AVFoundation
import SwiftData

struct MyTracksView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var savedTracks: [SavedTrack] = []
    @State private var currentlyPlayingTrackId: UUID?
    @State private var showingDeleteAlert = false
    @State private var trackToDelete: SavedTrack?
    @StateObject private var compositionService: TimelineCompositionService
    
    init() {
        let container = try! ModelContainer(for: SoundPadEntity.self, SavedTrack.self, TimelineItemData.self)
        let context = ModelContext(container)
        _compositionService = StateObject(wrappedValue: TimelineCompositionService(modelContext: context))
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#cceeff"),
                    Color(hex: "#cce2ff"),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("My Tracks")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 50)
                
                if savedTracks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No tracks yet")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        
                        Text("Create and save tracks from the main screen")
                            .font(.body)
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(savedTracks, id: \.id) { track in
                                TrackCard(
                                    track: track,
                                    isPlaying: currentlyPlayingTrackId == track.id,
                                    onPlay: { playTrack(track) },
                                    onDelete: { deleteTrack(track) }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSavedTracks()
        }
        .alert("Delete Track", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let track = trackToDelete {
                    confirmDeleteTrack(track)
                }
            }
        } message: {
            Text("Are you sure you want to delete this track? This action cannot be undone.")
        }
    }
    
    private func loadSavedTracks() {
        savedTracks = compositionService.loadSavedTracks()
    }
    
    private func playTrack(_ track: SavedTrack) {
        // Stop currently playing track
        if currentlyPlayingTrackId != nil {
            compositionService.stopAllAudio()
        }
        
        currentlyPlayingTrackId = track.id
        
        Task {
            await compositionService.playComposition(track)
            
            // Reset playing state after composition finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + track.duration) {
                if self.currentlyPlayingTrackId == track.id {
                    self.currentlyPlayingTrackId = nil
                }
            }
        }
    }
    
    private func deleteTrack(_ track: SavedTrack) {
        trackToDelete = track
        showingDeleteAlert = true
    }
    
    private func confirmDeleteTrack(_ track: SavedTrack) {
        // Stop if currently playing
        if currentlyPlayingTrackId == track.id {
            compositionService.stopAllAudio()
            currentlyPlayingTrackId = nil
        }
        
        // Delete from service
        compositionService.deleteSavedTrack(track)
        
        // Reload tracks
        loadSavedTracks()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TrackCard: View {
    let track: SavedTrack
    let isPlaying: Bool
    let onPlay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Play button
            Button(action: onPlay) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Track info
            VStack(alignment: .leading, spacing: 4) {
                Text(track.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                HStack {
                    Text(formatDuration(track.duration))
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.4))
                    
                    Text("\(track.timelineItems.count) items")
                        .font(.caption)
                        .foregroundColor(.black.opacity(0.6))
                }
                
                Text(formatDate(track.createdAt))
                    .font(.caption2)
                    .foregroundColor(.black.opacity(0.5))
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    private func formatDuration(_ duration: Double) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        MyTracksView()
    }
}
