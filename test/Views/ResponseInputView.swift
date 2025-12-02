//
//  ResponseInputView.swift
//  ReminiscAR
//
//  添加回复界面
//

import SwiftUI

struct ResponseInputView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var memoryManager = MemoryManager.shared
    
    let memoryId: UUID
    
    @State private var responseType: ResponseType = .text
    @State private var textContent = ""
    @State private var userName = ""
    
    enum ResponseType {
        case text, voice
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Response Type Selector
                HStack(spacing: 12) {
                    TypeButton(
                        icon: "text.bubble",
                        title: "Text",
                        isSelected: responseType == .text
                    ) {
                        responseType = .text
                    }
                    
                    TypeButton(
                        icon: "mic",
                        title: "Voice",
                        isSelected: responseType == .voice
                    ) {
                        responseType = .voice
                    }
                }
                .padding(.horizontal)
                
                // Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Name")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your name", text: $userName)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                }
                .padding(.horizontal)
                
                // Input Area
                if responseType == .text {
                    textInputView
                } else {
                    voiceInputView
                }
                
                Spacer()
                
                // Submit Button
                Button(action: submitResponse) {
                    Text("Send Response")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "4ecdc4"))
                        .cornerRadius(15)
                }
                .disabled(userName.isEmpty || (responseType == .text && textContent.isEmpty))
                .opacity((userName.isEmpty || (responseType == .text && textContent.isEmpty)) ? 0.5 : 1.0)
                .padding()
            }
            .padding(.top)
            .navigationTitle("Add Your Response")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Text Input View
    private var textInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Message")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            TextEditor(text: $textContent)
                .frame(height: 200)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .padding(.horizontal)
        }
    }
    
    // MARK: - Voice Input View
    private var voiceInputView: some View {
        VStack(spacing: 20) {
            Text("Voice recording feature coming soon!")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button(action: {}) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color(hex: "4ecdc4"), lineWidth: 3)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .fill(Color(hex: "4ecdc4").opacity(0.2))
                            .frame(width: 110, height: 110)
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color(hex: "4ecdc4"))
                    }
                    
                    Text("Tap to record")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
    
    // MARK: - Submit Response
    private func submitResponse() {
        let response = MemoryResponse(
            authorName: userName,
            content: textContent,
            isVoiceNote: responseType == .voice
        )
        
        memoryManager.addResponse(to: memoryId, response: response)
        
        // Dismiss the sheet
        dismiss()
    }
}

// MARK: - Type Button
struct TypeButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(isSelected ? Color(hex: "4ecdc4") : .secondary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color(hex: "4ecdc4").opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "4ecdc4") : Color.clear, lineWidth: 2)
            )
        }
    }
}

#if DEBUG
struct ResponseInputView_Previews: PreviewProvider {
    static var previews: some View {
        ResponseInputView(memoryId: Memory.mockMemories[0].id)
    }
}
#endif

