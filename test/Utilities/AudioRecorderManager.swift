//
//  AudioRecorderManager.swift
//  MemoryLink
//
//  真实录音功能
//

import Foundation
import AVFoundation
import Combine

class AudioRecorderManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var recordedDuration: TimeInterval = 0
    @Published var liveCaption = ""
    @Published var audioFileName: String?
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var recordingSession: AVAudioSession!
    
    // MARK: - Computed Properties
    var formattedTime: String {
        let minutes = Int(recordedDuration) / 60
        let seconds = Int(recordedDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var audioFileURL: URL? {
        guard let fileName = audioFileName else { return nil }
        return getDocumentsDirectory().appendingPathComponent(fileName)
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            
            // Request permission
            recordingSession.requestRecordPermission { [weak self] allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        print("Microphone access denied")
                    }
                }
            }
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Recording
    func startRecording() {
        // Generate unique filename
        let fileName = "recording_\(Date().timeIntervalSince1970).m4a"
        audioFileName = fileName
        
        let audioURL = getDocumentsDirectory().appendingPathComponent(fileName)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            recordedDuration = 0
            
            // Start timer
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.recordedDuration += 1
                
                // Simulate live caption (in real app, would use speech recognition)
                self.updateLiveCaption()
            }
            
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
    }
    
    private func updateLiveCaption() {
        // Simulate live transcription
        let sampleTexts = [
            "This is a wonderful memory...",
            "I remember when...",
            "It was such a special moment...",
            "Every time I see this object..."
        ]
        
        if Int(recordedDuration) % 3 == 0 {
            liveCaption = sampleTexts.randomElement() ?? ""
        }
    }
    
    // MARK: - Playback
    func playAudio(fileName: String) {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
    }
    
    // MARK: - File Management
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func deleteAudioFile(fileName: String) {
        let url = getDocumentsDirectory().appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
            audioFileName = nil
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension AudioRecorderManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Audio playback finished")
    }
}

