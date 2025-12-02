//
//  MemoryDetailView.swift
//  ReminiscAR
//
//  记忆详情页面 - 显示音频、文本和回复
//

import SwiftUI
import AVFoundation

struct MemoryDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var memoryManager = MemoryManager.shared
    @StateObject private var audioPlayer = AudioPlayerManager()
    
    let memoryId: UUID
    @State private var showResponseInput = false
    
    // Get the latest memory data from memoryManager
    private var memory: Memory? {
        memoryManager.memories.first(where: { $0.id == memoryId })
    }
    
    var body: some View {
        NavigationView {
            Group {
                if let memory = memory {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Header with gradient
                            headerView(memory: memory)
                            
                            // Photo Section (if available)
                            if let photoFileName = memory.photoFileName {
                                photoView(fileName: photoFileName)
                                    .padding()
                            }
                            
                            // Audio Player
                            audioPlayerView(memory: memory)
                                .padding()
                            
                            // Transcript Section
                            transcriptView(memory: memory)
                                .padding()
                            
                            // Responses Section
                            if !memory.responses.isEmpty {
                                responsesView(memory: memory)
                                    .padding()
                            }
                            
                            Spacer(minLength: 20)
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                            }
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        // Respond Button
                        Button(action: { showResponseInput = true }) {
                            HStack {
                                Image(systemName: "bubble.left")
                                Text("Add Your Response")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "4ecdc4"))
                            .cornerRadius(15)
                        }
                        .padding()
                        .background(Color(.systemGroupedBackground))
                    }
                    .sheet(isPresented: $showResponseInput) {
                        ResponseInputView(memoryId: memory.id)
                    }
                } else {
                    Text("Memory not found")
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Photo View
    private func photoView(fileName: String) -> some View {
        Group {
            if let image = loadImage(fileName: fileName) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Photo")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                }
            }
        }
    }
    
    private func loadImage(fileName: String) -> UIImage? {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        if let data = try? Data(contentsOf: fileURL) {
            return UIImage(data: data)
        }
        return nil
    }
    
    // MARK: - Header View
    private func headerView(memory: Memory) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "4ecdc4"), Color(hex: "45b7af")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 12) {
                Text(memory.objectEmoji)
                    .font(.system(size: 64))
                
                Text(memory.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Created \(memory.createdDate.formatted(date: .abbreviated, time: .omitted)) by \(memory.creator)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.vertical, 40)
        }
    }
    
    // MARK: - Audio Player View
    private func audioPlayerView(memory: Memory) -> some View {
        HStack(spacing: 15) {
            // Play Button
            Button(action: {
                audioPlayer.togglePlayPause(audioFileName: memory.audioFileName)
            }) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "4ecdc4"))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            
            // Progress Bar and Time
            VStack(spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray5))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "4ecdc4"))
                            .frame(width: geometry.size.width * audioPlayer.progress, height: 6)
                    }
                }
                .frame(height: 6)
                
                // Time display
                HStack {
                    Text(formatDuration(audioPlayer.currentTime))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatDuration(audioPlayer.duration > 0 ? audioPlayer.duration : memory.audioDuration))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Transcript View
    private func transcriptView(memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcript")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(memory.transcript)
                .font(.system(size: 16))
                .foregroundColor(.primary)
                .lineSpacing(6)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    // MARK: - Responses View
    private func responsesView(memory: Memory) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Family Responses")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            
            ForEach(memory.responses) { response in
                ResponseBubbleView(response: response)
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Response Bubble
struct ResponseBubbleView: View {
    let response: MemoryResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(response.authorName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(response.createdDate.timeAgoDisplay())
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text(response.content)
                .font(.system(size: 15))
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "4ecdc4"), lineWidth: 3)
                        .padding(.leading, -3)
                )
        )
    }
}

// MARK: - Audio Player Manager
class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var progress: Double = 0.0  // 0.0 to 1.0
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var currentAudioFileName: String?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func play(audioFileName: String?) {
        guard let fileName = audioFileName else {
            print("No audio file name provided")
            return
        }
        
        // 如果已经在播放同一个文件，继续播放
        if currentAudioFileName == fileName && audioPlayer != nil {
            audioPlayer?.play()
            isPlaying = true
            startTimer()
            return
        }
        
        // 加载新文件
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Audio file does not exist: \(fileURL.path)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            progress = 0
            
            audioPlayer?.play()
            isPlaying = true
            currentAudioFileName = fileName
            
            startTimer()
            
            print("Playing audio: \(fileName)")
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        isPlaying = false
        progress = 0
        currentTime = 0
        stopTimer()
    }
    
    func togglePlayPause(audioFileName: String?) {
        if isPlaying {
            pause()
        } else {
            play(audioFileName: audioFileName)
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress() {
        guard let player = audioPlayer else { return }
        
        currentTime = player.currentTime
        duration = player.duration
        
        if duration > 0 {
            progress = currentTime / duration
        }
    }
    
    // AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.progress = 0
            self.currentTime = 0
            self.stopTimer()
            
            // 重置播放器到开始位置
            self.audioPlayer?.currentTime = 0
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("Audio decode error: \(error?.localizedDescription ?? "unknown")")
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}

#if DEBUG
struct MemoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        MemoryDetailView(memoryId: Memory.mockMemories[0].id)
    }
}
#endif

