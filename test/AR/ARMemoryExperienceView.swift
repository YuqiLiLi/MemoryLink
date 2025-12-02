//
//  ARMemoryExperienceView.swift
//  MemoryLink
//
//  真正的 AR 记忆体验 - 在 3D 空间中检测和标记物体
//

import SwiftUI
import RealityKit
import ARKit

struct ARMemoryExperienceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var arViewModel = ARMemoryViewModel()
    
    var body: some View {
        ZStack {
            // AR View
            ARMemoryViewContainer(viewModel: arViewModel)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    
                    Spacer()
                    
                    // Status Indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(arViewModel.isTracking ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        
                        Text(arViewModel.isTracking ? "Tracking" : "Initializing...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                }
                .padding()
                
                Spacer()
                
                // Detected Objects List
                if !arViewModel.detectedObjects.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(arViewModel.detectedObjects) { object in
                                DetectedObjectCard(
                                    object: object,
                                    hasMemory: arViewModel.hasMemory(for: object)
                                ) {
                                    arViewModel.selectObject(object)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Instructions
                VStack(spacing: 8) {
                    if arViewModel.selectedObject != nil {
                        Text("Tap 'Create Memory' to save a story for this object")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    } else {
                        Text("Move your camera around to detect objects")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        if arViewModel.memoriesNearby > 0 {
                            Text("✨ \(arViewModel.memoriesNearby) memory nearby - look for glowing objects")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "4ecdc4"))
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.black.opacity(0.6))
                        .blur(radius: 10)
                )
                .padding()
            }
            
            // Create Memory Button (when object selected)
            if arViewModel.selectedObject != nil {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        arViewModel.createMemoryForSelected()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                            Text("Create Memory")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "4ecdc4"), Color(hex: "45b7af")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                        .shadow(color: Color(hex: "4ecdc4").opacity(0.5), radius: 20)
                    }
                    .padding()
                }
            }
        }
        .fullScreenCover(isPresented: $arViewModel.showRecordingView) {
            if let object = arViewModel.selectedObject {
                ARScanAndRecordView(
                    prefilledObjectName: object.label,
                    prefilledEmoji: object.emoji
                )
            }
        }
    }
}

// MARK: - AR View Container
struct ARMemoryViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARMemoryViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // AR Configuration
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        viewModel.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, ARSessionDelegate {
        let viewModel: ARMemoryViewModel
        
        init(viewModel: ARMemoryViewModel) {
            self.viewModel = viewModel
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            viewModel.processFrame(frame)
        }
    }
}

// MARK: - Detected Object Card
struct DetectedObjectCard: View {
    let object: ARDetectedObject
    let hasMemory: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Emoji with glow effect if has memory
                ZStack {
                    if hasMemory {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.yellow.opacity(0.6), Color.yellow.opacity(0)],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                    }
                    
                    Text(object.emoji)
                        .font(.system(size: 40))
                }
                
                Text(object.label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                if hasMemory {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("Has memory")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(Color(hex: "4ecdc4"))
                } else {
                    Text("Tap to add")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(hasMemory ? Color(hex: "4ecdc4").opacity(0.3) : Color.black.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(hasMemory ? Color(hex: "4ecdc4") : Color.white.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
}

#if DEBUG
struct ARMemoryExperienceView_Previews: PreviewProvider {
    static var previews: some View {
        ARMemoryExperienceView()
    }
}
#endif

