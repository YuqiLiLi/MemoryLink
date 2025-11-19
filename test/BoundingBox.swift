//
//  BoundingBox.swift
//  test
//
//  Created by Ruchen Cai on 11/8/25.
//


//  BoundingBox.swift
import SceneKit
import simd

/// Simple wire-frame cube that can be resized by dragging a corner node.
final class BoundingBox {

    // MARK: – Public
    let node = SCNNode()
    private(set) var extent: SIMD3<Float>

    /// Call from the scanner’s pan-handler while the user is dragging a
    /// corner handle.
    /// - Parameters:
    ///   - handle:   The handle node being dragged (one of the 8 spheres).
    ///   - worldPos: The *new* world-space position where the user dragged
    ///               that handle to.
    func resize(handle: SCNNode, to worldPos: SIMD3<Float>) {

        guard let idx = handleNodes.firstIndex(of: handle) else { return }

        // Opposite corner ( 0 <-> 7, 1 <-> 6, 2 <-> 5, 3 <-> 4 )
        let oppositeIdx = idx ^ 0b111
        let oppositePos = handleNodes[oppositeIdx].simdWorldPosition

        // New centre = mid-point of the dragged corner and its opposite.
        let newCenter = (worldPos + oppositePos) * 0.5
        let newExtent = abs(worldPos - oppositePos)        // edge lengths

        // Keep a minimum size to avoid degenerating the box.
        let minSide: Float = 0.02   // 2 cm
        extent = simd_max(newExtent, SIMD3<Float>(repeating: minSide))

        updateGeometry()
        node.simdWorldPosition = newCenter
    }

    // MARK: – Init
    init(size: SIMD3<Float>) {
        self.extent = size
        buildGeometry()
    }

    // MARK: – Private
    private let lineThickness: Float = 0.006        // 2× thicker than before (was 0.003)

    private var solidBox: SCNBox!
    private var wireBoxNode: SCNNode!
    private var handleNodes: [SCNNode] = []

    private func buildGeometry() {

        // 1. Invisible solid cube only used as a parent for convenience
        solidBox = SCNBox(width: CGFloat(extent.x),
                          height: CGFloat(extent.y),
                          length: CGFloat(extent.z),
                          chamferRadius: 0)
        solidBox.firstMaterial?.diffuse.contents = UIColor.clear
        node.geometry = solidBox

        // 2. Yellow wire-frame (twice as thick)
        let wf = SCNBox.makeWireFrame(size: extent, thickness: lineThickness)
        wf.firstMaterial?.diffuse.contents = UIColor.yellow
        wireBoxNode = SCNNode(geometry: wf)
        node.addChildNode(wireBoxNode)

        // 3. Eight red corner handles
        addCornerHandles()
    }

    private func updateGeometry() {

        // Update solid box
        solidBox.width  = CGFloat(extent.x)
        solidBox.height = CGFloat(extent.y)
        solidBox.length = CGFloat(extent.z)

        // Replace wire-frame geometry with new dimensions
        wireBoxNode.geometry = SCNBox.makeWireFrame(size: extent,
                                                    thickness: lineThickness)

        // Update handle positions
        let h = extent * 0.5
        let positions: [SIMD3<Float>] = [
            [-h.x,-h.y,-h.z],[ h.x,-h.y,-h.z],
            [-h.x, h.y,-h.z],[ h.x, h.y,-h.z],
            [-h.x,-h.y, h.z],[ h.x,-h.y, h.z],
            [-h.x, h.y, h.z],[ h.x, h.y, h.z]
        ]
        for (i,p) in positions.enumerated() {
            handleNodes[i].simdPosition = p
        }
    }

    private func addCornerHandles() {

        let radius: CGFloat = 0.007        // ≈7 mm spheres
        let g = SCNSphere(radius: radius)
        g.firstMaterial?.diffuse.contents = UIColor.red

        let h = extent * 0.5
        let positions: [SIMD3<Float>] = [
            [-h.x,-h.y,-h.z],[ h.x,-h.y,-h.z],
            [-h.x, h.y,-h.z],[ h.x, h.y,-h.z],
            [-h.x,-h.y, h.z],[ h.x,-h.y, h.z],
            [-h.x, h.y, h.z],[ h.x, h.y, h.z]
        ]

        for p in positions {
            let n = SCNNode(geometry: g.copy() as? SCNGeometry)
            n.name = "handle"
            n.simdPosition = p
            node.addChildNode(n)
            handleNodes.append(n)
        }
    }
    
    func scale(by factor: Float) {
        // avoid collapsing to almost zero
        let minSide: Float = 0.02          // 2 cm
        extent = simd_max(extent * factor, SIMD3<Float>(repeating: minSide))
        updateGeometry()
    }
}

// MARK: – Wire-frame helper
private extension SCNBox {

    /// Creates a *lines* SCNBox slightly bigger than `size` so the lines
    /// appear with roughly `thickness` metres width.
    static func makeWireFrame(size: SIMD3<Float>,
                              thickness: Float) -> SCNBox {

        let w  = CGFloat(size.x) + CGFloat(thickness)
        let h  = CGFloat(size.y) + CGFloat(thickness)
        let l  = CGFloat(size.z) + CGFloat(thickness)

        let box = SCNBox(width: w, height: h, length: l, chamferRadius: 0)
        box.firstMaterial?.fillMode = .lines
        return box
    }
}
