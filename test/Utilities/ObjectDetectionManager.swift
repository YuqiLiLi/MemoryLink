//
//  ObjectDetectionManager.swift
//  MemoryLink
//
//  实时物体检测（使用 Vision Framework）
//

import Foundation
import AVFoundation
import Vision
import UIKit

// MARK: - Detected Object Model
struct DetectedObject: Identifiable {
    let id = UUID()
    let label: String          // 物体名称 (e.g., "cup", "chair")
    let confidence: Float      // 置信度 (0.0 - 1.0)
    let boundingBox: CGRect    // 边界框位置
    let emoji: String          // 对应的 emoji
    
    // 物体名称映射到 emoji
    static func emojiForLabel(_ label: String) -> String {
        let emojiMap: [String: String] = [
            "cup": "☕️",
            "mug": "☕️",
            "bottle": "🍾",
            "glass": "🥤",
            "book": "📚",
            "notebook": "📓",
            "chair": "🪑",
            "couch": "🛋",
            "table": "🪑",
            "laptop": "💻",
            "phone": "📱",
            "camera": "📷",
            "clock": "⏰",
            "watch": "⌚️",
            "vase": "🏺",
            "plant": "🪴",
            "picture": "🖼",
            "frame": "🖼",
            "lamp": "💡",
            "keyboard": "⌨️",
            "mouse": "🖱",
            "bag": "👜",
            "backpack": "🎒",
            "shoe": "👟",
            "hat": "🎩",
            "glasses": "👓",
            "pen": "🖊",
            "pencil": "✏️"
        ]
        
        return emojiMap[label.lowercased()] ?? "📦"
    }
}

// MARK: - Object Detection Manager
class ObjectDetectionManager: NSObject, ObservableObject {
    
    @Published var detectedObjects: [DetectedObject] = []
    @Published var isDetecting = false
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let outputQueue = DispatchQueue(label: "com.memorylink.objectdetection")
    
    // Vision request - 使用图像分类
    private lazy var classificationRequest: VNClassifyImageRequest = {
        let request = VNClassifyImageRequest { [weak self] request, error in
            self?.processClassification(request: request, error: error)
        }
        return request
    }()
    
    // MARK: - Setup
    func setupCamera() -> AVCaptureSession? {
        // 如果已经设置过，直接返回
        if let existingSession = captureSession {
            return existingSession
        }
        
        let session = AVCaptureSession()
        session.sessionPreset = .high
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get camera device")
            return nil
        }
        
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            print("Failed to create camera input")
            return nil
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        } else {
            print("Cannot add input to session")
            return nil
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: outputQueue)
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            print("Cannot add output to session")
            return nil
        }
        
        self.captureSession = session
        self.videoOutput = output
        
        print("Camera setup completed successfully")
        
        return session
    }
    
    func startDetection() {
        guard let session = captureSession else { return }
        
        isDetecting = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            print("Camera session started")
        }
    }
    
    func stopDetection() {
        isDetecting = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.stopRunning()
            print("Camera session stopped")
        }
    }
    
    // MARK: - Process Classification
    private func processClassification(request: VNRequest, error: Error?) {
        guard let results = request.results as? [VNClassificationObservation] else {
            return
        }
        
        // 获取最高置信度的结果（降低阈值让更容易检测）
        let topResults = results.filter { $0.confidence > 0.15 }.prefix(5)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.detectedObjects = topResults.enumerated().map { index, observation in
                // 为每个检测到的物体创建边界框
                let spacing: CGFloat = 0.28
                let y = CGFloat(index) * spacing + 0.15
                
                // 清理标签名称
                let cleanLabel = self.cleanLabel(observation.identifier)
                
                return DetectedObject(
                    label: cleanLabel,
                    confidence: observation.confidence,
                    boundingBox: CGRect(x: 0.1, y: y, width: 0.8, height: 0.22),
                    emoji: DetectedObject.emojiForLabel(cleanLabel)
                )
            }
        }
    }
    
    // 清理标签名称（改进版）
    private func cleanLabel(_ label: String) -> String {
        // 移除 ImageNet 类别前缀 (n开头的数字)
        var cleaned = label.replacingOccurrences(of: #"^n\d+"#, with: "", options: .regularExpression)
        
        // 移除下划线，用空格替换
        cleaned = cleaned.replacingOccurrences(of: "_", with: " ")
        
        // 只取第一个词（通常是主要物体）
        if let firstPart = cleaned.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) {
            cleaned = firstPart
        }
        
        // 只取最后一个有意义的词
        let words = cleaned.components(separatedBy: " ").filter { !$0.isEmpty }
        if let lastWord = words.last {
            cleaned = lastWord
        }
        
        // 首字母大写
        return cleaned.prefix(1).uppercased() + cleaned.dropFirst().lowercased()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ObjectDetectionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private static var lastProcessTime: Date = Date()
    private static let processingInterval: TimeInterval = 0.5  // 每 0.5 秒处理一次
    
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        
        guard isDetecting,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // 节流：每 0.5 秒处理一次（更频繁）
        let now = Date()
        guard now.timeIntervalSince(Self.lastProcessTime) >= Self.processingInterval else {
            return
        }
        Self.lastProcessTime = now
        
        // 创建图像方向
        let orientation = CGImagePropertyOrientation.right
        
        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )
        
        do {
            try handler.perform([classificationRequest])
        } catch {
            print("Failed to perform detection: \(error)")
        }
    }
}

