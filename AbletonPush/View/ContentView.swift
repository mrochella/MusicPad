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
    @StateObject private var viewModel = PadsViewModel()
    @StateObject private var utilityViewModel = UtilityButtonsViewModel()
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HeaderView {
                    viewModel.showingFileImporter = true
                }
                
                
                UtilityButtons(
                    onLoop: { utilityViewModel.handleLoop() },
                    onReset: { utilityViewModel.handleReset() },
                    onPlayPause: { utilityViewModel.handlePlayPause() },
                    onEdit: { utilityViewModel.handleEdit() },
                    isLoopEnabled: utilityViewModel.isLoopEnabled,
                    isPlaying: utilityViewModel.isPlaying
                )

                PadsGridView(
                    pads: viewModel.pads,
                    columns: columns,
                    onPadTap: viewModel.playSound,
                    onPadReplace: viewModel.handlePadReplace,
                    onPadRemove: viewModel.removePad,
                    onPadRecord: viewModel.startRecording,
                    onAddPad: viewModel.handleAddPad
                )
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .fileImporter(
                isPresented: $viewModel.showingFileImporter,
                allowedContentTypes: [.wav, .mp3, .aiff],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleFileImport(result: result)
            }
            .sheet(isPresented: $viewModel.showingRecorderSheet) {
                RecordingSheet(recorder: viewModel.recorderInstance) { fileURL in
                    viewModel.handleRecordingCompletion(fileURL: fileURL)
                }
            }
            .alert("Error", isPresented: $viewModel.showingAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.alertMessage)
            }
            .confirmationDialog("Add New Sound", isPresented: $viewModel.showAddOptions, titleVisibility: .visible) {
                Button("Import File") {
                    viewModel.showingFileImporter = true
                }
                Button("Record Sound") {
                    viewModel.recordingPadIndex = viewModel.pads.count // Add new pad at the end
                    viewModel.showingRecorderSheet = true
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    ContentView()
} 
