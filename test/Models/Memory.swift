//
//  Memory.swift
//  ReminiscAR
//
//  Memory data model
//

import Foundation
import ARKit

/// 记忆节点 - 代表一个绑定到物理对象的记忆
struct Memory: Identifiable, Codable {
    let id: UUID
    var title: String
    var objectName: String  // 例如: "Coffee Mug", "Photo Album"
    var objectEmoji: String // 例如: "☕️", "📷"
    var transcript: String  // 语音转文字
    var audioFileName: String?  // 音频文件名
    var audioDuration: TimeInterval  // 音频时长（秒）
    var creator: String  // 创建者名称
    var createdDate: Date
    var responses: [MemoryResponse]
    
    // 照片相关
    var photoFileName: String?   // 拍摄的照片文件名
    
    // AR 相关
    var anchorIdentifier: UUID?  // ARKit anchor ID
    var scanImageName: String?   // 扫描的参考图片
    
    init(id: UUID = UUID(),
         title: String,
         objectName: String,
         objectEmoji: String,
         transcript: String,
         audioFileName: String? = nil,
         audioDuration: TimeInterval,
         creator: String,
         createdDate: Date = Date(),
         responses: [MemoryResponse] = [],
         photoFileName: String? = nil,
         anchorIdentifier: UUID? = nil) {
        
        self.id = id
        self.title = title
        self.objectName = objectName
        self.objectEmoji = objectEmoji
        self.transcript = transcript
        self.audioFileName = audioFileName
        self.audioDuration = audioDuration
        self.creator = creator
        self.createdDate = createdDate
        self.responses = responses
        self.photoFileName = photoFileName
        self.anchorIdentifier = anchorIdentifier
    }
}

/// 记忆回复
struct MemoryResponse: Identifiable, Codable {
    let id: UUID
    var authorName: String
    var content: String
    var isVoiceNote: Bool
    var audioFileName: String?
    var createdDate: Date
    
    init(id: UUID = UUID(),
         authorName: String,
         content: String,
         isVoiceNote: Bool = false,
         audioFileName: String? = nil,
         createdDate: Date = Date()) {
        
        self.id = id
        self.authorName = authorName
        self.content = content
        self.isVoiceNote = isVoiceNote
        self.audioFileName = audioFileName
        self.createdDate = createdDate
    }
}

// MARK: - Mock Data for Preview
extension Memory {
    static let mockMemories: [Memory] = [
        Memory(
            title: "Grandma's Paris Mug",
            objectName: "Coffee Mug",
            objectEmoji: "☕️",
            transcript: "This mug was a gift from my daughter when she visited Paris. Every morning when I use it, I remember that wonderful trip we took together to the Eiffel Tower. The coffee tastes better in this mug, I swear!",
            audioDuration: 45,
            creator: "Grandma",
            responses: [
                MemoryResponse(
                    authorName: "Sarah (Daughter)",
                    content: "I remember that day too, Mom! You were so happy. Love you ❤️"
                )
            ]
        ),
        Memory(
            title: "Old Photo Album",
            objectName: "Photo Album",
            objectEmoji: "📷",
            transcript: "These photos are from our honeymoon in Hawaii. It was the summer of 1965, we had just gotten married. The beaches were beautiful, and we were so young and full of dreams...",
            audioDuration: 83,
            creator: "Grandpa",
            responses: []
        ),
        Memory(
            title: "Rocking Chair",
            objectName: "Rocking Chair",
            objectEmoji: "🪑",
            transcript: "I used to rock your mother to sleep in this chair. Now when I see it, I remember those warm evenings, singing lullabies and watching her peaceful face...",
            audioDuration: 135,
            creator: "Grandma",
            responses: []
        )
    ]
}

