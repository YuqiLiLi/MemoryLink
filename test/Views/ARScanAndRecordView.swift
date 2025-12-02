//
//  ARScanAndRecordView.swift
//  ReminiscAR
//
//  AR扫描和录音界面 - 创建新记忆
//

import SwiftUI
import AVFoundation

struct ARScanAndRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var memoryManager = MemoryManager.shared
    @StateObject private var recordingManager = AudioRecorderManager()
    
    // 可选：从物体检测预填充
    var prefilledObjectName: String? = nil
    var prefilledEmoji: String? = nil
    
    @State private var currentStep: CreationStep = .scan
    @State private var memoryTitle = ""
    @State private var objectName = ""
    @State private var selectedEmoji = "☕️"
    @State private var creatorName = ""
    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var photoFileName: String?
    
    enum CreationStep {
        case scan, recording, preview, complete
    }
    
    init(prefilledObjectName: String? = nil, prefilledEmoji: String? = nil) {
        self.prefilledObjectName = prefilledObjectName
        self.prefilledEmoji = prefilledEmoji
    }
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            switch currentStep {
            case .scan:
                scanStepView
            case .recording:
                recordingStepView
            case .preview:
                previewStepView
            case .complete:
                completeStepView
            }
            
            // Close Button
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                    .padding(.top, 10)
                    
                    Spacer()
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // 从物体检测预填充数据
            if let objectName = prefilledObjectName {
                self.objectName = objectName
            }
            if let emoji = prefilledEmoji {
                self.selectedEmoji = emoji
            }
        }
    }
    
    // MARK: - Step 1: Take Photo
    private var scanStepView: some View {
        VStack(spacing: 0) {
            // 顶部安全区域
            Spacer()
                .frame(height: 80)
            
            // Photo Preview or Camera Button
            ZStack {
                if let image = capturedImage {
                    // Show captured photo
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .clipped()
                        .cornerRadius(20)
                        .padding()
                } else {
                    // Camera placeholder
                    VStack(spacing: 30) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white.opacity(0.6))
                        
                        VStack(spacing: 15) {
                            Text("📸 Take a Photo of the Object")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("This photo will be linked to your memory")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.gray.opacity(0.3))
                    )
                    .padding()
                }
            }
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                if capturedImage == nil {
                    // Take Photo Button
                    Button(action: { showCamera = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                            Text("Take Photo")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "4ecdc4"))
                        .cornerRadius(15)
                    }
                } else {
                    // Continue to Recording Button
                    Button(action: { currentStep = .recording }) {
                        HStack(spacing: 12) {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 24))
                            Text("Start Recording Memory")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "ff6b6b"), Color(hex: "ff5252")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: Color(hex: "ff6b6b").opacity(0.5), radius: 15)
                    }
                    
                    // Retake Button
                    Button(action: { capturedImage = nil }) {
                        Text("Retake Photo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    }
                }
            }
            .padding()
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $capturedImage, sourceType: .camera)
        }
    }
    
    // MARK: - Step 2: Recording
    private var recordingStepView: some View {
        VStack(spacing: 0) {
            // Recording Header
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text("Recording")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text(recordingManager.formattedTime)
                    .font(.system(size: 18, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding()
            .padding(.top, 60)
            
            Spacer()
            
            // Object Preview
            VStack(spacing: 20) {
                Text(selectedEmoji)
                    .font(.system(size: 80))
                
                Text("Tell your story...")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Audio Visualizer
            AudioWaveformView(isRecording: recordingManager.isRecording)
                .frame(height: 80)
                .padding()
            
            // Live Caption (simulated)
            if recordingManager.isRecording {
                Text(recordingManager.liveCaption)
                    .font(.system(size: 16))
                    .italic()
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.2))
                    )
                    .padding(.horizontal)
            }
            
            Spacer()
            
            // Stop Recording Button
            Button(action: {
                recordingManager.stopRecording()
                currentStep = .preview
            }) {
                Text("Stop & Save")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "ff6b6b"))
                    .cornerRadius(15)
            }
            .padding()
            .padding(.bottom, 40)
        }
        .onAppear {
            recordingManager.startRecording()
        }
    }
    
    // MARK: - Step 3: Preview & Edit
    private var previewStepView: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Success Icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.yellow, Color.orange.opacity(0.3)],
                                center: .center,
                                startRadius: 10,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Text("✨")
                        .font(.system(size: 64))
                }
                .padding(.top, 40)
                
                Text("Memory Recorded!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // Form Fields
                VStack(spacing: 20) {
                    // Creator Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Name")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Enter your name", text: $creatorName)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    
                    // Memory Title
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Memory Title")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("E.g., Grandma's Paris Mug", text: $memoryTitle)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    
                    // Object Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Object Name")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("E.g., Coffee Mug", text: $objectName)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                    }
                    
                    // Emoji Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose an Emoji")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(["☕️", "📷", "🪑", "📚", "🎸", "⌚️", "🖼", "📱", "💍", "🎹"], id: \.self) { emoji in
                                    Text(emoji)
                                        .font(.system(size: 40))
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedEmoji == emoji ? Color(hex: "4ecdc4") : Color.white.opacity(0.2))
                                        )
                                        .onTapGesture {
                                            selectedEmoji = emoji
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Memory Details
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "waveform")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "4ecdc4"))
                            .frame(width: 30)
                        
                        Text("Audio: \(Int(recordingManager.recordedDuration)) seconds")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Spacer()
                        
                        // Play button
                        Button(action: {
                            if let fileName = recordingManager.audioFileName {
                                recordingManager.playAudio(fileName: fileName)
                            }
                        }) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color(hex: "4ecdc4"))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.1))
                    )
                    
                    DetailRow(icon: "doc.text", text: "Transcript ready")
                    DetailRow(icon: "location", text: "Anchored to object")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: saveMemory) {
                        Text("Save Memory")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "4ecdc4"))
                            .cornerRadius(15)
                    }
                    .disabled(memoryTitle.isEmpty || objectName.isEmpty || creatorName.isEmpty)
                    .opacity((memoryTitle.isEmpty || objectName.isEmpty || creatorName.isEmpty) ? 0.5 : 1.0)
                    
                    Button(action: { currentStep = .recording }) {
                        Text("Re-record")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    }
                }
                .padding()
            }
        }
        .background(Color.black)
    }
    
    // MARK: - Step 4: Complete
    private var completeStepView: some View {
        VStack(spacing: 30) {
            Spacer()
                .frame(height: 100)
            
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 150, height: 150)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.green)
            }
            
            Text("Memory Created!")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Text("Your story has been anchored to this object")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "4ecdc4"))
                    .cornerRadius(15)
            }
            .padding()
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Save Memory
    private func saveMemory() {
        // Save photo if available
        if let image = capturedImage {
            photoFileName = saveImage(image)
        }
        
        // Generate transcript (in real app, would use speech recognition)
        let transcript = "This is a recorded memory about \(objectName). Created by \(creatorName)."
        
        let memory = Memory(
            title: memoryTitle,
            objectName: objectName,
            objectEmoji: selectedEmoji,
            transcript: transcript,
            audioFileName: recordingManager.audioFileName,
            audioDuration: recordingManager.recordedDuration,
            creator: creatorName,
            photoFileName: photoFileName
        )
        
        memoryManager.addMemory(memory)
        currentStep = .complete
    }
    
    // MARK: - Save Image
    private func saveImage(_ image: UIImage) -> String {
        let fileName = "photo_\(Date().timeIntervalSince1970).jpg"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
        
        return fileName
    }
}


// MARK: - Audio Waveform View
struct AudioWaveformView: View {
    let isRecording: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<7) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "4ecdc4"), Color(hex: "45b7af")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 6)
                    .frame(height: isRecording ? CGFloat.random(in: 20...70) : 20)
                    .animation(
                        isRecording ? .easeInOut(duration: 0.3).repeatForever() : .default,
                        value: isRecording
                    )
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "4ecdc4"))
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white)
        }
    }
}


#if DEBUG
struct ARScanAndRecordView_Previews: PreviewProvider {
    static var previews: some View {
        ARScanAndRecordView()
    }
}
#endif

