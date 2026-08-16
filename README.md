# StickyPal 📌

> 极简、优雅的 macOS 磨砂玻璃与 Apple Metal 动态流光原生浮窗便签。全局快捷键 **⌥ + Space**（Option + 空格）一键随叫随到。

![macOS 14+](https://img.shields.io/badge/macOS-14.0%2B-blue?logo=apple)
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)
![Apple Metal](https://img.shields.io/badge/Metal-GPU_Accelerated-purple?logo=apple)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ 核心特性

- 🪟 **原生浮窗**：浮动在所有窗口之上，跨虚拟桌面（Spaces）常驻，随时记录灵感。
- ⚡️ **一键唤出 / 隐藏**：全局系统快捷键 **⌥ + Space**（Option + 空格），免权限设置、零延迟。
- 🧊 **经典磨砂 + 5 款动态着色器主题**：
  - **经典磨砂（Classic Frosted）**：默认 macOS 原生磨砂玻璃 + 黄/蓝/绿/粉/紫/灰 颜色标签调节。
  - **流光渐变（Mesh Gradient）**：Apple 壁纸风格的四光球有机网格漫射，落日玫瑰粉与琥珀金温和交融。
  - **极光流转（Luminous Aurora）**：深海幽蓝夜空衬托出翡翠绿与极光青的呼吸流动。
  - **丝绸银铬（Silk Chrome）**：丝绸般顺滑的液态钛金 / 铬光波浪，柔和自然。
  - **暗黑霓虹（Cyber Neon Glow）**：暗夜黑底色上的霓虹流光，深邃紫罗兰与洋红色柔光晕染。
  - **克莱因蓝（Luxury Klein Blue）**：纯正艺术级伊夫·克莱因深海蓝与电光钴蓝流动波纹。
- 💊 **双击折叠为「灵动迷你胶囊」（Mini Capsule）**：双击便签顶部，瞬间弹性收拢为 36pt 极窄胶囊条，再双击即刻恢复。
- 🧲 **边缘平滑磁吸（Magnetic Snapping）**：拖动靠近屏幕边缘（≤14pt）或相邻便签时自动轻微吸附对齐。
- 📸 **一键导出 / 复制精美卡片（Card Export）**：
  - 快捷键 **⌘ + Shift + C** 直接把当前便签导出为带 3D 悬浮阴影与红黄绿三色灯的 2x Retina 高清卡片，在微信/邮件/文档直接 ⌘V 粘贴，彻底告别白边。
  - 支持右键一键保存卡片到桌面。
- 🖼️ **图片与图文混排**：支持剪贴板截图直接粘贴（⌘V）、Finder 文件拖拽放入、大图按便签宽度自动等比缩放。
- 🎚️ **透明度调节**：支持 100%、85%、70%、55% 多档半透明度微调。
- 🔒 **本地优先与自启**：纯本地 RTFD / JSON 存储，数据完全在本地，支持开机自启。

---

## ⌨️ 快捷键速查

| 快捷键 | 功能说明 |
|---|---|
| **⌥ + Space** | 全局切换显示 / 隐藏所有便签 |
| **⌘ + Shift + C** | 复制当前便签为 2x Retina 精美 3D 卡片图片到剪贴板 |
| **双击便签顶部** | 在「完整便签」与「灵动迷你胶囊」之间平滑折叠切换 |
| **右键便签** | 弹出便签操作菜单（主题、颜色、透明度、导出等） |
| **红 / 黄 / 绿按钮** | 红色关闭删除、黄色最小化、绿色缩放 |
| **菜单栏图标 📌** | 点击管理便签、切换开机自启、退出应用 |

---

## 🚀 安装使用

### 方式一：直接下载使用（推荐）

1. 前往 [Releases](https://github.com/lunartideio-netizen/StickyPal/releases) 页面下载最新版 `StickyPal-v1.2.0.zip`。
2. 解压后将 `StickyPal.app` 拖入 `/Applications`（应用程序）文件夹。
3. 双击打开即可随时使用 **⌥ + Space** 唤出便签！

### 方式二：源码构建

需要 macOS 14+ 及 Swift 6+ 工具链：

```bash
git clone https://github.com/lunartideio-netizen/StickyPal.git
cd StickyPal

# 编译并打包 Release 版本
bash build_app.sh release

# 运行 App
open build/StickyPal.app
```

---

## 🛠️ 项目技术栈

- **语言 / 框架**：Swift 6, SwiftUI, AppKit (NSPanel, NSVisualEffectView, NSTextView)
- **渲染加速**：Apple Metal Shading Language (MSL, 60fps/120fps GPU 加速)
- **快捷键方案**：Carbon `RegisterEventHotKey`（原生免权限系统级热键）
- **持久化**：本地 RTFD / JSON 存储（`~/Library/Application Support/StickyPal/notes.json`）
- **打包工具**：原生 SwiftPM + Shell 自动化打包含 Ad-Hoc 签名 `.app`

---

## 📄 开源许可

本项目基于 [MIT License](LICENSE) 开源。
