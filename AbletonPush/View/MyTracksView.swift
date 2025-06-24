//
//  MyTracksView.swift
//  AbletonPush
//
//  Created by Nessa on 24/06/25.
//

import SwiftUI

struct MyTracksView: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#cceeff"),
                    Color(hex: "#cce2ff"),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("My Tracks")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .padding(.top, 50)
                
                Text("Your saved tracks will appear here")
                    .font(.body)
                    .foregroundColor(.black.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MyTracksView()
    }
}
