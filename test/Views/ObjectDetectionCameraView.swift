//
//  ObjectDetectionCameraView.swift
//  MemoryLink
//
//  带物体检测的相机视图
//

import SwiftUI
import AVFoundation

struct ObjectDetectionCameraView: View {
    @StateObject private var detectionManager = ObjectDetectionManager()
    @State private var selectedObject: DetectedObject?
    @State private var showRecordingView = false
    @State private var cameraReady = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Camera Preview Layer
                CameraPreviewWithDetection(
                    detectionManager: detectionManager,
                    onCameraReady: {
                        cameraReady = true
                        detectionManager.startDetection()
                    }
                )
                .ignoresSafeArea()
                
                VStack {
                    // Top Status
                    HStack {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(cameraReady && detectionManager.isDetecting ? Color.green : Color.orange)
                                .frame(width: 10, height: 10)
                            
                            if !cameraReady {
                                Text("Initializing camera...")
                            } else if detectionManager.detectedObjects.isEmpty {
                                Text("Scanning... point at objects")
                            } else {
                                Text("Found \(detectionManager.detectedObjects.count) objects")
                            }
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                        )
                        
                        Spacer()
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Detection Cards at bottom
                    if !detectionManager.detectedObjects.isEmpty {
                        VStack(spacing: 10) {
                            ForEach(detectionManager.detectedObjects) { object in
                                DetectionCardView(
                                    object: object,
                                    onTap: {
                                        selectedObject = object
                                        showRecordingView = true
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    } else {
                        // 提示
                        VStack(spacing: 12) {
                            Image(systemName: "viewfinder.circle")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.6))
                            
                            Text("Point camera at common objects")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("cups, books, phones, chairs, etc.")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(30)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black.opacity(0.6))
                        )
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .onDisappear {
            detectionManager.stopDetection()
        }
        .fullScreenCover(isPresented: $showRecordingView) {
            if let object = selectedObject {
                ARScanAndRecordView(
                    prefilledObjectName: object.label,
                    prefilledEmoji: object.emoji
                )
            }
        }
    }
}

// MARK: - Camera Preview with Detection
struct CameraPreviewWithDetection: UIViewRepresentable {
    @ObservedObject var detectionManager: ObjectDetectionManager
    var onCameraReady: () -> Void
    
    class PreviewView: UIView {
        var previewLayer: AVCaptureVideoPreviewLayer?
        
        func setupWithSession(_ session: AVCaptureSession) {
            // 创建预览层
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = bounds
            
            // 设置方向
            if let connection = layer.connection {
                connection.videoOrientation = .portrait
            }
            
            self.layer.addSublayer(layer)
            self.previewLayer = layer
            
            print("Preview layer setup complete")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
    }
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        
        // 等待权限授权
        DispatchQueue.main.async {
            // 检查权限
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                if let session = detectionManager.setupCamera() {
                    view.setupWithSession(session)
                    onCameraReady()
                }
                
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    DispatchQueue.main.async {
                        if granted {
                            if let session = detectionManager.setupCamera() {
                                view.setupWithSession(session)
                                onCameraReady()
                            }
                        } else {
                            print("Camera permission denied")
                        }
                    }
                }
                
            default:
                print("Camera access denied or restricted")
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
    }
    
    static func dismantleUIView(_ uiView: PreviewView, coordinator: ()) {
        uiView.previewLayer?.removeFromSuperlayer()
    }
}

// MARK: - Detection Card View
struct DetectionCardView: View {
    let object: DetectedObject
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: {
            isPressed = true
            
            // 触觉反馈
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPressed = false
                onTap()
            }
        }) {
            HStack(spacing: 15) {
                // Emoji with pulse effect
                ZStack {
                    if isPulsing {
                        Circle()
                            .fill(Color(hex: "4ecdc4").opacity(0.3))
                            .frame(width: 60, height: 60)
                            .scaleEffect(isPulsing ? 1.5 : 1.0)
                            .opacity(isPulsing ? 0 : 1)
                    }
                    
                    Text(object.emoji)
                        .font(.system(size: 42))
                }
                .frame(width: 60, height: 60)
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(object.label)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        // Confidence badge
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("\(Int(object.confidence * 100))%")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "4ecdc4"))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("Tap to record")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // Arrow with pulse
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color(hex: "4ecdc4"))
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                isPressed ? Color.green : Color(hex: "4ecdc4"),
                                lineWidth: 3
                            )
                    )
                    .shadow(color: Color(hex: "4ecdc4").opacity(0.3), radius: 10)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

#if DEBUG
struct DetectionCardView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            DetectionCardView(
                object: DetectedObject(
                    label: "Cup",
                    confidence: 0.87,
                    boundingBox: CGRect(x: 0, y: 0, width: 100, height: 100),
                    emoji: "☕️"
                ),
                onTap: {}
            )
            .padding()
        }
    }
}
#endif

#if DEBUG
struct ObjectDetectionCameraView_Previews: PreviewProvider {
    static var previews: some View {
        ObjectDetectionCameraView()
    }
}
#endif

