//
//  ListViewTab.swift
//  ReminiscAR
//
//  记忆列表视图
//

import SwiftUI

struct ListViewTab: View {
    @StateObject private var memoryManager = MemoryManager.shared
    @State private var selectedMemoryId: UUID?
    @State private var showMemoryDetail = false
    @State private var sortOption: SortOption = .recent
    
    enum SortOption: String, CaseIterable {
        case recent = "Most Recent"
        case oldest = "Oldest First"
        case byObject = "By Object"
    }
    
    var sortedMemories: [Memory] {
        switch sortOption {
        case .recent:
            return memoryManager.memories.sorted { $0.createdDate > $1.createdDate }
        case .oldest:
            return memoryManager.memories.sorted { $0.createdDate < $1.createdDate }
        case .byObject:
            return memoryManager.memories.sorted { $0.objectName < $1.objectName }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("All Memories")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Sort Picker
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: { sortOption = option }) {
                            HStack {
                                Text(option.rawValue)
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text("Sort")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            
            // Memories List
            if sortedMemories.isEmpty {
                EmptyMemoriesView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 15) {
                        ForEach(sortedMemories) { memory in
                            MemoryListItemView(memory: memory)
                                .onTapGesture {
                                    selectedMemoryId = memory.id
                                    showMemoryDetail = true
                                }
                        }
                    }
                    .padding()
                    .padding(.bottom, 80) // 为底部浮动按钮留空间
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showMemoryDetail) {
            if let memoryId = selectedMemoryId {
                MemoryDetailView(memoryId: memoryId)
            }
        }
    }
}

// MARK: - Memory List Item
struct MemoryListItemView: View {
    let memory: Memory
    
    var body: some View {
        HStack(spacing: 15) {
            // Object Emoji Icon
            Text(memory.objectEmoji)
                .font(.system(size: 36))
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(memory.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("by \(memory.creator) • \(memory.createdDate.timeAgoDisplay())")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text(memory.transcript)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .padding(.top, 2)
                
                // Stats
                HStack(spacing: 15) {
                    Label(formatDuration(memory.audioDuration), systemImage: "waveform")
                    Label("\(memory.responses.count) response\(memory.responses.count == 1 ? "" : "s")", systemImage: "bubble.left")
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            }
            
            Spacer(minLength: 0)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        )
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Empty State
struct EmptyMemoriesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("✨")
                .font(.system(size: 80))
            
            Text("No Memories Yet")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Tap the + button to create your first memory by scanning an object")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#if DEBUG
struct ListViewTab_Previews: PreviewProvider {
    static var previews: some View {
        ListViewTab()
    }
}
#endif

