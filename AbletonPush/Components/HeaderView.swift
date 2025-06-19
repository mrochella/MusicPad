//
//  HeaderView.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import SwiftUI

// MARK: - Header View Component
struct HeaderView: View {
    let onAddSounds: () -> Void

    var body: some View {
        HStack {
            Text("SOUNDS PAD")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            Spacer()
            Button("Add Sounds") {
                onAddSounds()
            }
            .foregroundColor(.orange)
        }
        .padding()
        .background(Color.black)
    }
}

#Preview {
    HeaderView {
        print("Add Sounds tapped")
    }
} 