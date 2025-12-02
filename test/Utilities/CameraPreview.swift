//
//  CameraPreview.swift
//  MemoryLink
//
//  真实相机预览视图
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    
    class CameraPreviewView: UIView {
        private var captureSession: AVCaptureSession?
        
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        func setupCamera() {
            let captureSession = AVCaptureSession()
            captureSession.sessionPreset = .photo
            
            guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: captureDevice) else {
                return
            }
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            videoPreviewLayer.session = captureSession
            videoPreviewLayer.videoGravity = .resizeAspectFill
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
            
            self.captureSession = captureSession
        }
        
        func stopCamera() {
            captureSession?.stopRunning()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
        }
    }
    
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        
        // Request camera permission
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                DispatchQueue.main.async {
                    view.setupCamera()
                }
            }
        }
        
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
    }
    
    static func dismantleUIView(_ uiView: CameraPreviewView, coordinator: ()) {
        uiView.stopCamera()
    }
}

