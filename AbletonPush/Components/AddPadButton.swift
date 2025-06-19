//
//  AddPadButton.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import SwiftUI

// MARK: - Add Pad Button Component
struct AddPadButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack {
                Image(systemName: "plus")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.6))
                Text("ADD")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .background(Color.clear)
            )
        }
    }
}

#Preview {
    AddPadButton {
        print("Add pad tapped")
    }
    .frame(width: 100, height: 100)
    .background(Color.black)
} 