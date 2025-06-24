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
                let nameText = Text(pad.name.uppercased())
                    .font(.body)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                nameText
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
                    .mask(nameText)

                let indexText = Text("#\(index + 1)")
                    .font(.caption)

                indexText
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
                    .mask(indexText)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 160)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "#cceeff"),
                                Color(hex: "#cce2ff")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
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
