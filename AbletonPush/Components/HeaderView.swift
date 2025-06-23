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
            Text("BEATFORGE")
                .font(.system(size: 48, weight: .heavy, design: .default))
                .foregroundColor(.white)
                .shadow(radius: 4)
        }
        .padding()
        .background(Color.clear)
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

        HeaderView {
            print("Add Sounds tapped")
        }
    }
}
