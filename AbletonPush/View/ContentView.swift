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
                    viewModel.showAddOptions = true
                }
                
                // Timeline(horizontal) sound yang dipilih/diclick user
                SoundTimeline(
                    timelineItems: viewModel.timelineItems,
                    onSoundTap: { (sound: SoundPad) in
                        viewModel.playSoundFromTimeline(sound)
                    },
                    onRemoveItem: { (index: Int) in 
                        viewModel.removeItemFromTimeline(at: index)
                    }
                )
                
                // UtilityButtons ( Loop, Reset, Play, Edit, Delay )
                UtilityButtons(
                    onLoop: { utilityViewModel.handleLoop() },
                    onReset: { utilityViewModel.handleReset() },
                    onPlayPause: { utilityViewModel.handlePlayPause() },
                    onEdit: { utilityViewModel.handleEdit() },
                    onDelay: { utilityViewModel.handleDelay() },
                    isLoopEnabled: utilityViewModel.isLoopEnabled,
                    isPlaying: utilityViewModel.isPlaying,
                    isTimelineEmpty: viewModel.timelineItems.isEmpty
                )

                // Sound Padfor:
                PadsGridView(
                    pads: viewModel.pads,
                    columns: columns,
                    onPadTap: { pad in
                        if viewModel.isEditMode {
                            if let index = viewModel.pads.firstIndex(where: { $0.id == pad.id }) {
                                viewModel.selectedPadIndexForEdit = index
                                viewModel.showingPadOptions = true
                            }
                        } else {
                            viewModel.playSound(for: pad)
                        }
                    },
                    onPadReplace: viewModel.handlePadReplace,
                    onPadRemove: viewModel.removePad,
                    onPadRecord: viewModel.startRecording,
                    onAddPad: viewModel.handleAddPad,
                    isEditMode: viewModel.isEditMode
                )
            }
            .background(Color.black)
            .navigationBarHidden(true)
            .onAppear {
                utilityViewModel.setPadsViewModel(viewModel)
            }
            .onChange(of: viewModel.timelineItems.count) { count in
                print("ViewModel timelineItems count changed to: \(count)")
                utilityViewModel.updateTimelineEmptyState(count == 0)
            }
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
            .sheet(isPresented: $viewModel.showingDelayInput) {
                DelayInputModal(
                    isPresented: $viewModel.showingDelayInput
                ) { duration in
                    viewModel.addDelayToTimeline(duration: duration)
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
                    viewModel.recordingPadIndex = viewModel.pads.count
                    viewModel.showingRecorderSheet = true
                }
                Button("Cancel", role: .cancel) {}
            }

            .confirmationDialog("Edit Pad", isPresented: $viewModel.showingPadOptions, titleVisibility: .visible) {
                Button("Replace") {
                    if let index = viewModel.selectedPadIndexForEdit {
                        viewModel.editingPadIndex = index
                        viewModel.showingFileImporter = true
                    }
                }
                Button("Remove", role: .destructive) {
                    if let index = viewModel.selectedPadIndexForEdit {
                        viewModel.removePad(at: index)
                    }
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
