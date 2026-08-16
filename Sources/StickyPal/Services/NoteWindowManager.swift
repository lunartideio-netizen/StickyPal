import AppKit
import SwiftUI

@MainActor
final class NoteWindowManager: ObservableObject {
    @Published var isVisible = true
    let store = NoteStore()

    private var panels: [UUID: NotePanel] = [:]
    private var menuHandlers: [UUID: MenuActionHandler] = [:]

    // MARK: - Show / Hide

    func toggleVisibility() {
        isVisible.toggle()
        if isVisible {
            showAllNotes()
        } else {
            hideAllNotes()
        }
    }

    func showAllNotes() {
        isVisible = true
        if store.notes.isEmpty {
            createNewNote()
            return
        }

        for note in store.notes {
            if panels[note.id] == nil {
                createPanel(for: note)
            }
            panels[note.id]?.orderFront(nil)
        }
    }

    func hideAllNotes() {
        isVisible = false
        for panel in panels.values {
            panel.orderOut(nil)
        }
    }

    // MARK: - Create / Delete

    func createNewNote() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.visibleFrame
        let offsetX = Double.random(in: -60...60)
        let offsetY = Double.random(in: -60...60)
        let x = screenFrame.midX - 120 + offsetX
        let y = screenFrame.midY - 90 + offsetY

        let note = StickyNote(
            positionX: x,
            positionY: y
        )
        store.add(note)

