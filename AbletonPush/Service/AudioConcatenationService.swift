//
//  AudioConcatenationService.swift
//  AbletonPush
//
//  Created by Nessa on 25/06/25.
//

import Foundation
import AVFoundation
import SwiftData

class AudioConcatenationService: ObservableObject {
    @Published var isProcessing = false
    @Published var progress: Double = 0.0
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func concatenateTimelineItems(_ timelineItems: [Any], trackName: String) async throws -> SavedTrack {
        await MainActor.run {
            isProcessing = true
            progress = 0.0
        }
        
        print("🎵 Starting audio concatenation for \(timelineItems.count) items")
        
        // Create a temporary directory for processing
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        defer {
            // Clean up temp directory
            try? FileManager.default.removeItem(at: tempDir)
        }
        
        // Prepare audio files and delays
        var audioSegments: [AVAudioFile] = []
        var timelineData: [TimelineItemData] = []
        var totalDuration: Double = 0
        
        // Define standard format for output
        let standardFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        for (index, item) in timelineItems.enumerated() {
            print("🎵 Processing item \(index + 1)/\(timelineItems.count)")
            
            if let sound = item as? SoundPad {
                print("🎵 Processing sound: \(sound.name)")
                
                // Verify file exists
                guard FileManager.default.fileExists(atPath: sound.fileURL.path) else {
                    throw NSError(domain: "AudioConcatenation", code: 2, userInfo: [NSLocalizedDescriptionKey: "Sound file not found: \(sound.name)"])
                }
                
                // Load and convert audio file to standard format
                let audioFile = try await loadAndConvertAudioFile(from: sound.fileURL, to: standardFormat, in: tempDir)
                audioSegments.append(audioFile)
                
                let timelineItem = TimelineItemData(
                    type: "sound",
                    name: sound.name,
                    duration: nil,
                    filePath: sound.fileURL.path
                )
                timelineData.append(timelineItem)
                
                // Use actual duration
                let soundDuration = Double(audioFile.length) / audioFile.processingFormat.sampleRate
                totalDuration += soundDuration
                print("🎵 Sound duration: \(soundDuration)s")
                
            } else if let delay = item as? DelayItem {
                print("🎵 Processing delay: \(delay.duration)s")
                
                // Create silence for delay
                let silenceFile = try createSilenceFile(duration: delay.duration, format: standardFormat, in: tempDir)
                audioSegments.append(silenceFile)
                
                let timelineItem = TimelineItemData(
                    type: "delay",
                    name: nil,
                    duration: delay.duration,
                    filePath: nil
                )
                timelineData.append(timelineItem)
                
                totalDuration += delay.duration
                print("🎵 Delay duration: \(delay.duration)s")
            }
            
            await MainActor.run {
                progress = Double(index + 1) / Double(timelineItems.count)
            }
        }
        
        print("🎵 Total duration: \(totalDuration)s")
        print("🎵 Audio segments: \(audioSegments.count)")
        
        // Concatenate all audio segments
        let concatenatedFile = try await concatenateAudioFiles(audioSegments, in: tempDir)
        
        // Save to documents directory
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "\(trackName)_\(timestamp).wav"
        let finalURL = documentsDir.appendingPathComponent(fileName)
        
        print("🎵 Saving to: \(finalURL.path)")
        
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: finalURL.path) {
            try FileManager.default.removeItem(at: finalURL)
        }
        
        try FileManager.default.copyItem(at: concatenatedFile.url, to: finalURL)
        
        // Verify file was saved
        guard FileManager.default.fileExists(atPath: finalURL.path) else {
            throw NSError(domain: "AudioConcatenation", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to save concatenated file"])
        }
        
        print("🎵 File saved successfully")
        
        // Create SavedTrack entity
        let savedTrack = SavedTrack(
            name: trackName,
            filePath: finalURL.path,
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
        
        print("🎵 Track saved to database: \(savedTrack.name)")
        
        await MainActor.run {
            isProcessing = false
            progress = 1.0
        }
        
        return savedTrack
    }
    
    private func loadAndConvertAudioFile(from url: URL, to targetFormat: AVAudioFormat, in directory: URL) async throws -> AVAudioFile {
        print("🎵 Loading audio file: \(url.lastPathComponent)")
        
        // First, try to read the original file
        let originalFile: AVAudioFile
        do {
            originalFile = try AVAudioFile(forReading: url)
            print("🎵 Original format: \(originalFile.processingFormat)")
        } catch let error as NSError {
            print("❌ Failed to read original file: \(error)")
            
            // Handle specific AVFoundation errors
            if error.domain == "com.apple.coreaudio.avfoundation" {
                switch error.code {
                case -5: // kAudioFileInvalidFileError
                    throw NSError(domain: "AudioConcatenation", code: 4, 
                                userInfo: [NSLocalizedDescriptionKey: "Invalid audio file format: \(url.lastPathComponent)"])
                case -43: // kAudioFilePermissionError
                    throw NSError(domain: "AudioConcatenation", code: 5, 
                                userInfo: [NSLocalizedDescriptionKey: "Permission denied accessing file: \(url.lastPathComponent)"])
                default:
                    throw NSError(domain: "AudioConcatenation", code: 6, 
                                userInfo: [NSLocalizedDescriptionKey: "Audio file error (\(error.code)): \(url.lastPathComponent)"])
                }
            }
            throw error
        }
        
        // If formats match, return the original file
        if originalFile.processingFormat == targetFormat {
            print("🎵 Formats match, using original file")
            return originalFile
        }
        
        // Convert to target format
        print("🎵 Converting to target format: \(targetFormat)")
        
        let convertedURL = directory.appendingPathComponent("converted_\(UUID().uuidString).wav")
        
        do {
            // Read the original file into a buffer
            let buffer = AVAudioPCMBuffer(pcmFormat: originalFile.processingFormat, frameCapacity: AVAudioFrameCount(originalFile.length))!
            try originalFile.read(into: buffer)
            
            // Create a new buffer with target format
            let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(originalFile.length))!
            convertedBuffer.frameLength = AVAudioFrameCount(originalFile.length)
            
            // Copy audio data (simple copy, no resampling)
            for channel in 0..<min(Int(targetFormat.channelCount), Int(originalFile.processingFormat.channelCount)) {
                if let outputChannel = convertedBuffer.floatChannelData?[channel],
                   let inputChannel = buffer.floatChannelData?[channel] {
                    for frame in 0..<Int(buffer.frameLength) {
                        outputChannel[frame] = inputChannel[frame]
                    }
                }
            }
            
            // Write converted buffer to file
            let convertedFile = try AVAudioFile(forWriting: convertedURL, settings: targetFormat.settings)
            try convertedFile.write(from: convertedBuffer)
            
            print("🎵 Conversion completed: \(convertedURL.path)")
            
            return try AVAudioFile(forReading: convertedURL)
            
        } catch let error as NSError {
            print("❌ Conversion failed: \(error)")
            
            // If conversion fails, try to use original file anyway
            if error.domain == "com.apple.coreaudio.avfoundation" {
                print("🎵 Falling back to original file format")
                return originalFile
            }
            throw error
        }
    }
    
