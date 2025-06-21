//
//  SoundTimeline.swift
//  AbletonPush
//
//  Created by Nessa on 20/06/25.
//

import SwiftUI

struct SoundTimeline: View {
    let selectedSounds: [SoundPad]
    let onSoundTap: (SoundPad) -> Void
    let onRemoveSound: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timeline")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(selectedSounds.enumerated()), id: \.offset) { index, sound in
                        TimelineSoundItem(
                            sound: sound,
                            index: index,
                            onTap: {
                                onSoundTap(sound) 
                            },
                            onRemove: {
                                onRemoveSound(index) 
                            }
                        )
                    }
                    
                    if selectedSounds.isEmpty {
                        Text("No sounds selected")
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

struct TimelineSoundItem: View {
    let sound: SoundPad
    let index: Int
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
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
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    let sampleSounds = [
        SoundPad(name: "Kick", fileURL: URL(fileURLWithPath: ""), isDefault: true),
        SoundPad(name: "Snare", fileURL: URL(fileURLWithPath: ""), isDefault: true),
        SoundPad(name: "HiHat", fileURL: URL(fileURLWithPath: ""), isDefault: false)
    ]
    
    SoundTimeline(
        selectedSounds: sampleSounds,
        onSoundTap: { sound in print("Timeline sound tapped: \(sound.name)") },
        onRemoveSound: { index in print("Remove sound at index: \(index)") }
    )
    .background(Color.black)
} 
