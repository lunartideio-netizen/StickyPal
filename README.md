# StickyPal 📌

> 极简、优雅的 macOS 磨砂玻璃原生浮窗便签。全局快捷键 **⌥ + Space**（Option + 空格）一键随叫随到。

---

## ✨ 核心特性

- 🪟 **原生浮窗**：浮动在所有窗口之上，跨虚拟桌面（Spaces）常驻，随时记录灵感。
- ⚡️ **一键唤出 / 隐藏**：全局系统快捷键 **⌥ + Space**（Option + 空格），免权限设置、零延迟。
- 🧊 **磨砂玻璃质感**：原生 macOS VisualEffect 材质与红黄绿交通灯按钮，完美适配浅色 / 深色模式。
- 🖱️ **自由拖拽 & 缩放**：每张便签独立定位，位置和大小变动自动本地持久化。
- 🏷️ **右键菜单**：右键任意位置即可新建便签、标记颜色分类（黄/蓝/绿/粉/紫/灰）或删除便签。
- 📌 **轻量无感知**：常驻顶部菜单栏，无 Dock 栏图标打扰，支持开机自启。
- 🔒 **本地优先**：纯本地 JSON 存储，数据完全在你的电脑上，离线可用。

---

## ⌨️ 快捷键速查

| 快捷键 | 功能说明 |
|---|---|
| **⌥ + Space** | 全局切换显示 / 隐藏所有便签 |
| **右键便签** | 弹出便签操作菜单（新建、颜色标签、删除等） |
| **红 / 黄 / 绿按钮** | 红色关闭删除、黄色最小化、绿色缩放 |
| **菜单栏图标 📌** | 点击管理便签、切换开机自启、退出应用 |

---

## 🚀 安装使用

### 方式一：直接下载使用（推荐）

1. 前往 [Releases](https://github.com/lunartideio-netizen/StickyPal/releases) 页面下载最新版 `StickyPal-v1.0.0.zip`。
2. 解压后将 `StickyPal.app` 拖入 `/Applications`（应用程序）文件夹。
3. 双击打开即可使用。

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
- **快捷键方案**：Carbon `RegisterEventHotKey`（原生免权限系统级热键）
- **持久化**：本地 JSON 存储（`~/Library/Application Support/StickyPal/notes.json`）
- **打包工具**：原生 SwiftPM + Shell 自动化打包含 Ad-Hoc 签名 `.app`

---

## 📄 开源许可

本项目基于 [MIT License](LICENSE) 开源。
