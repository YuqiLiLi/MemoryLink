//
//  ARMemoryViewModel.swift
//  MemoryLink
//
//  AR 记忆体验的视图模型
//

import Foundation
import SwiftUI
import ARKit
import RealityKit
import Vision
import Combine

// MARK: - AR Detected Object
struct ARDetectedObject: Identifiable {
    let id = UUID()
    let label: String
    let emoji: String
    let confidence: Float
    let position: SIMD3<Float>  // 3D 世界坐标
    let anchor: ARAnchor
}

// MARK: - AR Memory View Model
class ARMemoryViewModel: ObservableObject {
    
    @Published var detectedObjects: [ARDetectedObject] = []
    @Published var selectedObject: ARDetectedObject?
    @Published var isTracking = false
    @Published var showRecordingView = false
    @Published var memoriesNearby = 0
    
    weak var arView: ARView?
    private var anchorManager = ARMemoryAnchorManager.shared
    private var memoryManager = MemoryManager.shared
    
    private var lastDetectionTime: Date = Date()
    private let detectionInterval: TimeInterval = 1.0  // 每秒检测一次
    
    private var glowingEntities: [UUID: ModelEntity] = [:]
    
    // MARK: - Process AR Frame
    func processFrame(_ frame: ARFrame) {
        // 更新追踪状态
        DispatchQueue.main.async {
            self.isTracking = frame.camera.trackingState == .normal
        }
        
        // 节流检测
        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) >= detectionInterval else {
            return
        }
        lastDetectionTime = now
        
        // 检测物体
        detectObjects(in: frame)
        
