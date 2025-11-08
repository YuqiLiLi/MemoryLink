//
//  PointCloudPreview.swift
//

import SwiftUI
import SceneKit
import ARKit
import simd

/// Shows the raw feature points contained in an `.arobject` file.
struct PointCloudPreview: UIViewControllerRepresentable {
    
    let objectURL: URL            // location of the .arobject on disk
    
    func makeUIViewController(context: Context) -> UIViewController {
        return PointCloudPreviewVC(objectURL: objectURL)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController,
                                context: Context) { }
}

// MARK: - UIKit view-controller

private final class PointCloudPreviewVC: UIViewController {

    private let scnView = SCNView()
    private let objectURL: URL
    
    init(objectURL: URL) {
        self.objectURL = objectURL
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:)") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scnView.frame = view.bounds
        scnView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scnView.backgroundColor = .black
        view.addSubview(scnView)
        
        do { try showPointCloud() }
        catch { presentError(error) }
    }
    
    private func showPointCloud() throws {
        let refObj = try ARReferenceObject(archiveURL: objectURL)
        
        // `rawFeaturePoints` is non-optional from iOS 15 on.
        // For compatibility with older SDKs keep an availability check.
        let cloud: ARPointCloud
        if #available(iOS 15.0, *) {
            cloud = refObj.rawFeaturePoints
        } else {
            // On older SDKs `rawFeaturePoints` was optional. Use KVC to access it
            // without confusing the compiler under newer SDKs.
            if let pts = refObj.value(forKey: "rawFeaturePoints") as? ARPointCloud {
                cloud = pts
            } else {
                throw NSError(domain: "PointCloudPreview",
                              code: -1,
                              userInfo: [NSLocalizedDescriptionKey:
                                            "No raw feature points in this reference object."])
            }
        }
        
        guard !cloud.points.isEmpty else {
            throw NSError(
                domain: "PointCloudPreview",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Reference object contains 0 feature points."]
            )
        }
        let node = makeNode(from: cloud)
        node.simdTransform = matrix_identity_float4x4
        
        let scene = SCNScene()
        scene.rootNode.addChildNode(node)
        
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.position = SCNVector3(0, 0, 0.25)
        scene.rootNode.addChildNode(camera)
        
        scnView.scene = scene
        scnView.allowsCameraControl = true
    }
    
    private func makeNode(from cloud: ARPointCloud) -> SCNNode {
        let vCount = cloud.points.count
        
        // Build Data buffers
        let vertices = cloud.points
        let vertexData = Data(bytes: vertices,
                              count: MemoryLayout<SIMD3<Float>>.size * vCount)
        
        let source = SCNGeometrySource(data: vertexData,
                                       semantic: .vertex,
                                       vectorCount: vCount,
                                       usesFloatComponents: true,
                                       componentsPerVector: 3,
                                       bytesPerComponent: MemoryLayout<Float>.size,
                                       dataOffset: 0,
                                       dataStride: MemoryLayout<SIMD3<Float>>.size)
        
        var indices = Array(UInt32(0)..<UInt32(vCount))
        let indexData = Data(bytes: &indices,
                             count: MemoryLayout<UInt32>.size * vCount)
        
        let element = SCNGeometryElement(data: indexData,
                                         primitiveType: .point,
                                         primitiveCount: vCount,
                                         bytesPerIndex: MemoryLayout<UInt32>.size)
        
        let geom = SCNGeometry(sources: [source], elements: [element])
        geom.firstMaterial?.diffuse.contents = UIColor.cyan
        geom.firstMaterial?.readsFromDepthBuffer = false
        geom.firstMaterial?.setValue(8.0, forKey: "pointSize")            // bigger points
        geom.firstMaterial?.setValue(true, forKey: "pointSizeAttenuation")
        
        return SCNNode(geometry: geom)
    }
    
    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "Error",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}

