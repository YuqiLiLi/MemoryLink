//
//  MemoryManager.swift
//  ReminiscAR
//
//  管理所有记忆的存储和加载
//

import Foundation
import Combine

class MemoryManager: ObservableObject {
    static let shared = MemoryManager()
    
    @Published var memories: [Memory] = []
    
    private let memoriesKey = "SavedMemories"
    
    init() {
        loadMemories()
    }
    
    // MARK: - Public Methods
    
    func addMemory(_ memory: Memory) {
        memories.insert(memory, at: 0)
        saveMemories()
    }
    
    func updateMemory(_ memory: Memory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index] = memory
            saveMemories()
        }
    }
    
    func deleteMemory(_ memory: Memory) {
        memories.removeAll { $0.id == memory.id }
        saveMemories()
    }
    
    func addResponse(to memoryId: UUID, response: MemoryResponse) {
        if let index = memories.firstIndex(where: { $0.id == memoryId }) {
            memories[index].responses.append(response)
            saveMemories()
        }
    }
    
    // MARK: - Persistence
    
    private func saveMemories() {
        if let encoded = try? JSONEncoder().encode(memories) {
            UserDefaults.standard.set(encoded, forKey: memoriesKey)
        }
    }
    
    private func loadMemories() {
        if let data = UserDefaults.standard.data(forKey: memoriesKey),
           let decoded = try? JSONDecoder().decode([Memory].self, from: data) {
            memories = decoded
        } else {
            // 首次启动时加载示例数据
            memories = Memory.mockMemories
        }
    }
}

