//
//  SaveTrackModal.swift
//  AbletonPush
//
//  Created by Nessa on 25/06/25.
//

import SwiftUI

struct SaveTrackModal: View {
    @Binding var isPresented: Bool
    @State private var trackName: String = ""
    let onSave: (String) -> Void
    let isProcessing: Bool
    let progress: Double
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isProcessing {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 20) {
                Text("Save Track")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if isProcessing {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Processing audio...")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(width: 200)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("Enter track name:")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Track name", text: $trackName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Button("Cancel") {
                                isPresented = false
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.white)
                            
                            Button("Save") {
                                let name = trackName.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !name.isEmpty {
                                    onSave(name)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(trackName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "#1e1b33"),
                                Color(hex: "#0f1021")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}

#Preview {
    SaveTrackModal(
        isPresented: .constant(true),
        onSave: { name in print("Save track: \(name)") },
        isProcessing: false,
        progress: 0.0
    )
} 