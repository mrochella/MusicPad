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
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.black]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HeaderView {
                        viewModel.showAddOptions = true
                    }

                    SoundTimeline(
                        timelineItems: viewModel.timelineItems,
                        onSoundTap: { sound in
                            viewModel.playSoundFromTimeline(sound)
                        },
                        onRemoveItem: { index in
                            viewModel.removeItemFromTimeline(at: index)
                        },
                        onMoveItem: { fromIndex, toIndex in
                            viewModel.moveItemInTimeline(from: fromIndex, to: toIndex)
                        },
                        isEditMode: viewModel.isEditMode
                    )

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
                    .padding(.vertical)

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
                .background(Color.clear)
                .onAppear {
                    utilityViewModel.setPadsViewModel(viewModel)
                }
                .onChange(of: viewModel.timelineItems.count) { count in
                    print("ViewModel timelineItems count changed to: \(count)")
                    utilityViewModel.updateTimelineEmptyState(count == 0)
                }
            }
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
        .alert("Name Your Sound", isPresented: $viewModel.isNamingNewPad) {
            TextField("Enter name", text: $viewModel.newPadName)
            Button("Save") {
                viewModel.finalizePadNaming()
            }
            Button("Cancel", role: .cancel) {
                viewModel.pendingPadURL = nil
                viewModel.newPadName = ""
                viewModel.isNamingNewPad = false
            }
        } message: {
            Text("Custom name will appear on the sound button.")
        }
    }
}

#Preview {
    ContentView()
}
