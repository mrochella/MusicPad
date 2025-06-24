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
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text("Drag to reorder")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(Color.clear) // ✅ make header background clear

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
                        VStack(spacing: 6) {
                            Image(systemName: "square.dashed")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))

                            Text("No items")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(width: 800, height: 180)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.horizontal)
                .background(Color.clear)
            }
            .background(Color.clear)
        }
        .frame(height: 300)
        .background(Color.clear)
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
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#1e1b33"),
                                    Color(hex: "#0f1021")
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Text(sound.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .overlay(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "#1e1b33"),
                                    Color(hex: "#0f1021")
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .mask(
                            Text(sound.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)
                        )
                }
                .frame(width: 80, height: 180)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(sound.isDefault ?
                              LinearGradient(
                                  colors: [
                                      Color(hex: "#88bbdd"),
                                      Color(hex: "#88aadd")
                                  ],
                                  startPoint: .top,
                                  endPoint: .bottom
                              ) :
                                LinearGradient(
                                    colors: [
                                        Color(hex: "#88bbdd"),
                                        Color(hex: "#88aadd")
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
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
                // Gradient-filled SF Symbol
                Image(systemName: "clock")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#1e1b33"),
                                Color(hex: "#0f1021")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Gradient-filled text using overlay + mask
                let durationText = Text("\(String(format: "%.1f", delay.duration))s")
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                durationText
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#1e1b33"),
                                Color(hex: "#0f1021")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(durationText)
            }
            .frame(width: 80, height: 180)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#fff5a1"),
                                Color(hex: "#ffe75e")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
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

    return ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.black]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        SoundTimeline(
            timelineItems: timelineItems,
            onSoundTap: { sound in print("Timeline sound tapped: \(sound.name)") },
            onRemoveItem: { index in print("Remove item at index: \(index)") },
            onMoveItem: { fromIndex, toIndex in print("Move item from \(fromIndex) to \(toIndex)") },
            isEditMode: true
        )
    }
}
