//
//  SoundPadButton.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import SwiftUI

// MARK: - Sound Pad Button Component
struct SoundPadButton: View {
    let pad: SoundPad
    let index: Int
    let onTap: () -> Void
    let onReplace: () -> Void
    let onRemove: (() -> Void)?
    let onRecord: (() -> Void)?

    var body: some View {
        Button(action: onTap) {
            padContent
        }
        .contextMenu {
            contextMenuContent
        }
    }

    private var padContent: some View {
        VStack(spacing: 4) {
            Text(pad.name.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text("\(index + 1)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(padBackground)
    }

    private var padBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(backgroundGradient)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
    }

    private var backgroundGradient: LinearGradient {
        if pad.isDefault {
            return LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.blue.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private var contextMenuContent: some View {
        Button("Replace Sound", systemImage: "arrow.triangle.2.circlepath") {
            onReplace()
        }

        Button("Record Sound", systemImage: "mic") {
            onRecord?()
        }

        if let onRemove = onRemove {
            Button("Remove", systemImage: "trash", role: .destructive) {
                onRemove()
            }
        }
    }
}

#Preview {
    let samplePad = SoundPad(name: "Kick", fileURL: URL(fileURLWithPath: ""), isDefault: true)
    
    SoundPadButton(
        pad: samplePad,
        index: 0,
        onTap: { print("Pad tapped") },
        onReplace: { print("Replace tapped") },
        onRemove: { print("Remove tapped") },
        onRecord: { print("Record tapped") }
    )
    .frame(width: 100, height: 100)
    .background(Color.black)
} 