    private func createSilenceFile(duration: Double, format: AVAudioFormat, in directory: URL) throws -> AVAudioFile {
        let frameCount = Int(duration * format.sampleRate)
        
        print("🎵 Creating silence file: \(duration)s, \(frameCount) frames")
        
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frameCount))!
        buffer.frameLength = AVAudioFrameCount(frameCount)
        
        // Fill with silence (zeros)
        for channel in 0..<Int(format.channelCount) {
            if let channelData = buffer.floatChannelData?[channel] {
                for i in 0..<frameCount {
                    channelData[i] = 0.0
                }
            }
        }
        
        let silenceURL = directory.appendingPathComponent("silence_\(duration).wav")
        let silenceFile = try AVAudioFile(forWriting: silenceURL, settings: format.settings)
        try silenceFile.write(from: buffer)
        
        return try AVAudioFile(forReading: silenceURL)
    }
    
    private func concatenateAudioFiles(_ audioFiles: [AVAudioFile], in directory: URL) async throws -> AVAudioFile {
        guard !audioFiles.isEmpty else {
            throw NSError(domain: "AudioConcatenation", code: 1, userInfo: [NSLocalizedDescriptionKey: "No audio files to concatenate"])
        }
        
        print("🎵 Concatenating \(audioFiles.count) audio files")
        
        if audioFiles.count == 1 {
            print("🎵 Only one file, returning as is")
            return audioFiles[0]
        }
        
        // Get the format from the first file
        let format = audioFiles[0].processingFormat
        print("🎵 Output format: \(format)")
        
        // Verify all files have the same format, if not, convert them
        var processedFiles: [AVAudioFile] = []
        for (index, audioFile) in audioFiles.enumerated() {
            if audioFile.processingFormat == format {
                processedFiles.append(audioFile)
            } else {
                print("🎵 Converting file \(index) to match format")
                let convertedFile = try await loadAndConvertAudioFile(from: audioFile.url, to: format, in: directory)
                processedFiles.append(convertedFile)
            }
        }
        
        // Calculate total frame count
        var totalFrameCount: AVAudioFrameCount = 0
        for (index, audioFile) in processedFiles.enumerated() {
            let fileLength = AVAudioFrameCount(audioFile.length)
            totalFrameCount += fileLength
            print("🎵 File \(index): \(fileLength) frames")
        }
        
        print("🎵 Total frames: \(totalFrameCount)")
        
        // Create output buffer
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrameCount)!
        outputBuffer.frameLength = totalFrameCount
        
        // Concatenate audio data
        var currentFrame: AVAudioFrameCount = 0
        
        for (index, audioFile) in processedFiles.enumerated() {
            print("🎵 Processing file \(index + 1)/\(processedFiles.count)")
            
            do {
                let readBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(audioFile.length))!
                try audioFile.read(into: readBuffer)
                
                // Copy data to output buffer
                for channel in 0..<Int(format.channelCount) {
                    if let outputChannel = outputBuffer.floatChannelData?[channel],
                       let inputChannel = readBuffer.floatChannelData?[channel] {
                        for frame in 0..<Int(readBuffer.frameLength) {
                            outputChannel[Int(currentFrame) + frame] = inputChannel[frame]
                        }
                    }
                }
                
                currentFrame += readBuffer.frameLength
                
            } catch let error as NSError {
                print("❌ Failed to process file \(index): \(error)")
                
                // If a file fails, skip it and continue
                if error.domain == "com.apple.coreaudio.avfoundation" {
                    print("🎵 Skipping problematic file and continuing")
                    continue
                }
                throw error
            }
        }
        
        // Adjust buffer length to actual written frames
        outputBuffer.frameLength = currentFrame
        
        // Write concatenated audio to file
        let outputURL = directory.appendingPathComponent("concatenated.wav")
        let outputFile = try AVAudioFile(forWriting: outputURL, settings: format.settings)
        try outputFile.write(from: outputBuffer)
        
        print("🎵 Concatenation completed: \(outputURL.path)")
        
        return try AVAudioFile(forReading: outputURL)
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
        // Delete the audio file
        let fileURL = URL(fileURLWithPath: track.filePath)
        try? FileManager.default.removeItem(at: fileURL)
        
        // Delete from SwiftData
        modelContext.delete(track)
        try? modelContext.save()
    }
} 
