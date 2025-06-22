//
//  SoundTimeline.swift
//  AbletonPush
//
//  Created by Nessa on 20/06/25.
//

import SwiftUI

struct SoundTimeline: View {
    let timelineItems: [Any]
    let onSoundTap: (SoundPad) -> Void
    let onRemoveItem: (Int) -> Void
    let onMoveItem: (Int, Int) -> Void
    let isEditMode: Bool
    
    @State private var draggedIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Timeline")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("Drag to reorder")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(timelineItems.enumerated()), id: \.offset) { index, item in
                        if let sound = item as? SoundPad {
                            TimelineSoundItem(
                                sound: sound,
                                index: index,
                                onTap: {
                                    onSoundTap(sound) 
                                },
                                onRemove: {
                                    onRemoveItem(index) 
                                },
                                isEditMode: isEditMode
                            )
                            .onDrag {
                                draggedIndex = index
                                let provider = NSItemProvider()
                                provider.registerDataRepresentation(forTypeIdentifier: "public.text", visibility: .all) { completion in
                                    let data = "\(index)".data(using: .utf8)
                                    completion(data, nil)
                                    return nil
                                }
                                return provider
                            }
                            .onDrop(of: [.text], delegate: DropViewDelegate(
                                item: sound, 
                                index: index, 
                                onMoveItem: onMoveItem,
                                onDragEnd: { draggedIndex = nil }
                            ))
                        } else if let delay = item as? DelayItem {
                            TimelineDelayItem(
                                delay: delay,
                                index: index,
                                onRemove: {
                                    onRemoveItem(index)
                                },
                                isEditMode: isEditMode
                            )
                            .onDrag {
                                draggedIndex = index
                                let provider = NSItemProvider()
                                provider.registerDataRepresentation(forTypeIdentifier: "public.text", visibility: .all) { completion in
                                    let data = "\(index)".data(using: .utf8)
                                    completion(data, nil)
                                    return nil
                                }
                                return provider
                            }
                            .onDrop(of: [.text], delegate: DropViewDelegate(
                                item: delay, 
                                index: index, 
                                onMoveItem: onMoveItem,
                                onDragEnd: { draggedIndex = nil }
                            ))
                        }
                    }
                    
                    if timelineItems.isEmpty {
                        Text("No items in timeline")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(height: 120)
        .background(Color.black.opacity(0.8))
    }
}

struct DropViewDelegate: DropDelegate {
    let item: Any
    let index: Int
    let onMoveItem: (Int, Int) -> Void
    let onDragEnd: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadDataRepresentation(forTypeIdentifier: "public.text") { data, error in
            if let data = data,
               let string = String(data: data, encoding: .utf8),
               let draggedIndex = Int(string) {
                DispatchQueue.main.async {
                    if draggedIndex != index {
                        onMoveItem(draggedIndex, index)
                    }
                    onDragEnd()
                }
            }
        }
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Optional: Add visual feedback when dragging over
    }
    
    func dropExited(info: DropInfo) {
        // Optional: Remove visual feedback when dragging away
    }
}

struct TimelineSoundItem: View {
    let sound: SoundPad
    let index: Int
    let onTap: () -> Void
    let onRemove: () -> Void
    let isEditMode: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                onTap()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(sound.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .frame(width: 80, height: 80)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(sound.isDefault ? 
                              LinearGradient(colors: [.blue.opacity(0.8), .blue.opacity(0.6)], startPoint: .top, endPoint: .bottom) :
                              LinearGradient(colors: [.green.opacity(0.8), .green.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isEditMode {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

struct TimelineDelayItem: View {
    let delay: DelayItem
    let index: Int
    let onRemove: () -> Void
    let isEditMode: Bool
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(String(format: "%.1f", delay.duration))s")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [.orange.opacity(0.8), .orange.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            if isEditMode {
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

#Preview {
    let sampleSounds = [
        SoundPad(name: "Kick", fileURL: URL(fileURLWithPath: ""), isDefault: true),
        SoundPad(name: "Snare", fileURL: URL(fileURLWithPath: ""), isDefault: true),
        SoundPad(name: "HiHat", fileURL: URL(fileURLWithPath: ""), isDefault: false)
    ]
    
    let sampleDelays = [
        DelayItem(duration: 0.5),
        DelayItem(duration: 1.0)
    ]
    
    let timelineItems: [Any] = [sampleSounds[0], sampleDelays[0], sampleSounds[1], sampleDelays[1]]
    
    SoundTimeline(
        timelineItems: timelineItems,
        onSoundTap: { sound in print("Timeline sound tapped: \(sound.name)") },
        onRemoveItem: { index in print("Remove item at index: \(index)") },
        onMoveItem: { fromIndex, toIndex in print("Move item from \(fromIndex) to \(toIndex)") },
        isEditMode: true
    )
    .background(Color.black)
} 
