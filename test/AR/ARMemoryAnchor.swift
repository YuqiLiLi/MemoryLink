//
//  ARMemoryAnchor.swift
//  MemoryLink
//
//  AR 记忆锚点 - 绑定到 3D 空间位置的记忆
//

import Foundation
import ARKit
import RealityKit

/// AR 记忆锚点数据
struct ARMemoryAnchorData: Codable {
    let id: UUID
    let memoryId: UUID
    let worldTransform: [Float]  // 4x4 矩阵存储为数组
    let detectedObjectType: String
    let createdDate: Date
    
    init(memoryId: UUID, anchor: ARAnchor, objectType: String) {
        self.id = UUID()
        self.memoryId = memoryId
        self.detectedObjectType = objectType
        self.createdDate = Date()
        
        // 将 4x4 矩阵转换为数组存储
        let matrix = anchor.transform
        self.worldTransform = [
            matrix.columns.0.x, matrix.columns.0.y, matrix.columns.0.z, matrix.columns.0.w,
            matrix.columns.1.x, matrix.columns.1.y, matrix.columns.1.z, matrix.columns.1.w,
            matrix.columns.2.x, matrix.columns.2.y, matrix.columns.2.z, matrix.columns.2.w,
            matrix.columns.3.x, matrix.columns.3.y, matrix.columns.3.z, matrix.columns.3.w
        ]
    }
    
    // 将数组转换回 4x4 矩阵
    var transform: simd_float4x4 {
        return simd_float4x4(
            SIMD4<Float>(worldTransform[0], worldTransform[1], worldTransform[2], worldTransform[3]),
            SIMD4<Float>(worldTransform[4], worldTransform[5], worldTransform[6], worldTransform[7]),
            SIMD4<Float>(worldTransform[8], worldTransform[9], worldTransform[10], worldTransform[11]),
            SIMD4<Float>(worldTransform[12], worldTransform[13], worldTransform[14], worldTransform[15])
        )
    }
}

/// AR 记忆锚点管理器
class ARMemoryAnchorManager: ObservableObject {
    static let shared = ARMemoryAnchorManager()
    
    @Published var anchors: [ARMemoryAnchorData] = []
    
    private let anchorsKey = "ARMemoryAnchors"
    
    init() {
        loadAnchors()
    }
    
    func addAnchor(memoryId: UUID, anchor: ARAnchor, objectType: String) {
        let anchorData = ARMemoryAnchorData(memoryId: memoryId, anchor: anchor, objectType: objectType)
        anchors.append(anchorData)
        saveAnchors()
    }
    
    func removeAnchor(id: UUID) {
        anchors.removeAll { $0.id == id }
        saveAnchors()
    }
    
    func findNearbyAnchors(to position: SIMD3<Float>, maxDistance: Float = 0.5) -> [ARMemoryAnchorData] {
        return anchors.filter { anchor in
            let anchorPosition = SIMD3<Float>(
                anchor.transform.columns.3.x,
                anchor.transform.columns.3.y,
                anchor.transform.columns.3.z
            )
            let distance = simd_distance(position, anchorPosition)
            return distance < maxDistance
        }
    }
    
    private func saveAnchors() {
        if let encoded = try? JSONEncoder().encode(anchors) {
            UserDefaults.standard.set(encoded, forKey: anchorsKey)
        }
    }
    
    private func loadAnchors() {
        if let data = UserDefaults.standard.data(forKey: anchorsKey),
           let decoded = try? JSONDecoder().decode([ARMemoryAnchorData].self, from: data) {
            anchors = decoded
        }
    }
}

