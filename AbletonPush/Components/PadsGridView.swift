//
//  PadsGridView.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import SwiftUI

// MARK: - Pads Grid Component
struct PadsGridView: View {
    let pads: [SoundPad]
    let columns: [GridItem]
    let onPadTap: (SoundPad) -> Void
    let onPadReplace: (Int) -> Void
    let onPadRemove: (Int) -> Void
    let onPadRecord: (Int) -> Void
    let onAddPad: () -> Void
    let isEditMode: Bool

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array(pads.enumerated()), id: \.element.id) { index, pad in
                    ZStack(alignment: .topTrailing) {
                        SoundPadButton(
                            pad: pad,
                            index: index,
                            onTap: { onPadTap(pad) }
                        )

                        if isEditMode {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.yellow)
                                .background(Color.black)
                                .clipShape(Circle())
                                .font(.system(size: 20))
                                .offset(x: -2, y: 2)
                        }
                    }
                }

                if pads.count < 12 {
                    AddPadButton(onTap: onAddPad)
                }
            }
            .padding()
        }
        .background(Color.clear) // ✅ Transparent to allow parent background to show
    }
}

#Preview {
    let samplePads = [
        SoundPad(name: "Kick", fileURL: URL(fileURLWithPath: ""), isDefault: true),
        SoundPad(name: "Snare", fileURL: URL(fileURLWithPath: ""), isDefault: true),
        SoundPad(name: "HiHat", fileURL: URL(fileURLWithPath: ""), isDefault: true)
    ]

    let columns = Array(repeating: GridItem(.flexible()), count: 4)

    return ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.black]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        PadsGridView(
            pads: samplePads,
            columns: columns,
            onPadTap: { _ in print("Pad tapped") },
            onPadReplace: { _ in print("Replace tapped") },
            onPadRemove: { _ in print("Remove tapped") },
            onPadRecord: { _ in print("Record tapped") },
            onAddPad: { print("Add pad tapped") },
            isEditMode: true
        )
    }
}
