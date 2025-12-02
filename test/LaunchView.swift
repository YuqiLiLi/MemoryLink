//
//  LaunchView.swift
//  ReminiscAR
//
//  主界面 - 记忆锚定应用
//

import SwiftUI

struct LaunchView: View {
    @StateObject private var memoryManager = MemoryManager.shared
    
    // Navigation states
    @State private var showMainApp = false
    @State private var showRecording = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 渐变背景
                LinearGradient(
                    colors: [Color(hex: "4ecdc4"), Color(hex: "45b7af")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // 顶部留白
                        Spacer()
                            .frame(height: 60)
                        
                        // App Header
                        VStack(spacing: 8) {
                            Text("MemoryLink")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Memories anchored in everyday moments")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 20)
                        
                        // Stats Cards
                        HStack(spacing: 15) {
                            StatCard(
                                number: "\(memoryManager.memories.count)",
                                label: "Memory Nodes"
                            )
                            
                            StatCard(
                                number: "1",
                                label: "Contributors"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Recent Memories Preview
                        if !memoryManager.memories.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Memories")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 10) {
                                    ForEach(memoryManager.memories.prefix(2)) { memory in
                                        MemoryPreviewRow(memory: memory)
                                    }
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 10)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Main Action Button
                        Button(action: { showMainApp = true }) {
                            HStack(spacing: 12) {
                                Text("✨")
                                    .font(.system(size: 24))
                                Text("Explore Memories")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(15)
                            .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 15, y: 8)
                        }
                        .padding(.horizontal)
                        
                        // 底部留白
                        Spacer()
                            .frame(height: 60)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showMainApp) {
                MainAppView()
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let number: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(number)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(Color(hex: "4ecdc4"))
            
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 10)
        )
    }
}

// MARK: - Memory Preview Row
struct MemoryPreviewRow: View {
    let memory: Memory
    
    var body: some View {
        HStack(spacing: 12) {
            Text(memory.objectEmoji)
                .font(.system(size: 24))
            
            Text(memory.title)
                .font(.system(size: 15))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(memory.createdDate.timeAgoDisplay())
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Date Extension
extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
