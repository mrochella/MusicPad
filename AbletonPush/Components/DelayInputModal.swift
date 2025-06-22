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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Delay")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Enter delay duration in seconds")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Duration (seconds)")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    TextField("0.5", text: $delayDuration)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.black)
                }
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(8)
                    
                    Button("Add Delay") {
                        addDelay()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationBarHidden(true)
            .alert("Invalid Input", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
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