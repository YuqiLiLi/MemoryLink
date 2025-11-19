//
//  ObjectScannerViewController.swift
//  test
//
//  Created by Ruchen Cai on 11/8/25.
//


//
//  ObjectScannerView.swift
//  YourProjectName
//
//  Created by Your Name on 2023-08-XX.
//

import UIKit
import ARKit
import SceneKit
import SwiftUI

// MARK: - UIViewController that performs object scanning
final class ObjectScannerViewController: UIViewController,
                                         ARSCNViewDelegate, ARSessionDelegate {

    private var currentHandle: SCNNode?
    private var initialExtent: SIMD3<Float> = .zero
    
    // MARK: – UI
    private let sceneView = ARSCNView(frame: .zero)
    private let scanButton  = UIButton(type: .system)
    private let saveButton  = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    
    // MARK: – Scanning helpers
    private var boundingBox: BoundingBox?
    private var scannedReferenceObject: ARReferenceObject?
    
    // Completion handler called when the scan is finished (or cancelled)
    private var completion: (URL?) -> Void
    
    // MARK: – Init
    init(completion: @escaping (URL?) -> Void) {
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: – Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Scene view setup
        sceneView.frame = view.bounds
        sceneView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        view.addSubview(sceneView)
        
        // UI Buttons
        configureButton(scanButton, title: "Scan", action: #selector(startScan))
        configureButton(saveButton, title: "Save", action: #selector(saveScan))
        configureButton(cancelButton, title: "Cancel", action: #selector(cancelScan))
        layoutButtons()
        
        startObjectScanningSession()
        
        // Tap gesture to place / move bounding box
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tap)
        
        // pan
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(pan)
        
        // Pinch to scale bounding box
//        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
//        sceneView.addGestureRecognizer(pinch)
    }
    
    // MARK: – AR Session
    private func startObjectScanningSession() {
        guard ARWorldTrackingConfiguration.supportsFrameSemantics([]) else {
            fatalError("ARObjectScanningConfiguration is not supported on this device.")
        }
        let configuration = ARObjectScanningConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isAutoFocusEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: – UI helpers
    private func configureButton(_ button: UIButton, title: String, action: Selector) {
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
    }
    
    private func layoutButtons() {
        NSLayoutConstraint.activate([
            scanButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            scanButton.widthAnchor.constraint(equalToConstant: 80), scanButton.heightAnchor.constraint(equalToConstant: 44),
            
            saveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 80), saveButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            cancelButton.widthAnchor.constraint(equalToConstant: 80), cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        saveButton.isHidden = true   // Only show after a successful scan
    }
    
    // MARK: – Gestures
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // After first placement we ignore any further taps.
        guard boundingBox == nil else { return }

        // Place the box for the very first (and only) time.
        let location = gesture.location(in: sceneView)
        let results  = sceneView.hitTest(location,
                                         types: [.featurePoint, .existingPlaneUsingExtent])
        guard let best = results.first else { return }

        // Default size 10 cm³
        let box = BoundingBox(size: SIMD3<Float>(0.1, 0.1, 0.1))
        box.node.simdTransform = best.worldTransform
        sceneView.scene.rootNode.addChildNode(box.node)
        boundingBox = box
    }

//    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
//        let location = gesture.location(in: sceneView)
//        let results  = sceneView.hitTest(location, types: [.featurePoint, .existingPlaneUsingExtent])
//        guard let best = results.first else { return }
//        
//        if let box = boundingBox {
//            // Move existing box
//            box.node.simdTransform = best.worldTransform
//        } else {
//            // Place new box (default size 10 cm cube)
//            let box = BoundingBox(size: SIMD3<Float>(0.1,0.1,0.1))
//            box.node.simdTransform = best.worldTransform
//            sceneView.scene.rootNode.addChildNode(box.node)
//            boundingBox = box
//        }
//    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {

        guard let box = boundingBox else { return }
        let loc2D = gesture.location(in: sceneView)

        switch gesture.state {
        case .began:
            // Start only if finger touches a red handle sphere
            let hits = sceneView.hitTest(loc2D, options: nil)
            currentHandle = hits.first { $0.node.name == "handle" }?.node

        case .changed:
            guard let handle = currentHandle else { return }

            // Project 2-D screen point into 3-D world using hit-test.
            let results = sceneView.hitTest(loc2D,
                                            types: [.featurePoint,.existingPlaneUsingExtent])
            guard let best = results.first else { return }

            let wp = SIMD3<Float>(best.worldTransform.columns.3.x,
                                  best.worldTransform.columns.3.y,
                                  best.worldTransform.columns.3.z)

            box.resize(handle: handle, to: wp)

        default:
            currentHandle = nil
        }
    }
    
//    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
//        guard let box = boundingBox else { return }
//        if gesture.state == .changed || gesture.state == .ended {
//            let scale = Float(gesture.scale)
//            gesture.scale = 1
//            box.scale(by: scale)
//        }
//    }
    
    // MARK: – Scan Actions
    @objc private func startScan() {
        guard let box = boundingBox else {
            showAlert("Place a bounding box first.")
            return
        }
        scanButton.isEnabled = false
        
        let center  = SIMD3<Float>(0,0,0)          // we already encoded transform in node
        let extent  = box.extent
        
        sceneView.session.createReferenceObject(
            transform: box.node.simdWorldTransform,
            center: center,
            extent: extent) { [weak self] refObject, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.scanButton.isEnabled = true
                }
                if let refObject = refObject {
                    self.scannedReferenceObject = refObject
                    DispatchQueue.main.async {
                        self.showAlert("Scan complete. Tap Save to store.")
                        self.saveButton.isHidden = false
                    }
                } else if let error = error {
                    self.showAlert("Failed: \(error.localizedDescription)")
                }
        }
    }
    
    @objc private func saveScan() {
        guard let object = scannedReferenceObject else {
            showAlert("Nothing to save.")
            return
        }
        
        // Ask user for a name
        let alert = UIAlertController(title: "Save Scan",
                                      message: "Enter a name for this object",
                                      preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Object name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            let name = alert.textFields?.first?.text ?? "ScannedObject"
            self.export(referenceObject: object, name: name)
        })
        present(alert, animated: true)
    }
    
    private func export(referenceObject: ARReferenceObject, name: String) {
        let fileName = "\(name).arobject"
        let url = FileManager.default.urls(for: .documentDirectory,
                                           in: .userDomainMask)[0].appendingPathComponent(fileName)
        do {
            try referenceObject.export(to: url, previewImage: sceneView.snapshot())
            showAlert("Saved to Documents/\(fileName)")
            completion(url)            // inform SwiftUI / caller
        } catch {
            showAlert("Export failed: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    @objc private func cancelScan() {
        completion(nil)
    }
    
    // MARK: – Helpers
    private func showAlert(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}


// MARK: - Simple wire-frame bounding box helper
//final class BoundingBox {
//    let node: SCNNode
//    private(set) var extent: SIMD3<Float>
//    
//    init(size: SIMD3<Float>) {
//        self.extent = size
//        // Create a thin wire-frame cube
//        let boxGeometry = SCNBox(width: CGFloat(size.x),
//                                 height: CGFloat(size.y),
//                                 length: CGFloat(size.z),
//                                 chamferRadius: 0.0)
//        boxGeometry.firstMaterial?.diffuse.contents = UIColor.clear
//        boxGeometry.firstMaterial?.lightingModel = .constant
//        let boxNode = SCNNode(geometry: boxGeometry)
//        // Add edges as child nodes
//        let edges = SCNNode(geometry: SCNBox.makeWireFrame(size: size))
//        edges.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
//        boxNode.addChildNode(edges)
//        
//        self.node = boxNode
//    }
//    
//    func scale(by factor: Float) {
//        extent *= factor
//        if let box = node.geometry as? SCNBox {
//            box.width  *= CGFloat(factor)
//            box.height *= CGFloat(factor)
//            box.length *= CGFloat(factor)
//        }
//        if let edges = node.childNodes.first,
//           let edgeGeo = edges.geometry as? SCNBox {
//            edgeGeo.width  *= CGFloat(factor)
//            edgeGeo.height *= CGFloat(factor)
//            edgeGeo.length *= CGFloat(factor)
//        }
//    }
//}

// Helper to create a wire-frame SCNBox (6 extremely thin boxes around edges)
private extension SCNBox {
    static func makeWireFrame(size: SIMD3<Float>) -> SCNBox {
        // very thin walls, basically edges
        let width  = CGFloat(size.x)
        let height = CGFloat(size.y)
        let length = CGFloat(size.z)
        let thickness: CGFloat = 0.003
        let box = SCNBox(width: width + thickness,
                         height: height + thickness,
                         length: length + thickness,
                         chamferRadius: 0)
        box.firstMaterial?.fillMode = .lines
        return box
    }
}

//////////////////////////////////////////////////////
/// Swift-UI wrapper to present the scanner view
//////////////////////////////////////////////////////

struct ObjectScannerContainer: UIViewControllerRepresentable {
    
    /// Called when the user finishes scanning (or cancels).  
    /// `url` is the file location of the saved *.arobject* or `nil` on cancel/failure.
    var completion: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> ObjectScannerViewController {
        return ObjectScannerViewController(completion: completion)
    }
    
    func updateUIViewController(_ uiViewController: ObjectScannerViewController,
                                context: Context) {
        // No updates required
    }
}

#if DEBUG
import QuickLook

struct ObjectScannerContainer_Previews: PreviewProvider {
    static var previews: some View {
        ObjectScannerContainer { _ in }
            .edgesIgnoringSafeArea(.all)
    }
}
#endif
