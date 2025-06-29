//
//  ContentView.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
import SwiftData

// MARK: - Main Content View
struct ContentView: View {
    @Environment(\.modelContext) var modelContext
    @StateObject private var viewModel: PadsViewModel
    @StateObject private var utilityViewModel = UtilityButtonsViewModel()
    @StateObject private var timelineCompositionService: TimelineCompositionService
    @State private var navigationPath = NavigationPath()
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    init() {
        // Create a temporary modelContext for initialization
        let container = try! ModelContainer(for: SoundPadEntity.self, SavedTrack.self, TimelineItemData.self)
        let tempContext = ModelContext(container)
        let tempViewModel = PadsViewModel(modelContext: tempContext)
        let tempCompositionService = TimelineCompositionService(modelContext: tempContext)
        _viewModel = StateObject(wrappedValue: tempViewModel)
        _timelineCompositionService = StateObject(wrappedValue: tempCompositionService)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#1e1b33"),
                        Color(hex: "#0f1021")
                    ]),
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
                        isEditMode: viewModel.isEditMode,
                        moveToMyTrack: { 
                            navigationPath.append(NavDestination.MyTracksView)
                        }
                    )

                    UtilityButtons(
                        onLoop: { utilityViewModel.handleLoop() },
                        onReset: { utilityViewModel.handleReset() },
                        onPlayPause: { utilityViewModel.handlePlayPause() },
                        onEdit: { utilityViewModel.handleEdit() },
                        onDelay: { utilityViewModel.handleDelay() },
                        onSave: { utilityViewModel.handleSave() },
                        isLoopEnabled: utilityViewModel.isLoopEnabled,
                        isPlaying: utilityViewModel.isPlaying,
                        isTimelineEmpty: viewModel.timelineItems.isEmpty
                    )

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
                    utilityViewModel.setTimelineCompositionService(timelineCompositionService)
                }
                .onChange(of: viewModel.timelineItems.count) { count in
                    print("ViewModel timelineItems count changed to: \(count)")
                    utilityViewModel.updateTimelineEmptyState(count == 0)
                }
                
                if viewModel.showingDelayInput {
                    // Dim background
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)

                    // Modal
                    DelayInputModal(
                        isPresented: $viewModel.showingDelayInput
                    ) { duration in
                        viewModel.addDelayToTimeline(duration: duration)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .zIndex(2)
                }
                
                if utilityViewModel.showingSaveModal {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .zIndex(1)

                    // Modal
                    SaveTrackModal(
                        isPresented: $utilityViewModel.showingSaveModal,
                        onSave: { trackName in
                            utilityViewModel.saveTrack(withName: trackName)
                        },
                        isProcessing: timelineCompositionService.isProcessing,
                        progress: timelineCompositionService.progress
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                    .zIndex(2)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Update the viewModel with the correct modelContext if needed
                utilityViewModel.setPadsViewModel(viewModel)
                utilityViewModel.setTimelineCompositionService(timelineCompositionService)
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
            .alert("Error", isPresented: $viewModel.showingAlert) {
                Button("OK") {}
            } message: {
                Text(viewModel.alertMessage)
            }
            .alert("Save Track", isPresented: $utilityViewModel.showingAlert) {
                Button("OK") {}
            } message: {
                Text(utilityViewModel.alertMessage)
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
            .navigationDestination(for: NavDestination.self) { destination in
                switch destination {
                case .MyTracksView:
                    MyTracksView()
                }
            }
        }
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
        .modelContainer(for: [SoundPadEntity.self, SavedTrack.self, TimelineItemData.self])
}
