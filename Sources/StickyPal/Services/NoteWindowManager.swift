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
                self?.store.update(id: noteID) { n in
                    n.positionX = panel.frame.origin.x
                    n.positionY = panel.frame.origin.y
                }
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

    func buildContextMenu(for noteID: UUID) -> NSMenu {
        let menu = NSMenu(title: "便签操作")

        let newItem = NSMenuItem(title: "新建便签", action: #selector(MenuActionHandler.newNote), keyEquivalent: "n")
        menu.addItem(newItem)

        menu.addItem(.separator())

        // Color tags submenu
        let currentTag = store.note(for: noteID)?.colorTag ?? "yellow"
        let colorMenu = NSMenu(title: "颜色标签")
        let colorTags: [(String, String)] = [
            ("🟡 黄色", "yellow"),
            ("🔵 蓝色", "blue"),
            ("🟢 绿色", "green"),
            ("🌸 粉色", "pink"),
            ("🟣 紫色", "purple"),
            ("⚪️ 灰色", "gray"),
        ]
        for (label, value) in colorTags {
            let item = NSMenuItem(title: label, action: #selector(MenuActionHandler.setColor(_:)), keyEquivalent: "")
            item.representedObject = value
            if value == currentTag {
                item.state = .on
            }
            colorMenu.addItem(item)
        }
        let colorItem = NSMenuItem(title: "颜色标签", action: nil, keyEquivalent: "")
        colorItem.submenu = colorMenu
        menu.addItem(colorItem)

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

        for item in colorMenu.items {
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
}
