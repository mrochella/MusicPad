//
//  UtilityButtons.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import SwiftUI

struct UtilityButtons: View {
    let onLoop: () -> Void
    let onReset: () -> Void
    let onPlayPause: () -> Void
    let onEdit: () -> Void
    let onDelay: () -> Void
    let onSave: () -> Void
    let isLoopEnabled: Bool
    let isPlaying: Bool
    let isTimelineEmpty: Bool

    var body: some View {
        HStack {
            Text("Tools")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Spacer()
                }
        .padding()
        
        HStack(spacing: 12) {
            UtilityButton(title: "Delay", icon: "clock", action: onDelay)
            UtilityButton(
                title: "Loop",
                icon: isLoopEnabled ? "repeat.circle.fill" : "repeat",
                action: onLoop,
                isActive: isLoopEnabled,
                isTimelineEmpty: isTimelineEmpty
            )
            UtilityButton(
                title: isPlaying ? "Pause" : "Play",
                icon: isPlaying ? "pause" : "play",
                action: onPlayPause,
                isTimelineEmpty: isTimelineEmpty
            )
            UtilityButton(
                title: "Reset",
                icon: "arrow.clockwise",
                action: onReset,
                isTimelineEmpty: isTimelineEmpty
            )
            
            UtilityButton(title: "Edit", icon: "pencil", action: onEdit)
            UtilityButton(
                title: "Save",
                icon: "square.and.arrow.down",
                action: onSave, // ini nanti diganti onSave
                isTimelineEmpty: isTimelineEmpty
            )
        }
        .padding()
        .background(Color.clear)
    }
}

struct UtilityButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    let isActive: Bool?
    let isTimelineEmpty: Bool?

    init(title: String, icon: String, action: @escaping () -> Void, isActive: Bool? = nil, isTimelineEmpty: Bool? = nil) {
        self.title = title
        self.icon = icon
        self.action = action
        self.isActive = isActive
        self.isTimelineEmpty = isTimelineEmpty
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isTimelineEmpty == true ? .gray : Color(hex: "#0f1021"))

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isTimelineEmpty == true ? .gray : Color(hex: "#0f1021"))
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    if isTimelineEmpty == true {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                    } else {
                        Image("silver1")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
                .shadow(
                    color: isTimelineEmpty == true ? .clear : Color.yellow.opacity(0.6),
                    radius: 8, x: 0, y: 0
                )
            )
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isTimelineEmpty == true)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue.opacity(0.9), Color.black]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            UtilityButtons(
                onLoop: { print("Loop tapped") },
                onReset: { print("Reset tapped") },
                onPlayPause: { print("Play tapped") },
                onEdit: { print("Edit tapped") },
                onDelay: { print("Delay tapped") },
                onSave: { print("Save tapped") },
                isLoopEnabled: true,
                isPlaying: false,
                isTimelineEmpty: false
            )
        }
    }
    .previewLayout(.sizeThatFits)
}
