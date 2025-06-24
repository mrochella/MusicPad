//
//  DelayInputModal.swift
//  AbletonPush
//
//  Created by Megan Rochella on 17/06/25.
//

import SwiftUI

struct DelayInputModal: View {
    @Binding var isPresented: Bool
    let onConfirm: (Double) -> Void

    @State private var delayDuration: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    private var isValidDelay: Bool {
        guard let value = Double(delayDuration), value > 0, value <= 10 else {
            return false
        }
        return true
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Add Delay")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            VStack(spacing: 16) {
                Text("Enter delay duration in seconds:")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))

                TextField("e.g. 0.5", text: $delayDuration)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)

                    Button("Add Delay") {
                        addDelay()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isValidDelay)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: 360)
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
        .alert("Invalid Input", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }

    private func addDelay() {
        guard let duration = Double(delayDuration), duration > 0 else {
            errorMessage = "Please enter a valid positive number"
            showingError = true
            return
        }

        if duration > 10 {
            errorMessage = "Delay cannot exceed 10 seconds"
            showingError = true
            return
        }

        onConfirm(duration)
        isPresented = false
        delayDuration = ""
    }
}

#Preview {
    DelayInputModal(
        isPresented: .constant(true),
        onConfirm: { duration in
            print("Delay added: \(duration) seconds")
        }
    )
}