        // 检查附近的记忆
        checkNearbyMemories(frame: frame)
    }
    
    // MARK: - Detect Objects
    private func detectObjects(in frame: ARFrame) {
        let pixelBuffer = frame.capturedImage
        
        let request = VNClassifyImageRequest { [weak self] request, error in
            guard let self = self,
                  let results = request.results as? [VNClassificationObservation] else {
                return
            }
            
            // 获取高置信度的结果
            let highConfidence = results.filter { $0.confidence > 0.4 }.prefix(5)
            
            var newObjects: [ARDetectedObject] = []
            
            for (index, observation) in highConfidence.enumerated() {
                // 在相机前方创建位置
                let distance: Float = 0.5 + Float(index) * 0.2  // 50cm 到 1.3m
                let angle = Float(index - 2) * 0.3  // 分散角度
                
                var translation = matrix_identity_float4x4
                translation.columns.3.x = sin(angle) * distance
                translation.columns.3.z = -distance
                
                let transform = simd_mul(frame.camera.transform, translation)
                let position = SIMD3<Float>(transform.columns.3.x,
                                           transform.columns.3.y,
                                           transform.columns.3.z)
                
                // 创建锚点
                let anchor = ARAnchor(transform: transform)
                
                // 清理标签
                let cleanLabel = self.cleanLabel(observation.identifier)
                
                let object = ARDetectedObject(
                    label: cleanLabel,
                    emoji: DetectedObject.emojiForLabel(cleanLabel),
                    confidence: observation.confidence,
                    position: position,
                    anchor: anchor
                )
                
                newObjects.append(object)
            }
            
            DispatchQueue.main.async {
                self.detectedObjects = newObjects
                self.visualizeDetectedObjects()
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    // MARK: - Visualize Detected Objects
    private func visualizeDetectedObjects() {
        guard let arView = arView else { return }
        
        // 清除旧的可视化
        arView.scene.anchors.forEach { anchor in
            if let anchorEntity = anchor as? AnchorEntity,
               anchorEntity.name.starts(with: "detected_") {
                arView.scene.removeAnchor(anchorEntity)
            }
        }
        
        // 为每个检测到的物体创建可视化
        for object in detectedObjects {
            let anchorEntity = AnchorEntity(anchor: object.anchor)
            anchorEntity.name = "detected_\(object.id.uuidString)"
            
            // 创建标记框
            let box = createDetectionBox(for: object)
            anchorEntity.addChild(box)
            
            // 检查是否有记忆
            if hasMemory(for: object) {
                let glow = createGlowEffect()
                anchorEntity.addChild(glow)
            }
            
            arView.scene.addAnchor(anchorEntity)
            arView.session.add(anchor: object.anchor)
        }
    }
    
    // MARK: - Create Detection Box
    private func createDetectionBox(for object: ARDetectedObject) -> ModelEntity {
        // 创建线框盒子
        let boxSize: Float = 0.15
        let box = ModelEntity(
            mesh: .generateBox(size: boxSize),
            materials: [SimpleMaterial(
                color: .init(white: 0, alpha: 0.3),
                isMetallic: false
            )]
        )
        
        // 添加边框
        let wireframe = ModelEntity(
            mesh: .generateBox(size: boxSize + 0.01),
            materials: [SimpleMaterial(
                color: hasMemory(for: object) ? UIColor(Color(hex: "4ecdc4")) : .white,
                isMetallic: false
            )]
        )
        wireframe.model?.materials = wireframe.model?.materials.map {
            var material = $0 as! SimpleMaterial
            material.baseColor = MaterialColorParameter.color(
                hasMemory(for: object) ?
                    UIColor(Color(hex: "4ecdc4")) :
                    UIColor.white.withAlphaComponent(0.5)
            )
            return material
        } ?? []
        
        box.addChild(wireframe)
        
        return box
    }
    
    // MARK: - Create Glow Effect
    private func createGlowEffect() -> ModelEntity {
        let sphere = ModelEntity(
            mesh: .generateSphere(radius: 0.1),
            materials: [SimpleMaterial(
                color: UIColor(Color.yellow.opacity(0.4)),
                isMetallic: false
            )]
        )
        
        // 添加脉冲动画（使用 RealityKit 动画）
        var transform = sphere.transform
        transform.scale = SIMD3<Float>(1.2, 1.2, 1.2)
        
        // 创建动画序列
        sphere.move(
            to: transform,
            relativeTo: sphere.parent,
            duration: 1.0
        )
        
        return sphere
    }
    
    // MARK: - Check Nearby Memories
    private func checkNearbyMemories(frame: ARFrame) {
        let cameraPosition = SIMD3<Float>(
            frame.camera.transform.columns.3.x,
            frame.camera.transform.columns.3.y,
            frame.camera.transform.columns.3.z
        )
        
        let nearby = anchorManager.findNearbyAnchors(to: cameraPosition, maxDistance: 2.0)
        
        DispatchQueue.main.async {
            self.memoriesNearby = nearby.count
        }
        
        // 为附近的记忆创建发光效果
        visualizeNearbyMemories(nearby)
    }
    
    // MARK: - Visualize Nearby Memories
    private func visualizeNearbyMemories(_ anchors: [ARMemoryAnchorData]) {
        guard let arView = arView else { return }
        
        for anchorData in anchors {
            // 创建锚点实体
            let transform = anchorData.transform
            let anchor = ARAnchor(transform: transform)
            
            let anchorEntity = AnchorEntity(anchor: anchor)
            anchorEntity.name = "memory_\(anchorData.memoryId.uuidString)"
            
            // 创建发光球体
            let glowSphere = ModelEntity(
                mesh: .generateSphere(radius: 0.08),
                materials: [SimpleMaterial(
                    color: UIColor(Color.yellow.opacity(0.6)),
                    isMetallic: true
                )]
            )
            
            anchorEntity.addChild(glowSphere)
            arView.scene.addAnchor(anchorEntity)
        }
    }
    
    // MARK: - Selection
    func selectObject(_ object: ARDetectedObject) {
        selectedObject = object
    }
    
    func createMemoryForSelected() {
        showRecordingView = true
    }
    
    // MARK: - Check if has memory
    func hasMemory(for object: ARDetectedObject) -> Bool {
        let nearby = anchorManager.findNearbyAnchors(to: object.position, maxDistance: 0.3)
        return !nearby.isEmpty
    }
    
    // MARK: - Clean Label
    private func cleanLabel(_ label: String) -> String {
        let cleaned = label
            .replacingOccurrences(of: "n0", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .components(separatedBy: ",").first ?? label
        
        let words = cleaned.components(separatedBy: " ")
        if let mainWord = words.last, !mainWord.isEmpty {
            return mainWord.capitalized
        }
        
        return cleaned.capitalized
    }
}

