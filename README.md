# ReminiscAR - 记忆锚定 AR 应用

## 📱 项目简介

**ReminiscAR** 是一个基于 ARKit 的 iOS 应用，可以将家人的故事和记忆锚定到日常物品上。通过 AR 技术，让物理对象成为触发回忆的"记忆节点"。

### ✨ 核心功能

1. **AR 扫描物体** - 识别并锚定真实物品（咖啡杯、相册、椅子等）
2. **录制语音故事** - 带实时字幕的语音录制
3. **记忆节点可视化** - 在 AR 视图中看到发光的记忆标记
4. **双视图浏览** - AR View（增强现实）和 List View（列表视图）
5. **家庭互动** - 添加文字或语音回复
6. **本地存储** - 所有记忆永久保存在设备上

---

## 🏗️ 项目结构

```
MemoryLink/
├── test/
│   ├── Models/                  # 数据模型
│   │   ├── Memory.swift         # 记忆数据结构
│   │   └── MemoryManager.swift  # 数据管理器
│   │
│   ├── Views/                   # 界面视图
│   │   ├── LaunchView.swift            # 启动页
│   │   ├── MainAppView.swift           # 主应用（Tab导航）
│   │   ├── ListViewTab.swift           # 列表视图
│   │   ├── MemoryDetailView.swift      # 记忆详情
│   │   ├── ResponseInputView.swift     # 添加回复
│   │   └── ARScanAndRecordView.swift   # AR扫描+录音
│   │
│   ├── AppDelegate.swift        # 应用入口
│   └── Assets.xcassets/         # 资源文件
│
├── demo/                        # Web原型参考
│   ├── index.html
│   ├── script.js
│   └── styles.css
│
└── README.md                    # 本文件
```

---

## 🚀 运行项目

### 前置要求

- **macOS** 电脑
- **Xcode 16+** (支持 iOS 17.0+)
- **iPhone 6s 或更新机型**（必须真机，模拟器无法运行 ARKit）
- **Apple Developer 账号**（免费账号即可）

### 运行步骤

#### 1. 打开项目

```bash
cd /Users/liyuqi/Desktop/DEV/MemoryLink
open test.xcodeproj
```

#### 2. 配置签名

在 Xcode 中：
1. 选择左侧项目导航器中的 **test** 项目
2. 选择 **test** target
3. 点击 **Signing & Capabilities** 标签
4. 在 **Team** 下拉菜单中选择你的 Apple ID
   - 如果没有，点击 **Add Account...** 登录

#### 3. 连接 iPhone

1. 用 USB 线连接 iPhone 到 Mac
2. iPhone 上信任此电脑
3. 在 Xcode 顶部选择你的 iPhone 设备

#### 4. 运行应用

1. 点击 Xcode 左上角的 **▶️ 运行按钮**（或按 `Cmd + R`）
2. 首次运行会提示"未受信任的开发者"
3. 在 iPhone 上：
   - **设置** → **通用** → **VPN与设备管理**
   - 找到你的 Apple ID，点击**信任**
4. 回到 Xcode 再次运行

#### 5. 授权权限

应用启动时会请求：
- ✅ 摄像头权限（必需）
- ✅ 麦克风权限（录音必需）

---

## 🎮 使用指南

### 主界面

- **Explore Memories** - 进入主应用
- 显示统计信息：记忆节点数量、贡献者
- 显示最近的记忆预览

### 主应用界面

#### AR View 标签页
- 实时 AR 摄像头视图
- 显示发光的记忆节点
- 点击 **+** 按钮创建新记忆

#### List View 标签页
- 所有记忆的列表
- 可按时间/对象排序
- 点击任意记忆查看详情

### 创建新记忆

1. **扫描物体** - 对准要绑定的物品
2. **录制故事** - 点击录音按钮讲述故事
3. **编辑信息** - 填写标题、物品名称、选择 emoji
4. **保存** - 记忆节点创建完成

### 查看记忆

- 播放音频
- 阅读文字转录
- 查看家人回复
- 添加自己的回复

---

## 🎨 设计亮点

### 视觉风格
- **渐变色** - 青绿色（#4ecdc4）作为主题色
- **发光效果** - 记忆节点使用金黄色光晕
- **现代 iOS 风格** - 圆角、毛玻璃、阴影

### 交互设计
- **流畅动画** - 页面切换、节点浮动效果
- **直观操作** - 大按钮、清晰提示
- **反馈及时** - 录音时实时波形可视化

---

## 📊 数据模型

### Memory（记忆）
```swift
- id: UUID                    // 唯一标识
- title: String               // 标题（例如"奶奶的巴黎杯子"）
- objectName: String          // 物品名称（"咖啡杯"）
- objectEmoji: String         // 表情符号（"☕️"）
- transcript: String          // 语音转文字
- audioFileName: String?      // 音频文件
- audioDuration: TimeInterval // 音频时长
- creator: String             // 创建者
- createdDate: Date           // 创建时间
- responses: [MemoryResponse] // 回复列表
```

### MemoryResponse（回复）
```swift
- id: UUID
- authorName: String          // 回复者名字
- content: String             // 回复内容
- isVoiceNote: Bool           // 是否语音
- createdDate: Date
```

---

## 🔧 技术栈

- **SwiftUI** - 现代声明式 UI 框架
- **ARKit** - Apple 的增强现实框架
- **AVFoundation** - 音频录制和播放
- **Combine** - 响应式编程
- **UserDefaults** - 本地数据持久化

---

## 📝 待完善功能

当前版本是一个功能完整的 MVP（最小可行产品），以下功能可以进一步完善：

### 🎯 优先级高
- [ ] 实际的 AR 物体识别（替换模拟视图）
- [ ] 真实音频录制和播放
- [ ] Speech-to-Text 语音转文字集成
- [ ] 音频文件管理

### 🔄 优先级中
- [ ] 语音回复功能
- [ ] 记忆地图视图（显示空间分布）
- [ ] iCloud 同步（家庭成员共享）
- [ ] 导出/分享记忆

### ✨ 优先级低
- [ ] 自定义 emoji 图标
- [ ] 记忆标签和分类
- [ ] 搜索功能
- [ ] 深色模式优化

---

## 🐛 常见问题

### Q: 为什么无法在模拟器运行？
**A:** ARKit 必须使用真机，模拟器不支持摄像头和传感器。

### Q: 应用闪退？
**A:** 
1. 确保授予了摄像头和麦克风权限
2. 检查是否信任了开发者证书
3. iOS 版本必须 ≥ 17.0

### Q: 无法录音？
**A:** 确保在系统设置中授予了麦克风权限。

### Q: AR 视图显示空白？
**A:** 当前版本使用模拟视图，真实 AR 功能需要进一步开发。

---

## 📄 许可证

本项目仅供学习和演示使用。

---

## 👨‍💻 开发者

- **项目创建**: 2025
- **基于原型**: demo/ 文件夹中的 Web 原型

---

## 🎉 开始使用

```bash
# 1. 克隆项目
git clone <repository-url>

# 2. 打开项目
open test.xcodeproj

# 3. 连接 iPhone 并运行
# 按 Cmd + R
```

祝你使用愉快！如有问题，请查看常见问题或提交 Issue。