        createPanel(for: note)
        if let panel = panels[note.id] {
            panel.orderFront(nil)
            panel.makeKeyAndOrderFront(nil)
        }
        isVisible = true
    }

    func deleteNote(id: UUID) {
        if let panel = panels[id] {
            panel.forceClose()
            panels.removeValue(forKey: id)
        }
        menuHandlers.removeValue(forKey: id)
        store.delete(id: id)
    }

    // MARK: - Panel Management

    private func createPanel(for note: StickyNote) {
        let rect = NSRect(
            x: note.positionX,
            y: note.positionY,
            width: note.width,
            height: note.height
        )

        let panel = NotePanel(contentRect: rect)
        let noteID = note.id

        // Apply initial color tag
        panel.applyColorTag(note.colorTag)

        // Apply initial theme mode
        panel.applyTheme(note.themeMode)

        // Apply initial opacity & collapse
        panel.applyOpacity(note.opacity)
        panel.applyCollapse(note.isCollapsed, animated: false)
        panel.onCollapseToggled = { [weak self] collapsed in
            self?.store.update(id: noteID) { $0.isCollapsed = collapsed }
        }

        // Red traffic light button deletes note
        panel.onDeleteRequested = { [weak self] in
            self?.deleteNote(id: noteID)
        }

        let contentView = NoteContentView(
            noteID: noteID,
            store: store,
            onContextMenu: { [weak self] in
                self?.buildContextMenu(for: noteID)
            }
        )

        let hostView = NSHostingView(rootView: contentView)
        hostView.autoresizingMask = [.width, .height]

        if let effectView = panel.contentView {
            hostView.frame = effectView.bounds
            effectView.addSubview(hostView)
        }

        // Track position changes
        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleWindowMove(panel: panel, noteID: noteID)
            }
        }

        // Track size changes
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.store.update(id: noteID) { n in
                    n.width = panel.frame.width
                    n.height = panel.frame.height
                }
            }
        }

        panels[noteID] = panel
    }

    func setColor(_ color: String, for noteID: UUID) {
        store.update(id: noteID) { n in
            n.colorTag = color
        }
        panels[noteID]?.applyColorTag(color)
    }

    func setTheme(_ theme: String, for noteID: UUID) {
        store.update(id: noteID) { n in
            n.themeMode = theme
        }
        panels[noteID]?.applyTheme(theme)
    }

    func setOpacity(_ opacity: Double, for noteID: UUID) {
        store.update(id: noteID) { n in
            n.opacity = opacity
        }
        panels[noteID]?.applyOpacity(opacity)
    }

    func copyCardImage(for noteID: UUID) {
        guard let note = store.note(for: noteID) else { return }
        let panel = panels[noteID]
        var attrString: NSAttributedString? = nil
        if let base64 = note.rtfdDataBase64, let data = Data(base64Encoded: base64) {
            attrString = NSAttributedString(rtfd: data, documentAttributes: nil)
        }
        _ = NoteCardExporter.copyCardToClipboard(panel: panel, note: note, attrString: attrString)
    }

    func saveCardImage(for noteID: UUID) {
        guard let note = store.note(for: noteID) else { return }
        let panel = panels[noteID]
        var attrString: NSAttributedString? = nil
        if let base64 = note.rtfdDataBase64, let data = Data(base64Encoded: base64) {
            attrString = NSAttributedString(rtfd: data, documentAttributes: nil)
        }
        _ = NoteCardExporter.saveCardToDesktop(panel: panel, note: note, attrString: attrString)
    }

    private func handleWindowMove(panel: NotePanel, noteID: UUID) {
        let snapped = calculateSnappedOrigin(for: panel)
        if snapped != panel.frame.origin {
            panel.setFrameOrigin(snapped)
        }
        store.update(id: noteID) { n in
            n.positionX = panel.frame.origin.x
            n.positionY = panel.frame.origin.y
        }
    }

    private func calculateSnappedOrigin(for panel: NotePanel) -> NSPoint {
        guard let screen = panel.screen ?? NSScreen.main else { return panel.frame.origin }
        let sFrame = screen.visibleFrame
        var origin = panel.frame.origin
        let snapDist: CGFloat = 14.0

        // Snap to screen edges
        if abs(origin.x - sFrame.minX) <= snapDist { origin.x = sFrame.minX }
        if abs(origin.x + panel.frame.width - sFrame.maxX) <= snapDist { origin.x = sFrame.maxX - panel.frame.width }
        if abs(origin.y + panel.frame.height - sFrame.maxY) <= snapDist { origin.y = sFrame.maxY - panel.frame.height }
        if abs(origin.y - sFrame.minY) <= snapDist { origin.y = sFrame.minY }

        // Snap to other panels
        for other in panels.values where other !== panel {
            let oFrame = other.frame
            if abs(origin.x - (oFrame.maxX + 8)) <= snapDist { origin.x = oFrame.maxX + 8 }
            if abs(origin.x + panel.frame.width - (oFrame.minX - 8)) <= snapDist { origin.x = oFrame.minX - 8 - panel.frame.width }
            if abs(origin.y + panel.frame.height - (oFrame.origin.y + oFrame.height)) <= snapDist { origin.y = oFrame.origin.y + oFrame.height - panel.frame.height }
            if abs(origin.y - oFrame.origin.y) <= snapDist { origin.y = oFrame.origin.y }
        }
        return origin
    }

    func buildContextMenu(for noteID: UUID) -> NSMenu {
        let menu = NSMenu(title: "便签操作")

        let newItem = NSMenuItem(title: "新建便签", action: #selector(MenuActionHandler.newNote), keyEquivalent: "n")
        menu.addItem(newItem)

        menu.addItem(.separator())

        // Theme modes submenu
        let currentTheme = store.note(for: noteID)?.themeMode ?? "classic"
        let themeMenu = NSMenu(title: "主题模式")
        let themeOptions: [(String, String)] = [
            ("经典磨砂", "classic"),
            ("流光渐变", "fluid"),
            ("极光流转", "aurora"),
            ("丝绸银铬", "chrome"),
            ("暗黑霓虹", "neon"),
            ("克莱因蓝", "klein"),
        ]
        for (label, value) in themeOptions {
            let item = NSMenuItem(title: label, action: #selector(MenuActionHandler.setTheme(_:)), keyEquivalent: "")
            item.representedObject = value
            if value == currentTheme {
                item.state = .on
            }
            themeMenu.addItem(item)
        }
        let themeItem = NSMenuItem(title: "主题模式", action: nil, keyEquivalent: "")
        themeItem.submenu = themeMenu
        menu.addItem(themeItem)

        // Color tags submenu
        let currentTag = store.note(for: noteID)?.colorTag ?? "gray"
        let colorMenu = NSMenu(title: "颜色标签")
        let colorTags: [(String, String)] = [
            ("黄色", "yellow"),
            ("蓝色", "blue"),
            ("绿色", "green"),
            ("粉色", "pink"),
            ("紫色", "purple"),
            ("灰色", "gray"),
        ]
        for (label, value) in colorTags {
            let item = NSMenuItem(title: label, action: #selector(MenuActionHandler.setColor(_:)), keyEquivalent: "")
            item.image = NoteColors.makeDotImage(for: value)
            item.representedObject = value
            if value == currentTag {
                item.state = .on
            }
            colorMenu.addItem(item)
        }
        let colorItem = NSMenuItem(title: "颜色标签", action: nil, keyEquivalent: "")
        colorItem.submenu = colorMenu
        menu.addItem(colorItem)

        // Opacity submenu
        let currentOpacity = store.note(for: noteID)?.opacity ?? 1.0
        let opacityMenu = NSMenu(title: "透明度")
        let opacityOptions: [(String, Double)] = [
            ("100%", 1.0),
            ("85%", 0.85),
            ("70%", 0.70),
            ("55%", 0.55),
        ]
        for (label, value) in opacityOptions {
            let item = NSMenuItem(title: label, action: #selector(MenuActionHandler.setOpacity(_:)), keyEquivalent: "")
            item.representedObject = value
            if abs(value - currentOpacity) < 0.05 {
                item.state = .on
            }
            opacityMenu.addItem(item)
        }
        let opacityItem = NSMenuItem(title: "透明度", action: nil, keyEquivalent: "")
        opacityItem.submenu = opacityMenu
        menu.addItem(opacityItem)

        menu.addItem(.separator())

        // Export card actions
        let copyCardItem = NSMenuItem(title: "复制卡片图片", action: #selector(MenuActionHandler.copyCard), keyEquivalent: "C")
        copyCardItem.keyEquivalentModifierMask = [.command, .shift]
        let saveCardItem = NSMenuItem(title: "保存卡片到桌面", action: #selector(MenuActionHandler.saveCard), keyEquivalent: "")
        menu.addItem(copyCardItem)
        menu.addItem(saveCardItem)

        menu.addItem(.separator())

        let hideItem = NSMenuItem(title: "隐藏全部便签", action: #selector(MenuActionHandler.hideAll), keyEquivalent: "h")
        menu.addItem(hideItem)

        menu.addItem(.separator())

        // Standard text edit actions
        let cutItem = NSMenuItem(title: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        let copyItem = NSMenuItem(title: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        let pasteItem = NSMenuItem(title: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        let selectAllItem = NSMenuItem(title: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        menu.addItem(cutItem)
        menu.addItem(copyItem)
        menu.addItem(pasteItem)
        menu.addItem(selectAllItem)

        menu.addItem(.separator())

        let deleteItem = NSMenuItem(title: "删除此便签", action: #selector(MenuActionHandler.deleteNote), keyEquivalent: "")
        deleteItem.attributedTitle = NSAttributedString(
            string: "删除此便签",
            attributes: [.foregroundColor: NSColor.systemRed]
        )
        menu.addItem(deleteItem)

        // Wire target handler
        let handler = MenuActionHandler(noteID: noteID, manager: self)
        menuHandlers[noteID] = handler

        newItem.target = handler
        hideItem.target = handler
        deleteItem.target = handler
        copyCardItem.target = handler
        saveCardItem.target = handler

        for item in colorMenu.items {
            item.target = handler
        }
        for item in themeMenu.items {
            item.target = handler
        }
        for item in opacityMenu.items {
            item.target = handler
        }

        return menu
    }
}

/// Bridges NSMenu actions back to NoteWindowManager.
@MainActor
final class MenuActionHandler: NSObject {
    let noteID: UUID
    weak var manager: NoteWindowManager?

    init(noteID: UUID, manager: NoteWindowManager) {
        self.noteID = noteID
        self.manager = manager
    }

    @objc func newNote() {
        manager?.createNewNote()
    }

    @objc func deleteNote() {
        manager?.deleteNote(id: noteID)
    }

    @objc func hideAll() {
        manager?.hideAllNotes()
    }

    @objc func setColor(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        manager?.setColor(value, for: noteID)
    }

    @objc func setTheme(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? String else { return }
        manager?.setTheme(value, for: noteID)
    }

    @objc func setOpacity(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        manager?.setOpacity(value, for: noteID)
    }

    @objc func copyCard() {
        manager?.copyCardImage(for: noteID)
    }

    @objc func saveCard() {
        manager?.saveCardImage(for: noteID)
    }
}
