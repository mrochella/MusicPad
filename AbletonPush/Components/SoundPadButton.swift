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

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                Text(pad.name.uppercased())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("#\(index + 1)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                
            )
        }
        .buttonStyle(OuterGlowStyle(glowColor: .yellow))
    }
}

// MARK: - Outer Glow Button Style
struct OuterGlowStyle: ButtonStyle {
    var glowColor: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(glowColor.opacity(configuration.isPressed ? 1 : 0), lineWidth: 2)
                    .shadow(color: glowColor.opacity(configuration.isPressed ? 0.8 : 0), radius: 10)
            )
            .scaleEffect(configuration.isPressed ? 1.02 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    let samplePad = SoundPad(name: "Kick", fileURL: URL(fileURLWithPath: ""), isDefault: true)

    return ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.black]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        SoundPadButton(
            pad: samplePad,
            index: 0,
            onTap: { print("Pad tapped") }
        )
        .frame(width: 100, height: 100)
        .padding()
    }
}
