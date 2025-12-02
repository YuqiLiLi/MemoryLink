//
//  MainAppView.swift
//  ReminiscAR
//
//  主应用界面 - AR视图和列表视图
//

import SwiftUI

struct MainAppView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var memoryManager = MemoryManager.shared
    
    @State private var selectedTab = 0
    @State private var showRecordingView = false
    
    var body: some View {
        ZStack {
            // 背景
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                    
                    Spacer()
                }
                .background(Color.black.opacity(0.3))
                
                // Tab Buttons
                HStack(spacing: 10) {
                    TabButton(
                        icon: "viewfinder.circle",
                        title: "AR View",
                        isSelected: selectedTab == 0
                    ) {
                        selectedTab = 0
                    }
                    
                    TabButton(
                        icon: "list.bullet",
                        title: "List View",
                        isSelected: selectedTab == 1
                    ) {
                        selectedTab = 1
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.black)
                
                // Tab Content
                if selectedTab == 0 {
                    ARViewTab()
                } else {
                    ListViewTab()
                }
            }
            
            // Floating Action Button - 创建新记忆
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showRecordingView = true }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "ff6b6b"), Color(hex: "ff5252")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 70, height: 70)
                                .shadow(color: Color(hex: "ff6b6b").opacity(0.5), radius: 20)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 25)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $showRecordingView) {
            ARScanAndRecordView()
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(hex: "4ecdc4") : Color.white.opacity(0.1))
            )
        }
    }
}

// MARK: - AR View Tab
struct ARViewTab: View {
    var body: some View {
        // 直接显示物体检测相机
        ObjectDetectionCameraView()
            .ignoresSafeArea()
    }
}

// MARK: - Memory Node Indicator (AR 中的发光节点)
struct MemoryNodeIndicator: View {
    let memory: Memory
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Glowing orb
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.yellow, Color.orange.opacity(0.3)],
                            center: .center,
                            startRadius: 5,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.7 : 1.0)
                
                Text("✨")
                    .font(.system(size: 24))
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(memory.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("by \(memory.creator)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.black.opacity(0.5))
                .blur(radius: 20)
        )
    }
}


#if DEBUG
struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
    }
}
#endif

